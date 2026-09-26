import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horai_core/horai_core.dart';

void main() {
  testWidgets('filters by level and searches sanitized log content', (
    tester,
  ) async {
    final sink = MemoryLogSink();
    final logger = _logger(sink);
    logger.info('User loaded', context: 'UserRepository');
    logger.error('Network timeout', context: 'ApiClient');

    await tester.pumpWidget(_console(sink));
    expect(find.text('User loaded'), findsOneWidget);
    expect(find.text('Network timeout'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, 'ERROR'));
    await tester.pump();
    expect(find.text('Network timeout'), findsOneWidget);
    expect(find.text('User loaded'), findsNothing);

    await tester.tap(find.text('ALL'));
    await tester.enterText(find.byType(TextField), 'userrepository');
    await tester.pump();
    expect(find.text('User loaded'), findsOneWidget);
    expect(find.text('Network timeout'), findsNothing);
  });

  testWidgets('expands errors and copies a complete sanitized entry', (
    tester,
  ) async {
    final sink = MemoryLogSink();
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText =
                (call.arguments as Map<Object?, Object?>)['text'] as String;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    final logger = _logger(sink);
    logger.error(
      'Request failed',
      error: StateError('token=private-token'),
      stackTrace: StackTrace.current,
      metadata: {'password': 'private-password'},
    );

    await tester.pumpWidget(_console(sink));
    await tester.tap(find.text('Request failed'));
    await tester.pump();
    expect(find.textContaining('stackTrace:'), findsOneWidget);

    await tester.tap(find.byTooltip('Copy visible logs'));
    await tester.pump();
    expect(copiedText, contains('Request failed'));
    expect(copiedText, isNot(contains('private-token')));
    expect(copiedText, isNot(contains('private-password')));
  });

  testWidgets('clears the bounded memory store', (tester) async {
    final sink = MemoryLogSink(maxEntries: 2);
    final logger = _logger(sink);
    logger.info('One');
    logger.info('Two');
    logger.info('Three');

    await tester.pumpWidget(_console(sink));
    expect(find.text('Three'), findsOneWidget);
    expect(find.text('One'), findsNothing);
    await tester.tap(find.byTooltip('Clear logs'));
    await tester.pump();

    expect(sink.entries, isEmpty);
    expect(find.text('No matching logs'), findsOneWidget);
  });
}

HoraiLogger _logger(MemoryLogSink sink) => HoraiLogger(
  config: const HoraiLoggerConfig(output: HoraiLogOutput.none),
  sinks: [sink],
);

Widget _console(MemoryLogSink sink) => MaterialApp(
  home: Scaffold(
    body: SizedBox(height: 500, child: HoraiLogConsole(sink: sink)),
  ),
);
