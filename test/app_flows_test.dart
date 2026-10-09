import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khidmat/app.dart';
import 'package:khidmat/models/local_data.dart';
import 'package:khidmat/services/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory directory;
  late LocalStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('khidmat-widget-');
    store = LocalStore(directory: directory);
    await store.initialize();
  });
  tearDown(() async {
    store.dispose();
    await directory.delete(recursive: true);
  });

  Future<void> start(WidgetTester tester) async {
    await tester.pumpWidget(KhidmatApp(store: store));
    await tester.pumpAndSettle();
  }

  Future<void> go(WidgetTester tester, String path) async {
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester, String label, String value) async {
    final scrollable = find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first;
    tester.state<ScrollableState>(scrollable).position.jumpTo(0);
    await tester.pumpAndSettle();
    final field = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label,
    );
    await tester.scrollUntilVisible(field, 200, scrollable: scrollable);
    await tester.enterText(field, value);
  }

  Future<void> save(WidgetTester tester, String label) async {
    final button = find.widgetWithText(ElevatedButton, label);
    await tester.scrollUntilVisible(
      button,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(button);
      // Disk IO runs outside the widget test's virtual clock.
      for (var i = 0; i < 200 && store.busy; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(store.busy, isFalse);
    });
    await tester.pumpAndSettle();
  }

  testWidgets('first launch leads directly to a validated phone profile', (
    tester,
  ) async {
    await start(tester);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('OTP'), findsNothing);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await save(tester, 'Save profile');
    tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
    expect(find.text('Fill this field'), findsNWidgets(2));
    await fill(tester, 'Your name', 'Ali Khan');
    await fill(tester, 'City', 'Lahore');
    await save(tester, 'Save profile');
    expect(find.text('Work giver dashboard'), findsOneWidget);
    expect(store.profile!.name, 'Ali Khan');
  });

  testWidgets('worker dashboard shows actual profession and local counts', (
    tester,
  ) async {
    await tester.runAsync(
      () => store.saveProfile(
        const KhidmatProfile(
          name: 'Aslam',
          city: 'Lahore',
          role: AccountRole.worker,
          profession: 'Electrician',
          experienceYears: 7,
        ),
      ),
    );
    await start(tester);
    expect(find.text('Worker dashboard'), findsOneWidget);
    expect(find.text('Electrician'), findsOneWidget);
    expect(find.text('7 years of experience'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(3));
    expect(find.text('Plan a service'), findsNothing);
  });

  testWidgets('adding a real worker and appointment persists their details', (
    tester,
  ) async {
    await tester.runAsync(
      () => store.saveProfile(
        const KhidmatProfile(
          name: 'Ali Khan',
          city: 'Lahore',
          role: AccountRole.customer,
        ),
      ),
    );
    await start(tester);
    await go(tester, '/contacts/new');
    await fill(tester, 'Worker name', 'Aslam');
    await fill(tester, 'Phone number', '03001234567');
    await fill(tester, 'City', 'Lahore');
    await save(tester, 'Save worker');
    expect(store.workers.single.phone, '+923001234567');
    expect(find.text('Aslam'), findsWidgets);
    await go(tester, '/jobs/new?worker=${store.workers.single.id}');
    await fill(tester, 'Work address', 'Garden Town, Lahore');
    await fill(tester, 'Agreed amount (Rs.)', '1500');
    await save(tester, 'Save job');
    expect(store.jobs.single.personName, 'Aslam');
    expect(store.jobs.single.amount, 1500);
    expect(find.text('Job details'), findsOneWidget);
  });

  testWidgets('Urdu survives restart and renders small screens right to left', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'app_language': 'ur'});
    await start(tester);
    expect(find.text('English'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(Scaffold).first)),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Get started'), findsOneWidget);
    await tester.tap(find.text('اردو'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await start(tester);
    expect(find.text('English'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('worker search fits a small phone while the keyboard is open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.runAsync(
      () => store.saveProfile(
        const KhidmatProfile(
          name: 'Ali Khan',
          city: 'Lahore',
          role: AccountRole.customer,
        ),
      ),
    );
    await start(tester);
    await go(tester, '/contacts');
    await tester.enterText(find.byType(TextField), 'plumber');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Worker name'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'removing the active profile through backup returns safely to welcome',
    (tester) async {
      await tester.runAsync(
        () => store.saveProfile(
          const KhidmatProfile(
            name: 'Ali Khan',
            city: 'Lahore',
            role: AccountRole.customer,
          ),
        ),
      );
      await start(tester);
      await go(tester, '/account');
      await tester.runAsync(
        () => store.restoreBackup(
          LocalStore(directory: directory).exportBackup(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Get started'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
