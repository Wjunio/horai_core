import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horai_core/horai_core.dart';

void main() {
  testWidgets('renders all four presentation channels', (tester) async {
    for (final presentation in [
      HoraiAlertPresentation.toast,
      HoraiAlertPresentation.snackbar,
      HoraiAlertPresentation.overlay,
      HoraiAlertPresentation.dialog,
    ]) {
      final core = HoraiCore();
      await tester.pumpWidget(_app(core, presentation: presentation));
      await tester.tap(find.text('Show alert'));
      await tester.pump();

      expect(find.text('Visible $presentation'), findsOneWidget);

      if (presentation == HoraiAlertPresentation.dialog) {
        expect(find.byType(ModalBarrier), findsAtLeastNWidgets(1));
      }
    }
  });

  testWidgets('uses the requested type, title, icon, and local colors', (
    tester,
  ) async {
    final core = HoraiCore();
    late BuildContext alertContext;
    const localColors = HoraiAlertColors(
      background: Color(0xFF101010),
      foreground: Color(0xFFFFFFFF),
      border: Color(0xFF00FF00),
      icon: Color(0xFF00FF00),
      title: Color(0xFFFFFFFF),
      message: Color(0xFFDDDDDD),
      action: Color(0xFFFFFF00),
    );

    await tester.pumpWidget(
      _app(core, onContext: (context) => alertContext = context),
    );
    core.alert.show(
      context: alertContext,
      type: HoraiAlertType.warning,
      title: 'Check this',
      message: 'Theme override',
      icon: Icons.lock_outline,
      colors: localColors,
      animation: const HoraiAlertAnimation(type: HoraiAlertAnimationType.none),
    );
    await tester.pump();

    expect(find.text('Check this'), findsOneWidget);
    expect(find.text('Theme override'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    final decorations = tester
        .widgetList<Container>(
          find.ancestor(
            of: find.text('Theme override'),
            matching: find.byType(Container),
          ),
        )
        .map((container) => container.decoration)
        .whereType<BoxDecoration>();
    expect(
      decorations.any(
        (decoration) => decoration.color == localColors.background,
      ),
      isTrue,
    );
  });

  testWidgets('runs an action and dismisses the active alert', (tester) async {
    final core = HoraiCore();
    var actionCount = 0;
    late BuildContext alertContext;

    await tester.pumpWidget(
      _app(core, onContext: (context) => alertContext = context),
    );
    core.alert.show(
      context: alertContext,
      type: HoraiAlertType.success,
      message: 'Saved',
      actionLabel: 'Undo',
      onAction: () => actionCount++,
      animation: const HoraiAlertAnimation(type: HoraiAlertAnimationType.none),
    );
    await tester.pump();
    await tester.tap(find.text('Undo'));
    await tester.pump();

    expect(actionCount, 1);
    expect(find.text('Saved'), findsNothing);
  });

  testWidgets('serializes modal alerts and advances after dismissal', (
    tester,
  ) async {
    final core = HoraiCore(
      config: const HoraiCoreConfig(
        alertConfig: HoraiAlertConfig(
          defaultPresentation: HoraiAlertPresentation.dialog,
          deduplication: HoraiAlertDeduplication(
            mode: HoraiAlertDeduplicationMode.disabled,
          ),
          animation: HoraiAlertAnimation(type: HoraiAlertAnimationType.none),
        ),
      ),
    );
    late BuildContext alertContext;

    await tester.pumpWidget(
      _app(core, onContext: (context) => alertContext = context),
    );
    core.alert.info(context: alertContext, message: 'First queued');
    core.alert.info(context: alertContext, message: 'Second queued');
    await tester.pump();

    expect(find.text('First queued'), findsOneWidget);
    expect(find.text('Second queued'), findsNothing);
    await tester.tap(find.byTooltip('Dismiss alert'));
    await tester.pump();

    expect(find.text('First queued'), findsNothing);
    expect(find.text('Second queued'), findsOneWidget);
  });

  testWidgets('suppresses repeated alerts during the configured window', (
    tester,
  ) async {
    final core = HoraiCore();
    late BuildContext alertContext;

    await tester.pumpWidget(
      _app(core, onContext: (context) => alertContext = context),
    );
    expect(core.alert.info(context: alertContext, message: 'Once'), isTrue);
    expect(core.alert.info(context: alertContext, message: 'Once'), isFalse);
    await tester.pump();

    expect(find.text('Once'), findsOneWidget);
  });

  testWidgets('keeps bottom alerts above an open software keyboard', (
    tester,
  ) async {
    final core = HoraiCore();
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    late BuildContext alertContext;

    await tester.pumpWidget(
      _app(core, onContext: (context) => alertContext = context),
    );
    core.alert.show(
      context: alertContext,
      type: HoraiAlertType.info,
      message: 'Above keyboard',
      animation: const HoraiAlertAnimation(type: HoraiAlertAnimationType.none),
    );
    await tester.pump();

    final alertRect = tester.getRect(find.text('Above keyboard'));
    expect(alertRect.bottom, lessThan(540));
  });

  testWidgets('keeps top alerts below the status bar safe area', (
    tester,
  ) async {
    final core = HoraiCore();
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(top: 64);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewPadding);
    late BuildContext alertContext;

    await tester.pumpWidget(
      _app(core, onContext: (context) => alertContext = context),
    );
    core.alert.show(
      context: alertContext,
      type: HoraiAlertType.info,
      message: 'Below status bar',
      position: HoraiAlertPosition.top,
      animation: const HoraiAlertAnimation(type: HoraiAlertAnimationType.none),
    );
    await tester.pump();

    expect(
      tester.getRect(find.text('Below status bar')).top,
      greaterThanOrEqualTo(64),
    );
  });

  testWidgets('pauses auto-dismiss while the app is in the background', (
    tester,
  ) async {
    final core = HoraiCore();
    late BuildContext alertContext;

    await tester.pumpWidget(
      _app(core, onContext: (context) => alertContext = context),
    );
    core.alert.show(
      context: alertContext,
      type: HoraiAlertType.info,
      message: 'Lifecycle alert',
      duration: const Duration(seconds: 5),
      animation: const HoraiAlertAnimation(type: HoraiAlertAnimationType.none),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Lifecycle alert'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Lifecycle alert'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('Lifecycle alert'), findsNothing);
  });

  testWidgets('does not retain a context after its widget is disposed', (
    tester,
  ) async {
    final core = HoraiCore();
    late BuildContext alertContext;

    await tester.pumpWidget(
      _app(core, onContext: (context) => alertContext = context),
    );
    await tester.pumpWidget(const SizedBox.shrink());

    expect(
      core.alert.info(context: alertContext, message: 'Disposed context'),
      isFalse,
    );
  });

  testWidgets('does not reserve deduplication keys for rejected queue items', (
    tester,
  ) async {
    final core = HoraiCore(
      config: const HoraiCoreConfig(
        alertConfig: HoraiAlertConfig(
          defaultPresentation: HoraiAlertPresentation.dialog,
          maxQueueLength: 1,
          animation: HoraiAlertAnimation(type: HoraiAlertAnimationType.none),
        ),
      ),
    );
    late BuildContext alertContext;

    await tester.pumpWidget(
      _app(core, onContext: (context) => alertContext = context),
    );
    core.alert.info(context: alertContext, message: 'Current');
    expect(core.alert.info(context: alertContext, message: 'Pending'), isFalse);
    await tester.pump();
    await tester.tap(find.byTooltip('Dismiss alert'));
    await tester.pump();

    expect(core.alert.info(context: alertContext, message: 'Pending'), isTrue);
    await tester.pump();
    expect(find.text('Pending'), findsOneWidget);
  });

  testWidgets('uses a custom builder and accessibility label', (tester) async {
    final core = HoraiCore();
    late BuildContext alertContext;
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _app(core, onContext: (context) => alertContext = context),
    );
    core.alert.show(
      context: alertContext,
      type: HoraiAlertType.info,
      message: 'Replacement content',
      semanticLabel: 'Data refreshed',
      builder: (context, alert) => Text('Custom: ${alert.message}'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Custom: Replacement content'), findsOneWidget);
    expect(find.bySemanticsLabel('Data refreshed'), findsOneWidget);
    semantics.dispose();
  });
}

Widget _app(
  HoraiCore core, {
  HoraiAlertPresentation presentation = HoraiAlertPresentation.auto,
  ValueChanged<BuildContext>? onContext,
}) {
  return MaterialApp(
    home: Builder(
      builder: (context) {
        onContext?.call(context);
        return Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => core.alert.show(
                context: context,
                type: HoraiAlertType.info,
                message: 'Visible $presentation',
                presentation: presentation,
                duration: const Duration(minutes: 1),
              ),
              child: const Text('Show alert'),
            ),
          ),
        );
      },
    ),
    builder: (context, child) =>
        HoraiAlertHost(core: core, child: child ?? const SizedBox.shrink()),
  );
}
