import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:khidmat/marketplace/services/marketplace_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeMarketplaceRepository implements MarketplaceRepository {
  String? uid;
  String status = 'active';
  Object? otpError;
  String? requestedPhone, watchedUser;
  int calls = 0;
  final auth = StreamController<void>.broadcast(sync: true);
  final updates = StreamController<void>.broadcast(sync: true);
  final requests = <Map<String, dynamic>>[];
  final pendingSearches = <Completer<dynamic>>[];
  bool delaySearch = false;
  bool admin = false;
  final delayedCalls = <String, Completer<dynamic>>{};
  List<Map<String, dynamic>> jobRows = [];
  Completer<List<Map<String, dynamic>>>? delayedJobs;
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
      'questions': [],
    },
  ];
  @override
  Future<Map<String, dynamic>?> fetchProfile() async => uid == null
      ? null
      : {
          'id': uid,
          'full_name': 'Ali Khan',
          'phone': phone,
          'city': 'Lahore',
          'neighbourhood': 'Model Town',
          'roles': ['customer', 'worker'],
          'status': status,
        };
  @override
  Future<List<Map<String, dynamic>>> fetchJobs({
    int offset = 0,
    int limit = 20,
  }) async => delayedJobs == null ? jobRows : delayedJobs!.future;
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
    calls++;
    requests.add({'function': function, ...params});
    if (delayedCalls.containsKey(function)) {
      return delayedCalls[function]!.future;
    }
    if (function == 'worker_own_profile') return null;
    if (function == 'admin_check') return admin;
    if (function == 'moderation_reports') {
      return List.generate(
        params['p_offset'] == 0 ? 30 : 1,
        (i) => {
          'id': 'report-${(params['p_offset'] as int) + i}',
          'details': 'Private moderation evidence',
        },
      );
    }
    if (function == 'search_workers') {
      if (delaySearch) {
        final pending = Completer<dynamic>();
        pendingSearches.add(pending);
        return pending.future;
      }
      return List.generate(
        params['p_offset'] == 0 ? 20 : 1,
        (i) => {
          'id': 'worker-${(params['p_offset'] as int) + i}',
          'name': 'Worker $i',
        },
      );
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
  void watchUser(String? userId) {
    watchedUser = userId;
  }

  @override
  void dispose() {
    unawaited(auth.close());
    unawaited(updates.close());
  }
}

class DeniedLocation extends DeviceLocationService {
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

class DeferredLocation extends DeviceLocationService {
  final pending = Completer<SearchLocation>();
  @override
  Future<SearchLocation> currentLocation() => pending.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'unconfigured service cannot simulate authentication or worker results',
    () async {
      final controller = MarketplaceController();
      addTearDown(controller.dispose);
      expect(await controller.initialize(), isTrue);
      expect(controller.configured, isFalse);
      expect(await controller.requestOtp('03001234567'), isFalse);
      expect(controller.isAuthenticated, isFalse);
      expect(controller.workers, isEmpty);
      expect(controller.error, contains('not connected'));
    },
  );

  test(
    'OTP failure never creates a session and successful login uses normalized phone',
    () async {
      final repository = FakeMarketplaceRepository()
        ..otpError = const AuthException(
          'provider disabled',
          code: 'phone_provider_disabled',
        );
      final controller = MarketplaceController(repository: repository);
      addTearDown(controller.dispose);
      await controller.initialize();
      expect(await controller.requestOtp('03001234567'), isFalse);
      expect(controller.isAuthenticated, isFalse);
      expect(await controller.verifyOtp('03001234567', '123456'), isFalse);
      repository.otpError = null;
      expect(await controller.requestOtp('0300 123-4567'), isTrue);
      expect(repository.requestedPhone, '+923001234567');
      expect(await controller.verifyOtp('03001234567', '123456'), isTrue);
      expect(controller.profile!.fullName, 'Ali Khan');
      expect(repository.watchedUser, 'customer');
      expect(await controller.signOut(), isTrue);
      expect(controller.profile, isNull);
      expect(controller.jobs, isEmpty);
    },
  );

