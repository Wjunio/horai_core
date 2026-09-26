import 'dart:async';

import '../horai_log_entry.dart';
import '../horai_log_sink.dart';

/// Bounded in-memory sink suitable for a development log console.
class MemoryLogSink implements HoraiLogSink {
  /// Creates a store that retains at most [maxEntries] records.
  MemoryLogSink({this.maxEntries = 500}) : assert(maxEntries > 0);

  /// Maximum number of retained records.
  final int maxEntries;

  final List<HoraiLogEntry> _entries = [];
  final StreamController<List<HoraiLogEntry>> _changes =
      StreamController<List<HoraiLogEntry>>.broadcast(sync: true);

  /// An immutable snapshot of retained entries.
  List<HoraiLogEntry> get entries => List<HoraiLogEntry>.unmodifiable(_entries);

  /// Emits immutable snapshots whenever entries change.
  Stream<List<HoraiLogEntry>> get changes => _changes.stream;

  @override
  void write(HoraiLogEntry entry) {
    if (_changes.isClosed) return;
    _entries.add(entry);
    if (_entries.length > maxEntries) {
      _entries.removeRange(0, _entries.length - maxEntries);
    }
    _notify();
  }

  /// Removes all retained entries.
  void clear() {
    if (_changes.isClosed) return;
    _entries.clear();
    _notify();
  }

  /// Closes the change stream and releases its resources.
  Future<void> dispose() => _changes.close();

  void _notify() => _changes.add(entries);
}
