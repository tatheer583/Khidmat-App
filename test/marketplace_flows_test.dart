import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:khidmat/localization/app_language.dart';
import 'package:khidmat/marketplace/screens/marketplace_account_screen.dart';
import 'package:khidmat/marketplace/screens/marketplace_admin_screen.dart';
import 'package:khidmat/marketplace/screens/marketplace_auth_screen.dart';
import 'package:khidmat/marketplace/screens/marketplace_home_screen.dart';
import 'package:khidmat/marketplace/screens/marketplace_jobs_screen.dart';
import 'package:khidmat/marketplace/screens/marketplace_services_screen.dart';
import 'package:khidmat/marketplace/screens/marketplace_worker_form_screen.dart';
import 'package:khidmat/marketplace/screens/marketplace_worker_profile_screen.dart';
import 'package:khidmat/marketplace/services/marketplace_controller.dart';
import 'package:khidmat/marketplace/widgets/marketplace_ui.dart';
import 'package:khidmat/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Network replacements exist only in tests. The shipped UI always uses the
/// authenticated repository, including provider and database failures.
class _Repository implements MarketplaceRepository {
  String? uid;
  Object? otpError, transitionError;
  String? requestedPhone;
  bool admin = false;
  var accountName = 'Ali Khan', accountCity = 'Lahore', status = 'active';
  List<String> roles = ['customer', 'worker'];
  final requests = <Map<String, dynamic>>[];
  final jobs = <Map<String, dynamic>>[];
  final reviews = <Map<String, dynamic>>[];
  final auth = StreamController<void>.broadcast(sync: true);
  final updates = StreamController<void>.broadcast(sync: true);

  @override
  String? get userId => uid;
  @override
  String? get phone => uid == null ? null : '+923001234567';
  @override
  Stream<void> get authChanges => auth.stream;
  @override
  Stream<void> get changes => updates.stream;
  @override
  Future<void> requestOtp(String phone) async {
    if (otpError != null) throw otpError!;
    requestedPhone = phone;
  }

  @override
  Future<void> verifyOtp(String phone, String token) async {
    uid = 'customer';
    auth.add(null);
  }

