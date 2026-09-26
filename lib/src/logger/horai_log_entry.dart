import 'horai_log_level.dart';

/// Immutable, sanitized record produced by [HoraiLogger].
class HoraiLogEntry {
  /// Creates a structured log record.
  HoraiLogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
    this.context,
    Map<String, Object?> metadata = const {},
    this.source,
    this.environment,
  }) : metadata = Map<String, Object?>.unmodifiable(metadata);

  /// Unique identifier within the producing logger.
  final String id;

  /// UTC time at which the entry was created.
  final DateTime timestamp;

  /// Entry severity.
  final HoraiLogLevel level;

  /// Sanitized human-readable message.
  final String message;

  /// Sanitized error description, if supplied.
  final String? error;

  /// Sanitized stack trace, if supplied.
  final String? stackTrace;

  /// Logical component that emitted this entry.
  final String? context;

  /// Sanitized structured metadata.
  final Map<String, Object?> metadata;

  /// Optional source identifier.
  final String? source;

  /// Optional environment label.
  final String? environment;
}
