import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../horai_log_entry.dart';
import '../horai_log_level.dart';
import '../sinks/memory_log_sink.dart';

/// Bounded development console for inspecting a [MemoryLogSink].
class HoraiLogConsole extends StatefulWidget {
  /// Creates a console connected to [sink]. Give this widget bounded height.
  const HoraiLogConsole({required this.sink, super.key});

  /// Store containing already-sanitized entries.
  final MemoryLogSink sink;

  @override
  State<HoraiLogConsole> createState() => _HoraiLogConsoleState();
}

class _HoraiLogConsoleState extends State<HoraiLogConsole> {
  StreamSubscription<List<HoraiLogEntry>>? _subscription;
  List<HoraiLogEntry> _entries = [];
  final Set<String> _expanded = {};
  String _query = '';
  HoraiLogLevel? _level;

  @override
  void initState() {
    super.initState();
    _listenToSink();
  }

  @override
  void didUpdateWidget(covariant HoraiLogConsole oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.sink, widget.sink)) _listenToSink();
  }

  void _listenToSink() {
    unawaited(_subscription?.cancel());
    _entries = widget.sink.entries;
    _subscription = widget.sink.changes.listen((entries) {
      if (mounted) setState(() => _entries = entries);
    });
  }

  List<HoraiLogEntry> get _visibleEntries {
    final query = _query.trim().toLowerCase();
    return _entries
        .where((entry) {
          if (_level != null && entry.level != _level) return false;
          if (query.isEmpty) return true;
          final searchable = [
            entry.message,
            entry.context,
            entry.source,
            entry.error,
            entry.metadata,
          ].join(' ').toLowerCase();
          return searchable.contains(query);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final entries = _visibleEntries;
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      child: Column(
        children: [
          _buildHeader(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search logs',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          _buildFilters(),
          Expanded(
            child: entries.isEmpty
                ? const Center(child: Text('No matching logs'))
                : ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) =>
                        _buildEntry(context, entries[index]),
                  ),
          ),
          _buildFooter(context, entries.length),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.terminal, size: 18),
          const SizedBox(width: 8),
          Text(
            'HORAI DEVELOPER CONSOLE',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Clear logs',
            onPressed: widget.sink.clear,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          _filterChip('ALL', null),
          for (final level in HoraiLogLevel.values)
            _filterChip(level.name.toUpperCase(), level),
        ],
      ),
    );
  }

  Widget _filterChip(String label, HoraiLogLevel? level) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: FilterChip(
        label: Text(label),
        selected: _level == level,
        onSelected: (_) => setState(() => _level = level),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildEntry(BuildContext context, HoraiLogEntry entry) {
    final expanded = _expanded.contains(entry.id);
    final localTime = entry.timestamp.toLocal();
    final time =
        '${_twoDigits(localTime.hour)}:${_twoDigits(localTime.minute)}:'
        '${_twoDigits(localTime.second)}';
    return Column(
      children: [
        ListTile(
          dense: true,
          onTap: () => setState(() {
            if (expanded) {
              _expanded.remove(entry.id);
            } else {
              _expanded.add(entry.id);
            }
          }),
          leading: SizedBox(
            width: 76,
            child: Text(
              entry.level.name.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: _levelColor(entry.level),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            entry.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '$time${entry.context == null ? '' : '  ${entry.context}'}',
          ),
          trailing: IconButton(
            tooltip: 'Copy log entry',
            onPressed: () =>
                Clipboard.setData(ClipboardData(text: _formatEntry(entry))),
            icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
          ),
        ),
        if (expanded) _buildDetails(context, entry),
      ],
    );
  }

  Widget _buildDetails(BuildContext context, HoraiLogEntry entry) {
    final details = <String>[
      'id: ${entry.id}',
      'timestamp: ${entry.timestamp.toIso8601String()}',
      if (entry.source != null) 'source: ${entry.source}',
      if (entry.environment != null) 'environment: ${entry.environment}',
      if (entry.metadata.isNotEmpty) 'metadata: ${entry.metadata}',
      if (entry.error != null) 'error: ${entry.error}',
      if (entry.stackTrace != null) 'stackTrace:\n${entry.stackTrace}',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: SelectableText(details.join('\n')),
    );
  }

  Widget _buildFooter(BuildContext context, int visibleCount) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Text('$visibleCount / ${_entries.length} events'),
          const Spacer(),
          IconButton(
            tooltip: 'Copy visible logs',
            onPressed: visibleCount == 0
                ? null
                : () => Clipboard.setData(
                    ClipboardData(
                      text: _visibleEntries.map(_formatEntry).join('\n'),
                    ),
                  ),
            icon: const Icon(Icons.copy),
          ),
        ],
      ),
    );
  }

  String _formatEntry(HoraiLogEntry entry) {
    return '${entry.timestamp.toIso8601String()} '
        '${entry.level.name.toUpperCase()} ${entry.message}'
        '${entry.context == null ? '' : ' [${entry.context}]'}'
        '${entry.metadata.isEmpty ? '' : ' ${entry.metadata}'}'
        '${entry.error == null ? '' : '\n${entry.error}'}'
        '${entry.stackTrace == null ? '' : '\n${entry.stackTrace}'}';
  }

  Color _levelColor(HoraiLogLevel level) => switch (level) {
    HoraiLogLevel.debug => Colors.blueGrey,
    HoraiLogLevel.info => Colors.lightBlue,
    HoraiLogLevel.success => Colors.green,
    HoraiLogLevel.warning => Colors.orange,
    HoraiLogLevel.error => Colors.red,
    HoraiLogLevel.fatal => Colors.deepPurple,
  };

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
