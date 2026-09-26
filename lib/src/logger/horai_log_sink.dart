import 'horai_log_entry.dart';

/// Destination that receives already-sanitized log entries.
abstract interface class HoraiLogSink {
  /// Writes [entry] to this destination.
  void write(HoraiLogEntry entry);
}
