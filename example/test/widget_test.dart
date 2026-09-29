import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horai_core_example/main.dart';

void main() {
  testWidgets('example exposes channel and position controls', (tester) async {
    await tester.pumpWidget(const HoraiExampleApp());

    expect(find.text('HORAI CORE'), findsOneWidget);
    expect(find.text('Alert channels'), findsOneWidget);
    expect(find.text('Presentation'), findsOneWidget);
    expect(find.text('Position'), findsOneWidget);
    expect(find.text('Structured logger'), findsOneWidget);
  });

  testWidgets('example exposes default and customizable confirmations', (
    tester,
  ) async {
    await tester.pumpWidget(const HoraiExampleApp());

    expect(find.text('Confirmation dialogs'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Warning').last);
    await tester.pumpAndSettle();

    expect(find.text('Atenção!'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmation cancelled'), findsOneWidget);

    await tester.tap(find.text('Custom warning'));
    await tester.pumpAndSettle();

    expect(find.text('Custom warning title'), findsOneWidget);
    expect(find.text('Custom warning message'), findsOneWidget);
    expect(find.text('Continue anyway'), findsOneWidget);
    expect(find.text('Keep editing'), findsOneWidget);
  });
}
