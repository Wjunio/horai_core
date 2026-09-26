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
}