  @override
  Future<void> signOut() async {
    uid = null;
    auth.add(null);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchProfessions() async => [
    {
      'id': 'electrician',
      'name': 'Electrician',
      'category': 'Electrical Services',
      'skills': ['Wiring repair'],
      'questions': [
        {
          'key': 'commercial',
          'label': 'Do you work on commercial wiring?',
          'type': 'boolean',
          'required': true,
        },
      ],
    },
    {
      'id': 'plumber',
      'name': 'Plumber',
      'category': 'Plumbing',
      'skills': ['Leak repair'],
      'questions': [
        {
          'key': 'emergency',
          'label': 'Can you handle emergency leaks?',
          'type': 'boolean',
          'required': true,
        },
      ],
    },
  ];
  @override
  Future<Map<String, dynamic>?> fetchProfile() async => uid == null
      ? null
      : {
          'id': uid,
          'full_name': accountName,
          'city': accountCity,
          'phone': phone,
          'roles': roles,
          'status': status,
          'neighbourhood': 'Model Town',
        };
  @override
  Future<List<Map<String, dynamic>>> fetchJobs({
    int offset = 0,
    int limit = 20,
  }) async => jobs.skip(offset).take(limit).toList();
  @override
  Future<List<Map<String, dynamic>>> fetchNotifications({
    int offset = 0,
    int limit = 30,
  }) async => [];
  @override
  Future<dynamic> call(
    String function, {
    Map<String, dynamic> params = const {},
  }) async {
    requests.add({'function': function, ...params});
    if (function == 'worker_own_profile') return null;
    if (function == 'admin_check') return admin;
    if (function == 'moderation_reports') return [];
    if (function == 'moderation_reviews') {
      return reviews
          .skip(params['p_offset'] as int? ?? 0)
          .take(params['p_limit'] as int? ?? 30)
          .map((review) => Map<String, dynamic>.from(review))
          .toList();
    }
    if (function == 'moderate_review') {
      reviews.firstWhere(
        (review) => review['id'] == params['p_review_id'],
      )['hidden'] = params['p_hidden'];
      return null;
    }
    if (function == 'search_workers') return [];
    if (function == 'save_profile') {
      final profile = params['p_profile'] as Map;
      accountName = profile['full_name'] as String;
      accountCity = profile['city'] as String;
      roles = List<String>.from(profile['roles'] as List);
      return fetchProfile();
    }
    if (function == 'transition_job' && transitionError != null) {
      throw transitionError!;
    }
    return null;
  }

  @override
  Future<String> uploadImage(
    Uint8List bytes,
    String extension,
    String mimeType,
  ) async => 'https://example.test/photo.$extension';
  @override
  void watchUser(String? userId) {}
  @override
  void dispose() {
    unawaited(auth.close());
    unawaited(updates.close());
  }
}

class _DeniedLocation extends DeviceLocationService {
  int requests = 0;
  @override
  Future<SearchLocation> currentLocation() async {
    requests++;
    throw const LocationAccessException(
      LocationAccess.denied,
      'Location declined. Choose a city.',
    );
  }
}

final _controllers = <MarketplaceController>[];

void _flow(String description, Future<void> Function(WidgetTester) body) {
  testWidgets(description, (tester) async {
    try {
      await body(tester);
    } finally {
      await tester.pumpWidget(const SizedBox());
      for (final controller in _controllers) {
        controller.dispose();
      }
      _controllers.clear();
    }
  });
}

Future<GoRouter> _start(
  WidgetTester tester,
  MarketplaceController controller,
  String route, {
  GlobalKey? screenshotKey,
}) async {
  _controllers.add(controller);
  final language = AppLanguage();
  final router = GoRouter(
    initialLocation: route,
    routes: [
      GoRoute(
        path: '/marketplace',
        builder: (_, state) => MarketplaceTheme(
          child: MarketplaceHomeScreen(
            professionId: state.uri.queryParameters['profession'],
            skillId: state.uri.queryParameters['skill'],
          ),
        ),
      ),
      GoRoute(
        path: '/marketplace/services',
        builder: (_, state) => MarketplaceTheme(
          child: MarketplaceServicesScreen(
            category: state.uri.queryParameters['category'],
          ),
        ),
      ),
      GoRoute(
        path: '/marketplace/services/:id',
        builder: (_, state) => MarketplaceTheme(
          child: MarketplaceServiceDetailScreen(
            id: state.pathParameters['id']!,
            skillId: state.uri.queryParameters['skill'],
          ),
        ),
      ),
      GoRoute(
        path: '/marketplace/auth',
        builder: (_, _) =>
            const MarketplaceTheme(child: MarketplaceAuthScreen()),
      ),
      GoRoute(
        path: '/marketplace/account',
        builder: (_, _) =>
            const MarketplaceTheme(child: MarketplaceAccountScreen()),
      ),
      GoRoute(
        path: '/marketplace/admin',
        builder: (_, _) =>
            const MarketplaceTheme(child: MarketplaceAdminScreen()),
      ),
      GoRoute(
        path: '/marketplace/worker/edit',
        builder: (_, _) =>
            const MarketplaceTheme(child: MarketplaceWorkerFormScreen()),
      ),
      GoRoute(
        path: '/marketplace/jobs',
        builder: (_, _) =>
            const MarketplaceTheme(child: MarketplaceJobsScreen()),
      ),
      GoRoute(
        path: '/marketplace/workers/:id',
        builder: (_, state) => MarketplaceTheme(
          child: MarketplaceWorkerProfileScreen(
            id: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) =>
            const Scaffold(body: Text('Private records fixture')),
      ),
    ],
  );
  addTearDown(() {
    router.dispose();
    language.dispose();
  });
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<MarketplaceController>.value(value: controller),
        ChangeNotifierProvider<AppLanguage>.value(value: language),
      ],
      child: Consumer<AppLanguage>(
        builder: (_, language, _) => RepaintBoundary(
          key: screenshotKey,
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
            locale: language.locale,
            supportedLocales: const [Locale('en'), Locale('ur')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('smoke-evidence/marketplace-redesign');
    await directory.create(recursive: true);
    await File(
      '${directory.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  _flow(
    'offline directory navigates from a profession to a real skill and retains search filters',
    (tester) async {
      final controller = MarketplaceController();
      await controller.initialize();
      final electrician = controller.professions.firstWhere(
        (p) => p.name == 'Electrician',
      );
      final skill = electrician.skills.first;
      await _start(tester, controller, '/marketplace');
      await _tap(tester, find.widgetWithText(FilledButton, 'Explore services'));
      expect(find.text('What can we help with?'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Electrician');
      await tester.pumpAndSettle();
      await _tap(tester, find.byType(MarketplaceServiceCard).first);
      expect(find.text('Choose the work you need'), findsOneWidget);
      await _tap(tester, find.byKey(ValueKey('service-skill-${skill.id}')));
      await _tap(tester, find.byKey(const ValueKey('find-service-workers')));
      expect(controller.search.professionId, electrician.id);
      expect(controller.search.skillId, skill.id);
      expect(find.text('Looking for'), findsOneWidget);
      expect(find.byType(MarketplaceWorkerCard), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  _flow(
    'service catalog search finds a skill and category query limits displayed professions',
    (tester) async {
      final controller = MarketplaceController();
      await controller.initialize();
      final plumber = controller.professions.firstWhere(
        (p) => p.name == 'Plumber',
      );
      final router = await _start(
        tester,
        controller,
        Uri(
          path: '/marketplace/services',
          queryParameters: {'category': plumber.category},
        ).toString(),
      );
      expect(find.byType(MarketplaceServiceCard), findsOneWidget);
      expect(find.text('Plumber'), findsOneWidget);
      expect(find.text('Electrician'), findsNothing);
      router.go('/marketplace/services');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'AC repair');
      await tester.pumpAndSettle();
      expect(find.byType(MarketplaceServiceCard), findsOneWidget);
      expect(find.text('AC Technician'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  _flow('narrow phone renders service photos and navigation without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = MarketplaceController();
    await controller.initialize();
    final router = await _start(tester, controller, '/marketplace');
    expect(find.byType(Image), findsWidgets);
    expect(find.byTooltip('Private organizer'), findsOneWidget);
    expect(tester.takeException(), isNull);
    router.go('/marketplace/services');
    await tester.pumpAndSettle();
    expect(find.text('What can we help with?'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _tap(tester, find.byType(MarketplaceServiceCard).first);
    expect(find.text('Choose the work you need'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  _flow(
    'Urdu service directory remains searchable and navigable on a narrow phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = MarketplaceController();
      await controller.initialize();
      await _start(tester, controller, '/marketplace/services');
      await tester.tap(find.text('اردو'));
      await tester.pumpAndSettle();
      expect(find.text('آپ کو کس کام میں مدد چاہیے؟'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(Scaffold))),
        TextDirection.rtl,
      );
      await tester.enterText(find.byType(TextField).first, 'وائرنگ کی مرمت');
      await tester.pumpAndSettle();
      expect(find.byType(MarketplaceServiceCard), findsOneWidget);
      await _tap(tester, find.byType(MarketplaceServiceCard).first);
      expect(find.text('اپنا مطلوبہ کام منتخب کریں'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  _flow(
    'missing service link explains the state and returns to the complete directory',
    (tester) async {
      final controller = MarketplaceController();
      await controller.initialize();
      await _start(tester, controller, '/marketplace/services/missing');
      expect(find.text('This service is unavailable'), findsOneWidget);
      await _tap(tester, find.widgetWithText(FilledButton, 'Explore services'));
      expect(find.byType(MarketplaceServiceCard), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  if (const bool.fromEnvironment('CAPTURE_MARKETPLACE_SCREENSHOTS')) {
    _flow('capture rendered marketplace design evidence', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = MarketplaceController();
      await controller.initialize();
      final key = GlobalKey();
      final router = await _start(
        tester,
        controller,
        '/marketplace',
        screenshotKey: key,
      );
      await _capture(tester, key, 'marketplace-home-en');
      router.go('/marketplace/services');
      await tester.pumpAndSettle();
      await _capture(tester, key, 'marketplace-services-en');
      final electrician = controller.professions.firstWhere(
        (p) => p.name == 'Electrician',
      );
      router.go('/marketplace/services/${electrician.id}');
      await tester.pumpAndSettle();
      await _capture(tester, key, 'marketplace-detail-en');
      router.go('/marketplace/auth');
      await tester.pumpAndSettle();
      await _capture(tester, key, 'marketplace-auth-en');
      router.go('/marketplace');
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(320, 740);
      await tester.tap(find.text('اردو'));
      await tester.pumpAndSettle();
      await _capture(tester, key, 'marketplace-home-ur-narrow');
      router.go('/marketplace/services');
      await tester.pumpAndSettle();
      await _capture(tester, key, 'marketplace-services-ur-narrow');
      expect(tester.takeException(), isNull);
    });
  }
  _flow(
    'admin review hiding requires a decision reason and preserves the original review after refresh',
    (tester) async {
      const comment = 'Original review containing a private address.';
      const decision =
          'Contains private customer information; hide from public listings.';
      final repository = _Repository()
        ..uid = 'moderator'
        ..admin = true;
      repository.reviews.add({
        'id': 'review-one',
        'worker_id': 'worker',
        'customer_id': 'customer',
        'rating': 3,
        'comment': comment,
        'hidden': false,
      });
      final controller = MarketplaceController(repository: repository);
      await controller.initialize();
      await _start(tester, controller, '/marketplace/admin');
      await _tap(tester, find.widgetWithText(OutlinedButton, 'Hide review'));
      expect(find.text('Hide this review?'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(comment),
        ),
        findsOneWidget,
      );
      await _tap(tester, find.widgetWithText(FilledButton, 'Save decision'));
      expect(
        find.text('Record at least 10 characters explaining this decision.'),
        findsOneWidget,
      );
      expect(
        repository.requests.where(
          (request) => request['function'] == 'moderate_review',
        ),
        isEmpty,
      );
      await tester.enterText(_field('Decision reason'), decision);
      await _tap(tester, find.widgetWithText(FilledButton, 'Save decision'));
      final saved = repository.requests.singleWhere(
        (request) => request['function'] == 'moderate_review',
      );
      expect(saved['p_review_id'], 'review-one');
      expect(saved['p_hidden'], isTrue);
      expect(saved['p_reason'], decision);
      expect(controller.moderationReviews.single['hidden'], isTrue);
      expect(controller.moderationReviews.single['comment'], comment);
      expect(controller.moderationReviews.single['rating'], 3);
      await tester.scrollUntilVisible(
        find.text('Review hidden'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView).first,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(
        find.widgetWithText(OutlinedButton, 'Restore review'),
        findsOneWidget,
      );
      expect(find.text(comment), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );
  _flow(
    'unconfigured marketplace shows no fabricated workers and protects sign-in',
    (tester) async {
      final controller = MarketplaceController();
      await controller.initialize();
      final router = await _start(tester, controller, '/marketplace');
      expect(controller.professions, isNotEmpty);
      expect(find.text('Everyday services'), findsOneWidget);
      expect(find.text('Explore services'), findsOneWidget);
      expect(find.byType(MarketplaceWorkerCard), findsNothing);
      router.go('/marketplace/auth');
      await tester.pumpAndSettle();
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Send verification code'),
      );
      expect(button.onPressed, isNull);
      expect(controller.isAuthenticated, isFalse);
      await tester.pumpWidget(const SizedBox());
    },
  );

  _flow(
    'private organizer remains reachable without marketplace configuration',
    (tester) async {
      final controller = MarketplaceController();
      await controller.initialize();
      await _start(tester, controller, '/marketplace');
      await _tap(
        tester,
        find.widgetWithText(OutlinedButton, 'Private organizer'),
      );
      expect(find.text('Private records fixture'), findsOneWidget);
    },
  );

  _flow(
    'unconfigured worker profile reports unavailable without a build-time notification',
    (tester) async {
      final controller = MarketplaceController();
      await controller.initialize();
      await _start(tester, controller, '/marketplace/workers/worker');
      expect(find.text('Profile unavailable'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(find.text('Request work'), findsNothing);
    },
  );

  _flow(
    'phone validation and provider failure cannot advance to verification',
    (tester) async {
      final repository = _Repository()
        ..otpError = const AuthException(
          'SMS disabled',
          code: 'phone_provider_disabled',
        );
      final controller = MarketplaceController(repository: repository);
      await controller.initialize();
      await _start(tester, controller, '/marketplace/auth');
      await tester.enterText(_field('Pakistani mobile number'), '12345678');
      await _tap(
        tester,
        find.widgetWithText(FilledButton, 'Send verification code'),
      );
      expect(repository.requestedPhone, isNull);
      expect(
        find.textContaining('Enter a Pakistani mobile number'),
        findsOneWidget,
      );
      await tester.enterText(_field('Pakistani mobile number'), '03001234567');
      await _tap(
        tester,
        find.widgetWithText(FilledButton, 'Send verification code'),
      );
      expect(controller.isAuthenticated, isFalse);
      expect(_field('Verification code'), findsNothing);
      expect(
        find.textContaining('Phone verification is not available'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  _flow(
    'denied location permits manual city search without additional location access',
    (tester) async {
      final repository = _Repository();
      final location = _DeniedLocation();
      final controller = MarketplaceController(
        repository: repository,
        locationService: location,
      );
      await controller.initialize();
      await _start(tester, controller, '/marketplace');
      expect(location.requests, 0);
      await _tap(tester, find.text('Choose your search location'));
      await _tap(
        tester,
        find.widgetWithText(FilledButton, 'Use my current location'),
      );
      expect(location.requests, 1);
      expect(
        find.textContaining('Device location is not shared'),
        findsOneWidget,
      );
      await _tap(tester, find.text('Choose your search location'));
      await tester.enterText(_field('City'), 'Lahore');
      await tester.enterText(_field('Neighbourhood (optional)'), 'Model Town');
      await _tap(
        tester,
        find.widgetWithText(OutlinedButton, 'Search this area'),
      );
      expect(controller.location?.city, 'Lahore');
      expect(controller.location?.hasCoordinates, isFalse);
      expect(location.requests, 1);
      expect(repository.requests.last['function'], 'search_workers');
      expect(repository.requests.last['p_city'], 'Lahore');
      await tester.pumpWidget(const SizedBox());
    },
  );

  _flow(
    'profession selection changes questions and preserves account-first onboarding',
    (tester) async {
      final repository = _Repository()..uid = 'worker';
      final controller = MarketplaceController(repository: repository);
      await controller.initialize();
      await _start(tester, controller, '/marketplace/worker/edit');
      expect(find.text('Step 1 of 4'), findsOneWidget);
      await _tap(tester, find.widgetWithText(FilledButton, 'Continue'));
      await _tap(tester, find.byType(DropdownButtonFormField<String>).first);
      await tester.tap(find.text('Electrician').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Do you work on commercial wiring? *'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView).first,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Do you work on commercial wiring? *'), findsOneWidget);
      expect(find.text('Can you handle emergency leaks? *'), findsNothing);
      tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byType(ListView).first,
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      await _tap(tester, find.byType(DropdownButtonFormField<String>).first);
      await tester.tap(find.text('Plumber').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Can you handle emergency leaks? *'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView).first,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Can you handle emergency leaks? *'), findsOneWidget);
      expect(find.text('Do you work on commercial wiring? *'), findsNothing);
      await _tap(tester, find.widgetWithText(OutlinedButton, 'Save draft'));
      final saved = repository.requests.firstWhere(
        (r) => r['function'] == 'save_worker_profile',
      );
      expect((saved['p_profile'] as Map)['profession_id'], 'plumber');
      expect((saved['p_profile'] as Map)['published'], isFalse);
      expect((saved['p_profile'] as Map)['answers'], isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );

  _flow(
    'worker receives only permitted job actions and server rejection stays visible',
    (tester) async {
      final repository = _Repository()
        ..uid = 'worker'
        ..transitionError = const PostgrestException(
          message: 'Request changed. Refresh and try again.',
          code: 'P0001',
        );
      repository.jobs.add({
        'id': 'job',
        'worker_id': 'worker',
        'customer_id': 'customer',
        'status': 'pending',
        'description': 'Repair the kitchen wiring',
        'scheduled_at': DateTime.now()
            .add(const Duration(days: 1))
            .toUtc()
            .toIso8601String(),
      });
      final controller = MarketplaceController(repository: repository);
      await controller.initialize();
      await _start(tester, controller, '/marketplace/jobs');
      expect(find.text('Accept request'), findsOneWidget);
      expect(find.text('Decline request'), findsOneWidget);
      expect(find.text('Leave a review'), findsNothing);
      expect(find.text('Confirm completed'), findsNothing);
      await _tap(tester, find.widgetWithText(OutlinedButton, 'Accept request'));
      expect(controller.jobs.single.status, 'pending');
      expect(
        find.text('Request changed. Refresh and try again.'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  _flow(
    'stale worker availability displays unknown with no fabricated distance',
    (tester) async {
      final controller = MarketplaceController();
      await controller.initialize();
      controller.location = const SearchLocation(city: 'Lahore');
      controller.workers = [
        MarketplaceWorker(
          id: 'worker',
          name: 'Test worker',
          city: 'Lahore',
          professionName: 'Electrician',
          availability: WorkerAvailability.availableNow,
          availabilityUpdatedAt: DateTime.now().subtract(
            const Duration(hours: 1),
          ),
          locationUpdatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ];
      // A standalone card avoids issuing a search that should replace these test records.
      final language = AppLanguage();
      addTearDown(() {
        controller.dispose();
        language.dispose();
      });
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MarketplaceController>.value(
              value: controller,
            ),
            ChangeNotifierProvider<AppLanguage>.value(value: language),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: MarketplaceWorkerCard(worker: controller.workers.single),
            ),
          ),
        ),
      );
      expect(find.text('Availability unknown'), findsOneWidget);
      expect(find.text('Available now'), findsNothing);
      expect(find.textContaining('km away'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  _flow('suspended accounts cannot publish a worker profile', (tester) async {
    final repository = _Repository()
      ..uid = 'worker'
      ..status = 'suspended';
    final controller = MarketplaceController(repository: repository);
    await controller.initialize();
    await _start(tester, controller, '/marketplace/worker/edit');
    expect(find.text('Account restricted'), findsOneWidget);
    expect(find.text('Publish profile'), findsNothing);
    expect(find.text('Save draft'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  _flow('verified new user completes the account before worker details', (
    tester,
  ) async {
    final repository = _Repository()
      ..accountName = ''
      ..accountCity = '';
    final controller = MarketplaceController(repository: repository);
    await controller.initialize();
    await _start(tester, controller, '/marketplace/auth');
    await tester.enterText(_field('Pakistani mobile number'), '03001234567');
    await _tap(
      tester,
      find.widgetWithText(FilledButton, 'Send verification code'),
    );
    expect(repository.requestedPhone, '+923001234567');
    await tester.enterText(_field('Verification code'), '123456');
    await _tap(
      tester,
      find.widgetWithText(FilledButton, 'Verify and continue'),
    );
    expect(find.text('My account'), findsOneWidget);
    await tester.enterText(_field('Full name'), 'Ali Khan');
    await tester.enterText(_field('City'), 'Lahore');
    await _tap(tester, find.widgetWithText(FilledButton, 'Save account'));
    expect(repository.accountName, 'Ali Khan');
    expect(find.text('Step 1 of 4'), findsOneWidget);
    expect(
      repository.requests.where((r) => r['function'] == 'save_worker_profile'),
      isEmpty,
    );
    await tester.pumpWidget(const SizedBox());
  });

  _flow('marketplace onboarding switches to Urdu with RTL on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _Repository()..uid = 'worker';
    final controller = MarketplaceController(repository: repository);
    await controller.initialize();
    await _start(tester, controller, '/marketplace/worker/edit');
    await tester.tap(find.text('اردو'));
    await tester.pumpAndSettle();
    expect(find.text('میری پیشہ ورانہ پروفائل'), findsOneWidget);
    expect(find.text('مرحلہ 1 از 4'), findsOneWidget);
    expect(find.text('پورا نام'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