  test(
    'manual location remains usable when permission is denied and boot never requests GPS',
    () async {
      final location = DeniedLocation();
      final controller = MarketplaceController(
        repository: FakeMarketplaceRepository(),
        locationService: location,
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      expect(location.requests, 0);
      await controller.setManualLocation('Lahore', 'Model Town');
      expect(await controller.useDeviceLocation(), isFalse);
      expect(controller.locationPermission, LocationAccess.denied);
      expect(controller.location!.city, 'Lahore');
      expect(controller.location!.hasCoordinates, isFalse);
      expect(await controller.searchWorkers(), isTrue);
    },
  );

  test(
    'search paginates on server; latest query wins across out of order responses',
    () async {
      final repository = FakeMarketplaceRepository();
      final controller = MarketplaceController(repository: repository);
      addTearDown(controller.dispose);
      await controller.initialize();
      await controller.setManualLocation('Lahore', '');
      await controller.searchWorkers();
      expect(controller.workers.length, 20);
      expect(controller.canLoadMore, isTrue);
      await controller.searchWorkers(append: true);
      expect(controller.workers.length, 21);
      expect(controller.canLoadMore, isFalse);
      expect(repository.requests.last['p_offset'], 20);
      repository.delaySearch = true;
      final old = controller.searchWorkers(
        filters: const WorkerSearch(query: 'old'),
      );
      final latest = controller.searchWorkers(
        filters: const WorkerSearch(query: 'latest'),
      );
      repository.pendingSearches[1].complete([
        {'id': 'latest', 'name': 'Latest worker'},
      ]);
      await latest;
      repository.pendingSearches[0].complete([
        {'id': 'old', 'name': 'Old worker'},
      ]);
      await old;
      expect(controller.workers.single.id, 'latest');
      expect(controller.search.query, 'latest');
    },
  );

  test(
    'suspended accounts and nonparticipants cannot mutate jobs or publish',
    () async {
      final repository = FakeMarketplaceRepository()
        ..uid = 'customer'
        ..status = 'suspended';
      final controller = MarketplaceController(repository: repository);
      addTearDown(controller.dispose);
      await controller.initialize();
      final count = repository.calls;
      expect(
        await controller.saveWorker(
          const WorkerDraft(professionId: 'electrician'),
        ),
        isFalse,
      );
      expect(repository.calls, count);
      repository.status = 'active';
      await controller.loadOwnAccount();
      controller.jobs = [
        MarketplaceJob(
          id: 'job',
          customerId: 'someone',
          workerId: 'worker',
          scheduledAt: DateTime.now(),
        ),
      ];
      expect(await controller.transitionJob('job', 'accepted'), isFalse);
      expect(
        repository.requests.where((r) => r['function'] == 'transition_job'),
        isEmpty,
      );
    },
  );

  test(
    'worker drafts persist safely without coordinates; publish validates required details',
    () async {
      final repository = FakeMarketplaceRepository()..uid = 'customer';
      final controller = MarketplaceController(repository: repository);
      addTearDown(controller.dispose);
      await controller.initialize();
      expect(
        await controller.saveWorker(
          const WorkerDraft(professionId: 'electrician'),
        ),
        isTrue,
      );
      final saved = repository.requests.firstWhere(
        (r) => r['function'] == 'save_worker_profile',
      );
      expect(saved['p_latitude'], isNull);
      expect(saved['p_longitude'], isNull);
      expect((saved['p_profile'] as Map)['published'], isFalse);
      expect(
        await controller.saveWorker(
          const WorkerDraft(professionId: 'electrician', published: true),
        ),
        isFalse,
      );
      expect(
        repository.requests
            .where((r) => r['function'] == 'save_worker_profile')
            .length,
        1,
      );
    },
  );

  test(
    'denied worker GPS blocks available-now update while available-later needs no coordinates',
    () async {
      final repository = FakeMarketplaceRepository()..uid = 'customer';
      final location = DeniedLocation();
      final controller = MarketplaceController(
        repository: repository,
        locationService: location,
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      expect(
        await controller.setAvailability(WorkerAvailability.availableNow),
        isFalse,
      );
      expect(
        repository.requests.where(
          (request) => request['function'] == 'set_worker_availability',
        ),
        isEmpty,
      );
      expect(
        await controller.setAvailability(WorkerAvailability.availableLater),
        isTrue,
      );
      expect(location.requests, 1);
      final request = repository.requests.firstWhere(
        (request) => request['function'] == 'set_worker_availability',
      );
      expect(request['p_status'], 'available_later');
      expect(request['p_latitude'], isNull);
      expect(request['p_longitude'], isNull);
    },
  );

  test(
    'privileged roles cannot be submitted and valid account payload excludes status/admin/phone',
    () async {
      final repository = FakeMarketplaceRepository()..uid = 'customer';
      final controller = MarketplaceController(repository: repository);
      addTearDown(controller.dispose);
      await controller.initialize();
      expect(
        await controller.saveAccount(
          fullName: 'Ali Khan',
          city: 'Lahore',
          roles: ['admin'],
        ),
        isFalse,
      );
      expect(
        repository.requests.where(
          (request) => request['function'] == 'save_profile',
        ),
        isEmpty,
      );
      expect(
        await controller.saveAccount(
          fullName: 'Ali Khan',
          city: 'Lahore',
          roles: ['customer', 'worker'],
        ),
        isTrue,
      );
      final payload =
          repository.requests.firstWhere(
                (request) => request['function'] == 'save_profile',
              )['p_profile']
              as Map;
      expect(payload.keys.toSet(), {
        'full_name',
        'city',
        'neighbourhood',
        'roles',
        'whatsapp',
      });
    },
  );

  test('private jobs arriving after logout are discarded', () async {
    final repository = FakeMarketplaceRepository()..uid = 'customer';
    var logoutHookRan = false;
    final controller = MarketplaceController(
      repository: repository,
      beforeSignOut: () async {
        expect(repository.userId, 'customer');
        logoutHookRan = true;
      },
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    repository.delayedJobs = Completer<List<Map<String, dynamic>>>();
    final pending = controller.loadJobs();
    expect(await controller.signOut(), isTrue);
    repository.delayedJobs!.complete([
      {'id': 'private-job', 'customer_id': 'customer', 'worker_id': 'worker'},
    ]);
    await pending;
    expect(logoutHookRan, isTrue);
    expect(controller.jobs, isEmpty);
    expect(controller.profile, isNull);
  });

  test(
    'failed obsolete search cannot replace current results with an error',
    () async {
      final repository = FakeMarketplaceRepository()..delaySearch = true;
      final controller = MarketplaceController(repository: repository);
      addTearDown(controller.dispose);
      await controller.initialize();
      await controller.setManualLocation('Lahore', '');
      final old = controller.searchWorkers(
        filters: const WorkerSearch(query: 'old'),
      );
      final latest = controller.searchWorkers(
        filters: const WorkerSearch(query: 'latest'),
      );
      repository.pendingSearches[1].complete([
        {'id': 'latest', 'name': 'Latest worker'},
      ]);
      await latest;
      repository.pendingSearches[0].completeError(StateError('obsolete error'));
      await old;
      expect(controller.error, isNull);
      expect(controller.workers.single.id, 'latest');
    },
  );

  test(
    'admin report pages are bounded and responses arriving after logout cannot restore private evidence',
    () async {
      final repository = FakeMarketplaceRepository()
        ..uid = 'customer'
        ..admin = true;
      final controller = MarketplaceController(repository: repository);
      addTearDown(controller.dispose);
      await controller.initialize();
      expect(await controller.loadReports(), isTrue);
      expect(controller.moderationReports.length, 30);
      expect(controller.canLoadMoreReports, isTrue);
      expect(await controller.loadReports(append: true), isTrue);
      expect(controller.moderationReports.length, 31);
      expect(repository.requests.last['p_offset'], 30);
      expect(controller.canLoadMoreReports, isFalse);
      repository.delayedCalls['moderation_reports'] = Completer<dynamic>();
      final loading = controller.loadReports();
      await controller.signOut();
      repository.delayedCalls['moderation_reports']!.complete([
        {'id': 'private', 'details': 'Private evidence'},
      ]);
      expect(await loading, isFalse);
      expect(controller.moderationReports, isEmpty);
    },
  );

  test(
    'account switch immediately clears old profile, jobs and admin evidence',
    () async {
      final repository = FakeMarketplaceRepository()
        ..uid = 'customer'
        ..admin = true;
      final controller = MarketplaceController(repository: repository);
      addTearDown(controller.dispose);
      await controller.initialize();
      await controller.loadReports();
      controller.jobs = [
        MarketplaceJob(
          id: 'private',
          customerId: 'customer',
          workerId: 'worker',
          scheduledAt: DateTime.now(),
        ),
      ];
      repository.uid = 'other-account';
      repository.auth.add(null);
      expect(controller.profile, isNull);
      expect(controller.jobs, isEmpty);
      expect(controller.moderationReports, isEmpty);
      expect(controller.isAdmin, isFalse);
      await Future<void>.delayed(Duration.zero);
    },
  );

  test(
    'contact details and account export completing after logout are discarded',
    () async {
      final repository = FakeMarketplaceRepository()..uid = 'customer';
      final controller = MarketplaceController(repository: repository);
      addTearDown(controller.dispose);
      await controller.initialize();
      repository.delayedCalls['get_worker_contact'] = Completer<dynamic>();
      repository.delayedCalls['export_my_account'] = Completer<dynamic>();
      final contact = controller.requestContact('worker');
      final exported = controller.exportAccount();
      await controller.signOut();
      repository.delayedCalls['get_worker_contact']!.complete({
        'phone': '+923001234567',
      });
      repository.delayedCalls['export_my_account']!.complete({
        'profile': {'phone': '+923001234567'},
      });
      expect(await contact, isNull);
      expect(await exported, isNull);
    },
  );

  test(
    'request in flight cannot create a job under a replacement account',
    () async {
      final repository = FakeMarketplaceRepository()..uid = 'customer';
      final controller = MarketplaceController(repository: repository);
      addTearDown(controller.dispose);
      await controller.initialize();
      repository.delayedCalls['worker_profile'] = Completer<dynamic>();
      final request = controller.requestJob(
        workerId: 'worker',
        description: 'Repair the kitchen wiring',
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
        city: 'Lahore',
        address: 'Private address',
      );
      repository.uid = 'other-account';
      repository.auth.add(null);
      repository.delayedCalls['worker_profile']!.complete({
        'id': 'worker',
        'profession_id': 'electrician',
      });
      expect(await request, isFalse);
      expect(
        repository.requests.where(
          (request) => request['function'] == 'create_job',
        ),
        isEmpty,
      );
    },
  );

  test(
    'worker GPS and account deactivation cannot cross an account switch while awaiting consent/cleanup',
    () async {
      final repository = FakeMarketplaceRepository()..uid = 'customer';
      final location = DeferredLocation();
      final beforeLogout = Completer<void>();
      final controller = MarketplaceController(
        repository: repository,
        locationService: location,
        beforeSignOut: () => beforeLogout.future,
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      final availability = controller.setAvailability(
        WorkerAvailability.availableNow,
      );
      final deactivate = controller.deactivateAccount();
      repository.uid = 'other-account';
      repository.auth.add(null);
      location.pending.complete(
        const SearchLocation(latitude: 31.5, longitude: 74.3, isDevice: true),
      );
      beforeLogout.complete();
      expect(await availability, isFalse);
      expect(await deactivate, isFalse);
      expect(
        repository.requests.where(
          (request) => [
            'deactivate_account',
            'set_worker_availability',
          ].contains(request['function']),
        ),
        isEmpty,
      );
    },
  );
}
