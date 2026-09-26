import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horai_core/horai_core.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final cases = <(HoraiAlertPresentation, HoraiAlertPosition)>{
    (HoraiAlertPresentation.toast, HoraiAlertPosition.top),
    (HoraiAlertPresentation.snackbar, HoraiAlertPosition.bottom),
    (HoraiAlertPresentation.overlay, HoraiAlertPosition.center),
    (HoraiAlertPresentation.dialog, HoraiAlertPosition.center),
  };

  for (final (presentation, position) in cases) {
    testWidgets('shows and dismisses $presentation end to end', (tester) async {
      final core = HoraiCore(
        config: const HoraiCoreConfig(
          alertConfig: HoraiAlertConfig(
            deduplication: HoraiAlertDeduplication(
              mode: HoraiAlertDeduplicationMode.disabled,
            ),
            animation: HoraiAlertAnimation(type: HoraiAlertAnimationType.none),
          ),
          loggerConfig: HoraiLoggerConfig(output: HoraiLogOutput.none),
        ),
      );
      var acknowledged = 0;

      await tester.pumpWidget(
        _IntegrationApp(
          core: core,
          presentation: presentation,
          position: position,
          onAcknowledge: () => acknowledged++,
        ),
      );
      await tester.tap(find.text('Trigger alert'));
      await tester.pump();

      expect(find.text('Integration $presentation'), findsOneWidget);
      expect(find.text('Completed through $presentation'), findsOneWidget);

      if (presentation == HoraiAlertPresentation.dialog) {
        expect(find.byType(ModalBarrier), findsAtLeastNWidgets(1));
        final alertRect = tester.getRect(
          find.text('Integration $presentation'),
        );
        expect(alertRect.center.dy, closeTo(400, 100));
      } else if (position == HoraiAlertPosition.top) {
        expect(
          tester.getRect(find.text('Integration $presentation')).top,
          lessThan(200),
        );
      } else if (position == HoraiAlertPosition.bottom) {
        expect(
          tester.getRect(find.text('Integration $presentation')).bottom,
          greaterThan(500),
        );
      }

      await tester.tap(find.text('Acknowledge'));
      await tester.pump();
      expect(acknowledged, 1);
      expect(find.text('Integration $presentation'), findsNothing);
    });
  }

  testWidgets('logs structured data independently from alert presentation', (
    tester,
  ) async {
    final sink = MemoryLogSink();
    final logger = HoraiLogger(
      config: const HoraiLoggerConfig(output: HoraiLogOutput.none),
      sinks: [sink],
    );

    await tester.pumpWidget(_IntegrationApp(core: HoraiCore()));
    logger.info(
      'Session established',
      context: 'IntegrationFlow',
      metadata: {'refresh_token': 'fake-token'},
    );

    expect(sink.entries.single.context, 'IntegrationFlow');
    expect(sink.entries.single.metadata['refresh_token'], '[REDACTED]');
    expect(find.text('Trigger alert'), findsOneWidget);
  });
}

class _IntegrationApp extends StatelessWidget {
  const _IntegrationApp({
    required this.core,
    this.presentation = HoraiAlertPresentation.auto,
    this.position = HoraiAlertPosition.bottom,
    this.onAcknowledge,
  });

  final HoraiCore core;
  final HoraiAlertPresentation presentation;
  final HoraiAlertPosition position;
  final VoidCallback? onAcknowledge;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => core.alert.show(
                context: context,
                type: HoraiAlertType.success,
                title: 'Integration $presentation',
                message: 'Completed through $presentation',
                presentation: presentation,
                position: position,
                duration: const Duration(minutes: 1),
                actionLabel: 'Acknowledge',
                onAction: onAcknowledge,
              ),
              child: const Text('Trigger alert'),
            ),
          ),
        ),
      ),
      builder: (context, child) =>
          HoraiAlertHost(core: core, child: child ?? const SizedBox.shrink()),
    );
  }
}
