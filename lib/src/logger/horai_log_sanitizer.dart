import 'dart:collection';

/// Redacts sensitive fields and common credential patterns from log data.
class HoraiLogSanitizer {
  /// Creates a sanitizer with built-in and additional sensitive field names.
  HoraiLogSanitizer({
    Set<String> sensitiveKeys = const <String>{},
    this.redactedValue = '[REDACTED]',
  }) : sensitiveKeys = Set<String>.unmodifiable({
         ..._defaultSensitiveKeys,
         ...sensitiveKeys.map(_normalizeKey),
       }),
       _sensitiveAssignment = _buildSensitiveAssignment({
         ..._defaultSensitiveKeys,
         ...sensitiveKeys.map(_normalizeKey),
       });

  static const Set<String> _defaultSensitiveKeys = {
    'password',
    'passwd',
    'pwd',
    'token',
    'accesstoken',
    'refreshtoken',
    'authorization',
    'cookie',
    'secret',
    'credential',
    'credentials',
    'cpf',
    'cnpj',
    'email',
    'phone',
    'phonenumber',
    'dateofbirth',
    'bankaccount',
    'cardnumber',
    'cvv',
    'iban',
    'authorizationheader',
    'setcookie',
  };

  static final RegExp _bearerToken = RegExp(
    r'\bBearer\s+[A-Za-z0-9._~+/=-]+',
    caseSensitive: false,
  );

  /// Normalized sensitive key names, including built-in defaults.
  final Set<String> sensitiveKeys;

  final RegExp _sensitiveAssignment;

  /// Replacement text used for redacted values.
  final String redactedValue;

  /// Redacts a sensitive value when its map key matches a protected name.
  Object? sanitizeValue(Object? value) =>
      _sanitizeValue(value, HashSet<Object>.identity());

  Object? _sanitizeValue(Object? value, HashSet<Object> active) {
    if (value is String) return sanitizeText(value);
    if (value == null || value is num || value is bool) return value;
    if (value is DateTime) return value.toUtc().toIso8601String();

    if (value is Map) {
      if (!active.add(value)) return '[CIRCULAR]';
      try {
        final sanitized = <String, Object?>{};
        for (final entry in value.entries) {
          final key = entry.key is String ? entry.key as String : '[key]';
          sanitized[key] = sensitiveKeys.contains(_normalizeKey(key))
              ? redactedValue
              : _sanitizeValue(entry.value, active);
        }
        return Map<String, Object?>.unmodifiable(sanitized);
      } finally {
        active.remove(value);
      }
    }

    if (value is Iterable) {
      if (!active.add(value)) return '[CIRCULAR]';
      try {
        return List<Object?>.unmodifiable(
          value.map((item) => _sanitizeValue(item, active)),
        );
      } finally {
        active.remove(value);
      }
    }

    return '[UNSUPPORTED]';
  }

  /// Redacts credentials embedded in free-form text.
  String sanitizeText(String value) {
    final assigned = value.replaceAllMapped(
      _sensitiveAssignment,
      (match) => '${match[1]}$redactedValue',
    );
    return assigned.replaceAll(_bearerToken, 'Bearer $redactedValue');
  }
}

RegExp _buildSensitiveAssignment(Set<String> sensitiveKeys) {
  final alternatives = sensitiveKeys.toList()
    ..sort((left, right) => right.length.compareTo(left.length));
  final keyPattern = alternatives
      .map(
        (key) =>
            key.runes.map((rune) => String.fromCharCode(rune)).join(r'[\s_-]*'),
      )
      .join('|');
  final pattern =
      r'''(\b(?:''' +
      keyPattern +
      r''')\b\s*["']?\s*[:=]\s*["']?)(?:Bearer\s+)?[^,\s"'&}]+''';
  return RegExp(pattern, caseSensitive: false);
}

String _normalizeKey(String key) =>
    key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
