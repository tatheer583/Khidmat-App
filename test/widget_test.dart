import 'package:flutter_test/flutter_test.dart';
import 'package:khidmat/app.dart';

void main() {
  testWidgets('KHIDMAT app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KhidmatApp());
    expect(find.byType(KhidmatApp), findsOneWidget);
  });
}
