import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khidmat/app.dart';
import 'package:khidmat/localization/app_language.dart';
import 'package:khidmat/services/backend_session.dart';

class ProfileSession extends BackendSession {
  ProfileSession(String role, {bool completed = true}) {
    ready = true;
    profile = {
      'id': 'member',
      'full_name': 'Ali',
      'city': 'Islamabad',
      'account_role': role,
      'onboarding_completed': completed,
      'profession': 'Plumber',
      'experience_years': 5,
      'bio': 'Repairs and installation',
    };
  }
  @override
  User get user => const User(
    id: 'member',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2026-10-06',
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'app_language': 'en'}));
  testWidgets(
    'worker gets job dashboard and can switch to persisted Urdu RTL',
    (tester) async {
      final session = ProfileSession('worker');
      await tester.pumpWidget(KhidmatApp(session: session));
      await tester.pumpAndSettle();
      expect(find.text('Worker dashboard'), findsOneWidget);
      expect(find.text('Find available providers'), findsNothing);
      expect(find.text('5 years of experience'), findsOneWidget);
      await tester.tap(find.text('اردو'));
      await tester.pumpAndSettle();
      expect(find.text('کاریگر کا ڈیش بورڈ'), findsOneWidget);
      final dashboardContext = tester.element(find.text('کاریگر کا ڈیش بورڈ'));
      expect(Directionality.of(dashboardContext), TextDirection.rtl);
      expect(
        (await SharedPreferences.getInstance()).getString('app_language'),
        'ur',
      );
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.text('Worker dashboard'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      session.dispose();
    },
  );
  testWidgets('work giver gets service discovery dashboard', (tester) async {
    final session = ProfileSession('customer');
    await tester.pumpWidget(KhidmatApp(session: session));
    await tester.pumpAndSettle();
    expect(find.text('Work giver dashboard'), findsOneWidget);
    expect(find.text('Find available providers'), findsOneWidget);
    expect(find.text('Worker dashboard'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    session.dispose();
  });
  testWidgets('unfinished account must choose a role before profile details', (
    tester,
  ) async {
    final session = ProfileSession('customer', completed: false);
    await tester.pumpWidget(KhidmatApp(session: session));
    await tester.pumpAndSettle();
    expect(find.text('How will you use Khidmat?'), findsOneWidget);
    expect(find.text('Work giver dashboard'), findsNothing);
    await tester.tap(find.text('Worker'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Profession'), findsOneWidget);
    expect(find.text('Working experience (years)'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    session.dispose();
  });
  test('Urdu templates preserve entered names and addresses', () {
    expect(translateUrdu('Welcome, Ali'), 'خوش آمدید، Ali');
    expect(
      translateUrdu('Providers in G-13 Islamabad'),
      'G-13 Islamabad میں کاریگر',
    );
  });
}
