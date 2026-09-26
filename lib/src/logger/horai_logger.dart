import 'dart:developer' as developer;

import '../core/horai_environment.dart';
import 'horai_log_entry.dart';
import 'horai_log_level.dart';
import 'horai_log_output.dart';
import 'horai_log_sanitizer.dart';
import 'horai_log_sink.dart';
import 'horai_logger_config.dart';
import 'sinks/console_log_sink.dart';
import 'sinks/memory_log_sink.dart';

/// Handles failures thrown by a custom [HoraiLogSink].
typedef HoraiLogSinkErrorHandler = void Function(
  HoraiLogSink sink,
  Object error,
  StackTrace stackTrace,
);

/// Structured logger that sanitizes entries before sending them to sinks.
class HoraiLogger {
  /// Creates a logger with environment-derived built-in sinks and custom [sinks].
  factory HoraiLogger({
    required HoraiLoggerConfig config,
    HoraiEnvironment environment = HoraiEnvironment.development,
    Iterable<HoraiLogSink> sinks = const [],
    HoraiLogSinkErrorHandler? onSinkError,
  }) {
    final resolvedSinks = <HoraiLogSink>[];
    MemoryLogSink? screenSink;

    if (config.enabled) {
      switch (config.output) {
        case HoraiLogOutput.console:
          resolvedSinks.add(const ConsoleLogSink());
        case HoraiLogOutput.screen:
          screenSink = MemoryLogSink(maxEntries: config.maxScreenEntries);
          resolvedSinks.add(screenSink);
        case HoraiLogOutput.both:
          resolvedSinks.add(const ConsoleLogSink());
          screenSink = MemoryLogSink(maxEntries: config.maxScreenEntries);
          resolvedSinks.add(screenSink);
        case HoraiLogOutput.none:
          break;
      }
      resolvedSinks.addAll(sinks);
    }

    return HoraiLogger._(
      config: config,
      environment: environment,
      sanitizer: config.effectiveSanitizer,
      sinks: List<HoraiLogSink>.unmodifiable(resolvedSinks),
      screenSink: screenSink,
      onSinkError: onSinkError,
    );
  }

  HoraiLogger._({
    required this.config,
    required this._environment,
    required this._sanitizer,
    required this._sinks,
    required this.screenSink,
    required this._onSinkError,
  });

  /// Configuration used by this logger.
  final HoraiLoggerConfig config;

  final HoraiEnvironment _environment;

  /// Built-in memory sink when screen output is enabled.
  final MemoryLogSink? screenSink;

  final HoraiLogSanitizer _sanitizer;
  final List<HoraiLogSink> _sinks;
  final HoraiLogSinkErrorHandler? _onSinkError;
  int _nextId = 0;

  /// Writes a diagnostic message.
  void debug(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? context,
    Map<String, Object?> metadata = const {},
    String? source,
  }) => _write(
    HoraiLogLevel.debug,
    message,
    error,
    stackTrace,
    context,
    metadata,
    source,
  );

  /// Writes an informational message.
  void info(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? context,
    Map<String, Object?> metadata = const {},
    String? source,
  }) => _write(
    HoraiLogLevel.info,
    message,
    error,
    stackTrace,
    context,
    metadata,
    source,
  );

  /// Writes a successful-operation message.
  void success(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? context,
    Map<String, Object?> metadata = const {},
    String? source,
  }) => _write(
    HoraiLogLevel.success,
    message,
    error,
    stackTrace,
    context,
    metadata,
    source,
  );

  /// Writes a warning message.
  void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? context,
    Map<String, Object?> metadata = const {},
    String? source,
  }) => _write(
    HoraiLogLevel.warning,
    message,
    error,
    stackTrace,
    context,
    metadata,
    source,
  );

  /// Writes an error message.
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? context,
    Map<String, Object?> metadata = const {},
    String? source,
  }) => _write(
    HoraiLogLevel.error,
    message,
    error,
    stackTrace,
    context,
    metadata,
    source,
  );

  /// Writes a fatal message.
  void fatal(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? context,
    Map<String, Object?> metadata = const {},
    String? source,
  }) => _write(
    HoraiLogLevel.fatal,
    message,
    error,
    stackTrace,
    context,
    metadata,
    source,
  );

  void _write(
    HoraiLogLevel level,
    String message,
    Object? error,
    StackTrace? stackTrace,
    String? context,
    Map<String, Object?> metadata,
    String? source,
  ) {
    if (!config.enabled ||
        level.index < config.minimumLevel.index ||
        _sinks.isEmpty) {
      return;
    }

    final sanitizedMetadata = _sanitizer.sanitizeValue(metadata);
    final safeMetadata = sanitizedMetadata is Map<String, Object?>
        ? sanitizedMetadata
        : const <String, Object?>{};
    final entry = HoraiLogEntry(
      id: '${DateTime.now().microsecondsSinceEpoch}-${_nextId++}',
      timestamp: DateTime.now().toUtc(),
      level: level,
      message: _sanitizer.sanitizeText(message),
      error: error == null ? null : _safeString(error),
      stackTrace: stackTrace == null
          ? null
          : _sanitizer.sanitizeText('$stackTrace'),
      context: context == null ? null : _sanitizer.sanitizeText(context),
      metadata: safeMetadata,
      source: source == null ? null : _sanitizer.sanitizeText(source),
      environment: _environment.name,
    );

    for (final sink in _sinks) {
      try {
        sink.write(entry);
      } on Object catch (sinkError, sinkStackTrace) {
        _handleSinkError(sink, sinkError, sinkStackTrace);
      }
    }
  }

  String _safeString(Object value) {
    try {
      return _sanitizer.sanitizeText(value.toString());
    } on Object {
      if (_environment == HoraiEnvironment.development) {
        developer.log(
          'HORAI logger could not stringify an error value',
          name: 'horai_core',
        );
      }
      return '[ERROR DESCRIPTION UNAVAILABLE]';
    }
  }

  void _handleSinkError(
    HoraiLogSink sink,
    Object error,
    StackTrace stackTrace,
  ) {
    if (_onSinkError != null) {
      try {
        _onSinkError(sink, error, stackTrace);
        return;
      } on Object catch (handlerError, handlerStackTrace) {
        if (_environment == HoraiEnvironment.development) {
          developer.log(
            'HORAI sink error handler failed: ${_safeString(handlerError)}\n'
            '${_sanitizer.sanitizeText('$handlerStackTrace')}',
            name: 'horai_core',
          );
        }
      }
    }
    if (_environment == HoraiEnvironment.development) {
      developer.log(
        'HORAI log sink failed: ${_safeString(error)}\n'
        '${_sanitizer.sanitizeText('$stackTrace')}',
        name: 'horai_core',
      );
    }
  }
}
