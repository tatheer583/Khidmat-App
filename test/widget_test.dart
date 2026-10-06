import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khidmat/app.dart';
import 'package:khidmat/services/backend_session.dart';

void main() {
  testWidgets(
    'unconfigured app opens connection screen and rejects a secret key',
    (tester) async {
      final session = BackendSession();
      await tester.pumpWidget(KhidmatApp(session: session));
      await tester.pumpAndSettle();
      expect(find.text('Connect Khidmat'), findsOneWidget);
      expect(find.text('Find available providers'), findsNothing);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'https://example.supabase.co');
      await tester.enterText(fields.at(1), 'sb_secret_example');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connect'));
      await tester.pumpAndSettle();
      expect(
        find.text('Use a publishable key, never a secret key.'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      session.dispose();
    },
  );
}
