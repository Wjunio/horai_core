import 'dart:developer' as developer;

import '../horai_log_entry.dart';
import '../horai_log_sink.dart';

/// Writes structured entries to the Dart developer log without using `print`.
class ConsoleLogSink implements HoraiLogSink {
  /// Creates a developer-console sink.
  const ConsoleLogSink();

  @override
  void write(HoraiLogEntry entry) {
    final details = <String>[
      '[${entry.level.name.toUpperCase()}] ${entry.timestamp.toIso8601String()}',
      if (entry.context != null) 'context=${entry.context}',
      if (entry.source != null) 'source=${entry.source}',
      entry.message,
      if (entry.metadata.isNotEmpty) 'metadata=${entry.metadata}',
      if (entry.error != null) 'error=${entry.error}',
      if (entry.stackTrace != null) 'stackTrace=${entry.stackTrace}',
    ].join(' | ');

    developer.log(details, name: 'horai_core.${entry.level.name}');
  }
}
