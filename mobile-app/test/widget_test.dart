import 'package:flutter_test/flutter_test.dart';
import 'package:zyeta_workforce_app/main.dart';

void main() {
  testWidgets('Zyeta app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ZyetaWorkforceApp());
    expect(find.text('ZyetaGate OS'), findsOneWidget);
  });
}

