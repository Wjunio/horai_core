import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horai_core/horai_core.dart';

void main() {
  testWidgets('shows Portuguese defaults and returns confirmation result', (
    tester,
  ) async {
    final core = HoraiCore();
    late BuildContext dialogContext;
    await tester.pumpWidget(
      _app(core, onContext: (context) => dialogContext = context),
    );

    final result = core.confirmation.show(context: dialogContext);
    await tester.pumpAndSettle();

    expect(find.text('Atenção!'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(await result, isTrue);
  });

  testWidgets(
    'allows all copy to be customized and cancellation returns false',
    (tester) async {
      final core = HoraiCore();
      late BuildContext dialogContext;
      await tester.pumpWidget(
        _app(core, onContext: (context) => dialogContext = context),
      );

      final result = core.confirmation.show(
        context: dialogContext,
        type: HoraiAlertType.error,
        title: 'Custom title',
        message: 'Custom message',
        confirmLabel: 'Try again',
        cancelLabel: 'Later',
      );
      await tester.pumpAndSettle();

      expect(find.text('Custom title'), findsOneWidget);
      expect(find.text('Custom message'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();
      expect(await result, isFalse);
    },
  );

  testWidgets('success and info defaults omit the cancel button', (
    tester,
  ) async {
    final core = HoraiCore();
    late BuildContext dialogContext;
    await tester.pumpWidget(
      _app(core, onContext: (context) => dialogContext = context),
    );

    for (final type in [HoraiAlertType.success, HoraiAlertType.info]) {
      final result = core.confirmation.show(context: dialogContext, type: type);
      await tester.pumpAndSettle();
      expect(
        find.text(type == HoraiAlertType.success ? 'Sucesso!' : 'Informação'),
        findsOneWidget,
      );
      expect(find.text('Fechar'), findsNothing);
      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();
      expect(await result, isNull);
    }
  });

  testWidgets('renders within a narrow mobile viewport', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final core = HoraiCore();
    late BuildContext dialogContext;
    await tester.pumpWidget(
      _app(core, onContext: (context) => dialogContext = context),
    );
    core.confirmation.show(
      context: dialogContext,
      type: HoraiAlertType.warning,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Continuar'), findsOneWidget);
  });
}

Widget _app(HoraiCore core, {required ValueChanged<BuildContext> onContext}) {
  return MaterialApp(
    home: Builder(
      builder: (context) {
        onContext(context);
        return const Scaffold(body: SizedBox.expand());
      },
    ),
  );
}
