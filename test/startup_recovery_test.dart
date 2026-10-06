import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:khidmat/app.dart';
import 'package:khidmat/services/backend_session.dart';
import 'package:khidmat/services/deadline_client.dart';
import 'onboarding_language_test.dart' show ProfileSession;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'app_language': 'en'}));

  testWidgets('startup paints while initialization is pending', (tester) async {
    final session = BackendSession()..initializing = true;
    await tester.pumpWidget(KhidmatApp(session: session));
    await tester.pump();
    expect(find.text('Connecting to Khidmat…'), findsOneWidget);
    expect(find.text('Connect Khidmat'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    session.dispose();
  });

  testWidgets('missing backend gives retry instead of broken onboarding', (
    tester,
  ) async {
    final session = ProfileSession('worker')
      ..serviceAvailable = false
      ..serviceError = serviceSetupMessage;
    await tester.pumpWidget(KhidmatApp(session: session));
    await tester.pumpAndSettle();
    expect(find.text(serviceSetupMessage), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Worker dashboard'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    session.dispose();
  });

  testWidgets('failed profile fetch permits retry and sign out', (
    tester,
  ) async {
    final session = ProfileSession('worker')
      ..profile = null
      ..error = 'Your profile could not be loaded.';
    await tester.pumpWidget(KhidmatApp(session: session));
    await tester.pumpAndSettle();
    expect(find.text('Your profile could not be loaded.'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('How will you use Khidmat?'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    session.dispose();
  });

  testWidgets('recovery link goes to password form before onboarding', (
    tester,
  ) async {
    final session = ProfileSession('worker', completed: false)
      ..recoveringPassword = true;
    await tester.pumpWidget(KhidmatApp(session: session));
    await tester.pumpAndSettle();
    expect(find.text('Choose a new password'), findsOneWidget);
    expect(find.text('How will you use Khidmat?'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    session.dispose();
  });

  test(
    'requests fail promptly on a stalled connection without automatic retry',
    () async {
      var attempts = 0;
      final httpClient = DeadlineClient(
        deadline: const Duration(milliseconds: 10),
        inner: MockClient((request) {
          attempts++;
          return Completer<http.Response>().future;
        }),
      );
      await expectLater(
        httpClient.get(Uri.parse('https://example.test')),
        throwsA(isA<TimeoutException>()),
      );
      expect(attempts, 1);
      httpClient.close();
    },
  );
}
