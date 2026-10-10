import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../localization/app_language.dart' show translateUrdu;
import '../data/bundled_profession_catalog.dart';
import '../models/marketplace_models.dart';
import 'device_location_service.dart';
import 'marketplace_repository.dart';
import 'worker_photo_service.dart';

export '../models/marketplace_models.dart';
export 'device_location_service.dart';
export 'marketplace_repository.dart';

enum CatalogSource { bundled, server }

/// Coordinates authenticated operations. All authoritative validation, ownership
/// and eligibility checks also run in the database; UI roles are never trusted.
class MarketplaceController extends ChangeNotifier with WidgetsBindingObserver {
  MarketplaceController({
    SupabaseClient? client,
    MarketplaceRepository? repository,
    DeviceLocationService? locationService,
    this.configurationError,
    this.beforeSignOut,
  }) : client = client,
       _repository =
           repository ??
           (client == null ? null : SupabaseMarketplaceRepository(client)),
       _locationService = locationService ?? DeviceLocationService();

  final SupabaseClient? client;
  final MarketplaceRepository? _repository;
  final DeviceLocationService _locationService;
  final String? configurationError;
  Future<void> Function()? beforeSignOut;
  bool initialized = false,
      _initializing = false,
      _disposed = false,
      isAdmin = false;
  bool _observing = false;
  int _operations = 0, _searchGeneration = 0, _sessionGeneration = 0;
  String? error, notice, _watchingUser, _pendingPhone;
  DateTime? _lastOtpAt;
  StreamSubscription<void>? _authSubscription, _changeSubscription;
  Timer? _refreshDebounce;
  Timer? _freshnessTimer;
  MarketplaceProfile? profile;
  WorkerDraft? ownWorker;
  WorkerAvailability ownAvailability = WorkerAvailability.unknown;
  // Browsing service definitions never depends on credentials, GPS or a server.
  List<Profession> professions = loadBundledProfessionCatalog();
  CatalogSource catalogSource = CatalogSource.bundled;
  bool catalogLoading = false, workerSearchLoading = false;
  String? catalogError, workerSearchError;
  Future<bool>? _catalogFetch;
  List<MarketplaceWorker> workers = [];
  List<MarketplaceJob> jobs = [];
  List<MarketplaceNotification> notifications = [];
  List<Map<String, dynamic>> moderationReports = [];
  bool canLoadMoreReports = false;
  int _reportOffset = 0;
  List<Map<String, dynamic>> moderationReviews = [];
  bool canLoadMoreModerationReviews = false;
  int _moderationReviewOffset = 0;
  String? _moderationWorker;
  WorkerSearch search = const WorkerSearch();
  SearchLocation? location;
  LocationAccess locationPermission = LocationAccess.unknown;
  bool canLoadMore = false,
      canLoadMoreJobs = false,
      canLoadMoreNotifications = false;
  int _workerOffset = 0, _jobOffset = 0, _notificationOffset = 0;
  static const _pageSize = 20;
  bool get configured => _repository != null;
  bool get busy => _operations > 0;
  bool get isAuthenticated => userId != null;
  String? get userId => _repository?.userId;
  String? get pendingPhone => _pendingPhone;
  int get unreadCount => notifications.where((n) => !n.isRead).length;
  List<String> get professionCategories =>
      professions.map((p) => p.category).toSet().toList();

  List<Profession> filterProfessions({
    String query = '',
    String? category,
    String? professionId,
    String? skillId,
  }) {
    final terms = query
        .toLowerCase()
        .trim()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty);
    return professions.where((profession) {
      if (category != null && profession.category != category) return false;
      if (professionId != null && profession.id != professionId) return false;
      if (skillId != null &&
          !profession.skills.any((skill) => skill.id == skillId)) {
        return false;
      }
      final searchable =
          '${profession.category} ${translateUrdu(profession.category)} '
                  '${profession.name} ${profession.nameUr} '
                  '${profession.skills.map((skill) => '${skill.name} ${translateUrdu(skill.name)}').join(' ')}'
              .toLowerCase();
      final englishWords = RegExp(
        r'[a-z0-9]+',
      ).allMatches(searchable).map((match) => match.group(0)!);
      return terms.every(
        (term) => RegExp(r'^[a-z0-9]+$').hasMatch(term)
            ? englishWords.any((word) => word.startsWith(term))
            : searchable.contains(term),
      );
    }).toList();
  }

  /// Skills and categories are stored under their canonical catalogue labels.
  /// Convert only exact known Urdu aliases; free-form customer/worker names and
  /// descriptions remain untouched, and the visible search retains its text.
  String _canonicalWorkerQuery(String query) {
    String normalize(String label) =>
        label.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final normalized = normalize(query);
    if (normalized.isEmpty) return query;
    final candidates = <String>{};
    for (final profession in professions) {
      if (profession.nameUr.isNotEmpty &&
          normalize(profession.nameUr) == normalized) {
        candidates.add(profession.name);
      }
      for (final label in [
        profession.name,
        profession.category,
        ...profession.skills.map((skill) => skill.name),
      ]) {
        final translated = translateUrdu(label);
        if (translated != label && normalize(translated) == normalized) {
          candidates.add(label);
        }
      }
    }
    return candidates.length == 1 ? candidates.single : query;
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  void clearMessages() {
    error = null;
    notice = null;
    _changed();
  }

  bool _sameSession(String? uid, int generation) =>
      !_disposed && uid == userId && generation == _sessionGeneration;
  MarketplaceRepository get _api =>
      _repository ??
      (throw StateError(
        configurationError ??
            'The marketplace is not connected yet. Configure the service to continue.',
      ));
  void _requireAccount({String? role}) {
    if (!isAuthenticated) {
      throw StateError('Sign in with your verified phone number to continue.');
    }
    if (profile == null) {
      throw StateError('Your account has not loaded. Refresh and try again.');
    }
    if (!profile!.isActive) {
      throw StateError(
        'Your account is ${profile!.status.replaceAll('_', ' ')}. Contact support for help.',
      );
    }
    if (role != null && !profile!.roles.contains(role)) {
      throw StateError('Enable the $role role in your account first.');
    }
  }

  Future<T?> _run<T>(Future<T> Function() action) async {
    if (_disposed) return null;
    _operations++;
    error = null;
    notice = null;
    _changed();
    try {
      return await action();
    } catch (exception) {
      if (!_disposed) error = marketplaceError(exception);
      return null;
    } finally {
      _operations--;
      _changed();
    }
  }

  Future<bool> initialize() async {
    if (initialized || _initializing || _disposed) return initialized;
    _initializing = true;
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    if (!configured) {
      initialized = true;
      _initializing = false;
      notice =
          configurationError ??
          'Browse services now. Connecting to workers requires online service setup. Your saved phone records remain available.';
      catalogError = configurationError;
      _changed();
      return true;
    }
    _freshnessTimer ??= Timer.periodic(const Duration(minutes: 1), (_) {
      if (!_disposed &&
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.paused) {
        _changed();
      }
    });
    _authSubscription ??= _api.authChanges.listen(
      (_) {
        final previousUser = _watchingUser;
        _sessionGeneration++;
        _syncWatch();
        if (!isAuthenticated || previousUser != userId) _clearAccount();
        if (isAuthenticated) unawaited(loadOwnAccount());
      },
      onError: (Object exception) {
        error = marketplaceError(exception);
        _changed();
      },
    );
    _changeSubscription ??= _api.changes.listen((_) {
      _refreshDebounce?.cancel();
      _refreshDebounce = Timer(const Duration(milliseconds: 350), () {
        if (!_disposed) unawaited(refresh());
      });
    });
    final result = await _run(() async {
      await reloadCatalog();
      _syncWatch();
      if (isAuthenticated) await _loadOwnAccount();
      initialized = true;
      return true;
    });
    _initializing = false;
    return result ?? false;
  }

  /// Server definitions replace bundled data, including an intentionally empty
  /// active catalogue. A failed refresh retains the last successful definitions.
  Future<bool> reloadCatalog() {
    if (_disposed || !configured) return Future.value(false);
    final pending = _catalogFetch;
    if (pending != null) return pending;
    final operation = _fetchCatalog();
    _catalogFetch = operation;
    unawaited(
      operation.then((_) {
        if (identical(_catalogFetch, operation)) _catalogFetch = null;
      }),
    );
    return operation;
  }

  Future<bool> _fetchCatalog() async {
    catalogLoading = true;
    catalogError = null;
    _changed();
    try {
      final rows = await _api.fetchProfessions().timeout(
        const Duration(seconds: 15),
      );
      final loaded = rows.map(Profession.fromJson).toList();
      if (loaded.any(
            (profession) =>
                profession.id.isEmpty ||
                profession.name.isEmpty ||
                profession.category.isEmpty,
          ) ||
          loaded.map((profession) => profession.id).toSet().length !=
              loaded.length) {
        throw const FormatException(
          'The service catalogue could not be read. Please retry.',
        );
      }
      if (_disposed) return false;
      professions = List.unmodifiable(loaded);
      catalogSource = CatalogSource.server;
      return true;
    } catch (exception) {
      if (!_disposed) catalogError = marketplaceError(exception);
      return false;
    } finally {
      catalogLoading = false;
      _changed();
    }
  }

  void _syncWatch() {
    if (_watchingUser != userId) {
      _watchingUser = userId;
      _api.watchUser(userId);
    }
  }

  void _clearAccount() {
    profile = null;
    ownWorker = null;
    ownAvailability = WorkerAvailability.unknown;
    jobs = [];
    notifications = [];
    moderationReports = [];
    moderationReviews = [];
    isAdmin = false;
    _moderationReviewOffset = 0;
    canLoadMoreModerationReviews = false;
    _reportOffset = 0;
    canLoadMoreReports = false;
    _moderationWorker = null;
    _jobOffset = _notificationOffset = 0;
    canLoadMoreJobs = canLoadMoreNotifications = false;
    _changed();
  }

  Future<bool> requestOtp(String phone) async =>
      await _run(() async {
        final normalized = normalizePakistaniPhone(phone);
        if (_lastOtpAt != null &&
            DateTime.now().difference(_lastOtpAt!) <
                const Duration(seconds: 60)) {
          throw StateError('Wait a minute before requesting another code.');
        }
        await _api.requestOtp(normalized);
        _pendingPhone = normalized;
        _lastOtpAt = DateTime.now();
        notice = 'A verification code was requested. Check your SMS messages.';
        return true;
      }) ??
      false;

  Future<bool> verifyOtp(String phone, String token) async =>
      await _run(() async {
        final normalized = normalizePakistaniPhone(phone);
        if (!RegExp(r'^\d{6,10}$').hasMatch(token.trim())) {
          throw const FormatException(
            'Enter the verification code from your SMS.',
          );
        }
        if (_pendingPhone != normalized) {
          throw StateError('Request a code for this phone number first.');
        }
        await _api.verifyOtp(normalized, token.trim());
        _sessionGeneration++;
        _pendingPhone = null;
        _syncWatch();
        await _loadOwnAccount();
        notice = 'Phone number verified.';
        return true;
      }) ??
      false;

  Future<bool> signOut() async =>
      await _run(() async {
        await beforeSignOut?.call();
        await _api.signOut();
        _sessionGeneration++;
        _syncWatch();
        _clearAccount();
        notice = 'Signed out.';
        return true;
      }) ??
      false;

  Future<void> _loadOwnAccount() async {
    final uid = userId;
    final generation = _sessionGeneration;
    if (uid == null) {
      _clearAccount();
      return;
    }
    final row = await _api.fetchProfile();
    if (generation != _sessionGeneration || uid != userId || _disposed) return;
    profile = row == null ? null : MarketplaceProfile.fromJson(row);
    ownWorker = null;
    ownAvailability = WorkerAvailability.unknown;
    if (profile == null) {
      throw StateError(
        'Your account record is missing. Apply the database setup and retry.',
      );
    }
    if (location == null && profile!.city.isNotEmpty) {
      location = SearchLocation(
        city: profile!.city,
        neighbourhood: profile!.neighbourhood,
      );
    }
    if (profile!.isActive) {
      final own = await _api.call('worker_own_profile');
      if (generation != _sessionGeneration || uid != userId || _disposed) {
        return;
      }
      if (own is Map) {
        final worker = MarketplaceWorker.fromJson(
          Map<String, dynamic>.from(own),
        );
        ownWorker = WorkerDraft.fromWorker(worker);
        ownAvailability = worker.currentAvailability;
      }
      final admin = await _api.call('admin_check') == true;
      if (generation != _sessionGeneration || uid != userId || _disposed) {
        return;
      }
      isAdmin = admin;
      if (!admin) {
        moderationReports = [];
        moderationReviews = [];
        canLoadMoreReports = canLoadMoreModerationReviews = false;
        _reportOffset = _moderationReviewOffset = 0;
      }
      await _loadJobs();
      await _loadNotifications();
    } else {
      isAdmin = false;
      jobs = [];
      notifications = [];
      moderationReports = [];
      moderationReviews = [];
      canLoadMoreReports = canLoadMoreModerationReviews = false;
    }
    _changed();
  }

  Future<bool> loadOwnAccount() async =>
      await _run(() async {
        await _loadOwnAccount();
        return true;
      }) ??
      false;

  Future<bool> saveAccount({
    required String fullName,
    required String city,
    String neighbourhood = '',
    List<String> roles = const ['customer'],
    String? whatsapp,
  }) async =>
      await _run(() async {
        _requireAccount();
        final uid = userId, generation = _sessionGeneration;
        if (fullName.trim().length < 2 ||
            fullName.length > 100 ||
            city.trim().length < 2 ||
            city.length > 80 ||
            neighbourhood.length > 100) {
          throw const FormatException(
            'Enter your name, city and a valid neighbourhood.',
          );
        }
        if (roles.isEmpty ||
            roles.toSet().length != roles.length ||
            roles.any((role) => !['customer', 'worker'].contains(role))) {
          throw const FormatException(
            'Choose customer, worker or both account roles.',
          );
        }
        final normalizedWhatsapp = (whatsapp?.trim().isNotEmpty ?? false)
            ? normalizePakistaniPhone(whatsapp!)
            : '';
        final row = await _api.call(
          'save_profile',
          params: {
            'p_profile': {
              'full_name': fullName.trim(),
              'city': city.trim(),
              'neighbourhood': neighbourhood.trim(),
              'roles': roles,
              'whatsapp': normalizedWhatsapp,
            },
          },
        );
        if (!_sameSession(uid, generation)) return false;
        if (row is Map) {
          profile = MarketplaceProfile.fromJson(Map<String, dynamic>.from(row));
        }
        await _loadOwnAccount();
        notice = 'Your account has been saved.';
        return true;
      }) ??
      false;

  Future<bool> setManualLocation(String city, String neighbourhood) async =>
      await _run(() async {
        final next = SearchLocation(
          city: city.trim(),
          neighbourhood: neighbourhood.trim(),
        );
        next.validate();
        location = next;
        workers = [];
        canLoadMore = false;
        workerSearchError = null;
        workerSearchLoading = false;
        _searchGeneration++;
        notice = 'Browsing ${next.label}. Distances require device location.';
        return true;
      }) ??
      false;

  Future<bool> useDeviceLocation() async =>
      await _run(() async {
        try {
          location = await _locationService.currentLocation();
          locationPermission = LocationAccess.granted;
          workers = [];
          canLoadMore = false;
          workerSearchError = null;
          workerSearchLoading = false;
          _searchGeneration++;
          notice = 'Current location selected for this search.';
          return true;
        } on LocationAccessException catch (exception) {
          locationPermission = exception.access;
          rethrow;
        }
      }) ??
      false;
  Future<bool> openLocationSettings() =>
      locationPermission == LocationAccess.serviceDisabled
      ? _locationService.openLocationSettings()
      : _locationService.openAppSettings();

  Future<bool> searchWorkers({
    WorkerSearch? filters,
    bool append = false,
  }) async {
    if (_disposed) return false;
    final generation = ++_searchGeneration;
    final requested = filters ?? search;
    _operations++;
    workerSearchLoading = true;
    workerSearchError = null;
    try {
      requested.validate();
      // The service/category/skill selection remains usable while offline.
      search = requested;
      if (!append) {
        workers = [];
        canLoadMore = false;
        _workerOffset = 0;
      }
      _changed();
      if (!configured) {
        workerSearchError =
            configurationError ??
            'Worker discovery needs an online connection to Khidmat. You can browse all services and use your saved phone records.';
        return false;
      }
      if (location == null) {
        workers = [];
        canLoadMore = false;
        notice = 'Choose your location to find workers.';
        return true;
      }
      if (append && !canLoadMore) return true;
      final offset = append ? _workerOffset : 0;
      final effectiveFilters = requested.copyWith(
        query: _canonicalWorkerQuery(requested.query),
      );
      final rows = await _api
          .call(
            'search_workers',
            params: effectiveFilters.toRpc(
              location!,
              offset: offset,
              limit: _pageSize,
            ),
          )
          .timeout(const Duration(seconds: 20));
      if (_disposed || generation != _searchGeneration) return false;
      final loaded = _rows(rows).map(MarketplaceWorker.fromJson).toList();
      final merged = <String, MarketplaceWorker>{
        if (append)
          for (final worker in workers) worker.id: worker,
        for (final worker in loaded) worker.id: worker,
      };
      search = requested;
      workers = merged.values.toList();
      _workerOffset = offset + loaded.length;
      canLoadMore = loaded.length == _pageSize && _workerOffset <= 10000;
      return true;
    } catch (exception) {
      if (!_disposed && generation == _searchGeneration) {
        workerSearchError = marketplaceError(exception);
      }
      return false;
    } finally {
      _operations--;
      if (generation == _searchGeneration) workerSearchLoading = false;
      _changed();
    }
  }

  Future<MarketplaceWorker?> loadWorker(String id) => _run(() async {
    final row = await _api.call('worker_profile', params: {'p_worker_id': id});
    if (row is! Map) throw StateError('This worker is not currently listed.');
    return MarketplaceWorker.fromJson(Map<String, dynamic>.from(row));
  });

  Future<bool> saveWorker(WorkerDraft draft) async =>
      await _run(() async {
        _requireAccount(role: 'worker');
        final uid = userId, generation = _sessionGeneration;
        final profession = professions
            .where((p) => p.id == draft.professionId)
            .firstOrNull;
        if (profession == null) {
          throw const FormatException('Choose an available profession.');
        }
        draft.validate(profession);
        await _api.call(
          'save_worker_profile',
          params: {
            'p_profile': draft.toJson(),
            'p_latitude': null,
            'p_longitude': null,
          },
        );
        if (!_sameSession(uid, generation)) return false;
        await _loadOwnAccount();
        notice = draft.published
            ? 'Your worker profile is published.'
            : 'Your progress has been saved.';
        return true;
      }) ??
      false;

  Future<bool> setAvailability(WorkerAvailability value) async =>
      await _run(() async {
        _requireAccount(role: 'worker');
        final uid = userId, generation = _sessionGeneration;
        SearchLocation? fix;
        if (value == WorkerAvailability.availableNow) {
          try {
            fix = await _locationService.currentLocation();
            locationPermission = LocationAccess.granted;
          } on LocationAccessException catch (exception) {
            locationPermission = exception.access;
            rethrow;
          }
        }
        if (!_sameSession(uid, generation)) return false;
        await _api.call(
          'set_worker_availability',
          params: {
            'p_status': value.value,
            'p_latitude': fix?.latitude,
            'p_longitude': fix?.longitude,
          },
        );
        if (!_sameSession(uid, generation)) return false;
        await _loadOwnAccount();
        notice = value.label;
        return true;
      }) ??
      false;

  Future<WorkerContactDetails?> requestContact(String id) =>
      _run<WorkerContactDetails?>(() async {
        _requireAccount(role: 'customer');
        final uid = userId, generation = _sessionGeneration;
        final row = await _api.call(
          'get_worker_contact',
          params: {'p_worker_id': id},
        );
        if (!_sameSession(uid, generation) || profile?.isActive != true) {
          return null;
        }
        if (row is! Map) {
          throw StateError('The worker has not shared their contact details.');
        }
        return WorkerContactDetails.fromJson(Map<String, dynamic>.from(row));
      });

  Future<String?> uploadImage(
    Uint8List bytes,
    String filename,
    String mimeType,
  ) => _run<String?>(() async {
    _requireAccount(role: 'worker');
    final uid = userId, generation = _sessionGeneration;
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw const FormatException('Choose an image smaller than 5 MB.');
    }
    final extensions = {
      'image/jpeg': 'jpg',
      'image/png': 'png',
      'image/webp': 'webp',
    };
    final extension = extensions[mimeType.toLowerCase()];
    bool starts(List<int> signature) =>
        bytes.length >= signature.length &&
        List.generate(
          signature.length,
          (i) => bytes[i] == signature[i],
        ).every((b) => b);
    final valid = switch (extension) {
      'jpg' => starts([0xff, 0xd8, 0xff]),
      'png' => starts([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
      'webp' =>
        starts([0x52, 0x49, 0x46, 0x46]) &&
            bytes.length > 11 &&
            bytes[8] == 0x57 &&
            bytes[9] == 0x45 &&
            bytes[10] == 0x42 &&
            bytes[11] == 0x50,
      _ => false,
    };
    if (extension == null || !valid) {
      throw const FormatException('Choose a JPEG, PNG or WebP photo.');
    }
    final sanitized = await prepareWorkerPhoto(bytes);
    if (!_sameSession(uid, generation)) return null;
    final url = await _api.uploadImage(sanitized, 'jpg', 'image/jpeg');
    return _sameSession(uid, generation) ? url : null;
  });

  Future<void> _loadJobs({bool append = false}) async {
    final generation = _sessionGeneration;
    final uid = userId;
    if (uid == null) {
      jobs = [];
      return;
    }
    final offset = append ? _jobOffset : 0;
    final rows = await _api.fetchJobs(offset: offset, limit: _pageSize);
    if (_disposed || generation != _sessionGeneration || uid != userId) return;
    final loaded = rows.map(MarketplaceJob.fromJson).toList();
    jobs = <String, MarketplaceJob>{
      if (append)
        for (final job in jobs) job.id: job,
      for (final job in loaded) job.id: job,
    }.values.toList();
    _jobOffset = offset + rows.length;
    canLoadMoreJobs = rows.length == _pageSize;
  }

  Future<bool> loadJobs({bool append = false}) async =>
      await _run(() async {
        _requireAccount();
        await _loadJobs(append: append);
        return true;
      }) ??
      false;

  Future<bool> requestJob({
    required String workerId,
    required String description,
    required DateTime scheduledAt,
    required String city,
    String neighbourhood = '',
    String address = '',
    double? offeredPrice,
    String? professionId,
  }) async =>
      await _run(() async {
        _requireAccount(role: 'customer');
        final uid = userId, generation = _sessionGeneration;
        if (workerId == userId) {
          throw const FormatException('You cannot request your own services.');
        }
        if (description.trim().length < 10 ||
            description.length > 2000 ||
            city.trim().length < 2 ||
            city.length > 80 ||
            neighbourhood.length > 100 ||
            address.length > 300 ||
            scheduledAt.isBefore(DateTime.now()) ||
            scheduledAt.isAfter(
              DateTime.now().add(const Duration(days: 365)),
            ) ||
            (offeredPrice != null &&
                (!offeredPrice.isFinite ||
                    offeredPrice < 0 ||
                    offeredPrice > 1000000))) {
          throw const FormatException(
            'Describe the work, choose your city, a future date within a year and a valid price.',
          );
        }
        final worker = await _api.call(
          'worker_profile',
          params: {'p_worker_id': workerId},
        );
        if (!_sameSession(uid, generation)) return false;
        if (worker is! Map) {
          throw StateError('This worker is not accepting requests.');
        }
        await _api.call(
          'create_job',
          params: {
            'p_worker_id': workerId,
            'p_profession_id': professionId ?? worker['profession_id'],
            'p_description': description.trim(),
            'p_scheduled_at': scheduledAt.toUtc().toIso8601String(),
            'p_city': city.trim(),
            'p_neighbourhood': neighbourhood.trim(),
            'p_address': address.trim(),
            'p_offered_price': offeredPrice,
          },
        );
        if (!_sameSession(uid, generation)) return false;
        await _loadJobs();
        notice =
            'Your request was sent. The worker must accept it to confirm the booking.';
        return true;
      }) ??
      false;

  Future<bool> transitionJob(String id, String status) async =>
      await _run(() async {
        _requireAccount();
        final current = jobs.where((job) => job.id == id).firstOrNull;
        if (current == null ||
            !current.allowedTransitions(userId).contains(status)) {
          throw StateError(
            'This job cannot be changed to that status. Refresh to see its latest progress.',
          );
        }
        await _api.call(
          'transition_job',
          params: {'p_job_id': id, 'p_status': status},
        );
        await _loadJobs();
        notice = 'Job progress updated.';
        return true;
      }) ??
      false;

  Future<bool> submitReview(String id, int rating, String comment) async =>
      await _run(() async {
        _requireAccount(role: 'customer');
        final job = jobs.where((job) => job.id == id).firstOrNull;
        if (job == null || !job.canReview(userId)) {
          throw StateError(
            'Reviews are available once for your completed jobs.',
          );
        }
        if (rating < 1 || rating > 5 || comment.length > 1000) {
          throw const FormatException(
            'Choose 1 to 5 stars and a review under 1000 characters.',
          );
        }
        await _api.call(
          'review_job',
          params: {
            'p_job_id': id,
            'p_rating': rating,
            'p_comment': comment.trim(),
          },
        );
        await _loadJobs();
        notice = 'Thank you. Your review has been saved.';
        return true;
      }) ??
      false;

  Future<void> _loadNotifications({bool append = false}) async {
    final uid = userId;
    final generation = _sessionGeneration;
    if (uid == null) {
      notifications = [];
      return;
    }
    final offset = append ? _notificationOffset : 0;
    final rows = await _api.fetchNotifications(offset: offset, limit: 30);
    if (_disposed || generation != _sessionGeneration || uid != userId) return;
    final loaded = rows.map(MarketplaceNotification.fromJson).toList();
    notifications = <String, MarketplaceNotification>{
      if (append)
        for (final item in notifications) item.id: item,
      for (final item in loaded) item.id: item,
    }.values.toList();
    _notificationOffset = offset + rows.length;
    canLoadMoreNotifications = rows.length == 30;
  }

  Future<bool> loadNotifications({bool append = false}) async =>
      await _run(() async {
        _requireAccount();
        await _loadNotifications(append: append);
        return true;
      }) ??
      false;
  Future<bool> markNotificationRead(String id) async =>
      await _run(() async {
        _requireAccount();
        await _api.call('read_notification', params: {'p_notification_id': id});
        await _loadNotifications();
        return true;
      }) ??
      false;

  Future<bool> reportAccount(String id, String reason, String details) async =>
      await _run(() async {
        _requireAccount();
        if (id == userId ||
            reason.trim().length < 3 ||
            reason.length > 100 ||
            details.length > 2000) {
          throw const FormatException(
            'Choose a reason and keep the details under 2000 characters.',
          );
        }
        await _api.call(
          'report_account',
          params: {
            'p_reported_user_id': id,
            'p_reason': reason.trim(),
            'p_details': details.trim(),
          },
        );
        notice = 'Your report has been sent for review.';
        return true;
      }) ??
      false;
  Future<bool> loadReports({bool append = false}) async =>
      await _run(() async {
        _requireAccount();
        if (!isAdmin) throw StateError('Administrator access is required.');
        final uid = userId, generation = _sessionGeneration;
        final offset = append ? _reportOffset : 0;
        final rows = _rows(
          await _api.call(
            'moderation_reports',
            params: {'p_limit': 30, 'p_offset': offset},
          ),
        );
        if (!_sameSession(uid, generation) || !isAdmin) return false;
        moderationReports = <String, Map<String, dynamic>>{
          if (append)
            for (final report in moderationReports)
              report['id'] as String: report,
          for (final report in rows) report['id'] as String: report,
        }.values.toList();
        _reportOffset = offset + rows.length;
        canLoadMoreReports = rows.length == 30 && _reportOffset <= 10000;
        return true;
      }) ??
      false;
  Future<bool> moderateAccount(String id, String action, String reason) async =>
      await _run(() async {
        _requireAccount();
        if (!isAdmin) throw StateError('Administrator access is required.');
        if (![
              'suspend',
              'reactivate',
              'verify_worker',
              'revoke_verification',
            ].contains(action) ||
            reason.trim().length < 10 ||
            reason.length > 1000) {
          throw const FormatException(
            'Choose an action and explain the moderation decision.',
          );
        }
        await _api.call(
          'moderate_account',
          params: {
            'p_user_id': id,
            'p_action': action,
            'p_reason': reason.trim(),
          },
        );
        notice = 'The moderation decision has been saved.';
        return true;
      }) ??
      false;

  Future<String?> exportAccount() => _run<String?>(() async {
    _requireAccount();
    final uid = userId, generation = _sessionGeneration;
    final data = await _api.call('export_my_account');
    return _sameSession(uid, generation)
        ? const JsonEncoder.withIndent('  ').convert(data)
        : null;
  });
  Future<bool> deactivateAccount() async =>
      await _run(() async {
        _requireAccount();
        final uid = userId, generation = _sessionGeneration;
        await beforeSignOut?.call();
        if (!_sameSession(uid, generation)) return false;
        await _api.call('deactivate_account');
        if (!_sameSession(uid, generation)) return false;
        await _api.signOut();
        _sessionGeneration++;
        _syncWatch();
        _clearAccount();
        notice =
            'Your account is deactivated. Existing job and account records are retained.';
        return true;
      }) ??
      false;

  Future<bool> loadModerationReviews({
    String? workerId,
    bool append = false,
  }) async =>
      await _run(() async {
        _requireAccount();
        if (!isAdmin) throw StateError('Administrator access is required.');
        final uid = userId, generation = _sessionGeneration;
        final offset = append && workerId == _moderationWorker
            ? _moderationReviewOffset
            : 0;
        final rows = _rows(
          await _api.call(
            'moderation_reviews',
            params: {
              'p_worker_id': workerId,
              'p_limit': 30,
              'p_offset': offset,
            },
          ),
        );
        if (!_sameSession(uid, generation) || !isAdmin) return false;
        moderationReviews = <String, Map<String, dynamic>>{
          if (offset > 0)
            for (final review in moderationReviews)
              review['id'] as String: review,
          for (final review in rows) review['id'] as String: review,
        }.values.toList();
        _moderationWorker = workerId;
        _moderationReviewOffset = offset + rows.length;
        canLoadMoreModerationReviews =
            rows.length == 30 && _moderationReviewOffset <= 10000;
        return true;
      }) ??
      false;
  Future<bool> moderateReview(String id, bool hidden, String reason) async =>
      await _run(() async {
        _requireAccount();
        if (!isAdmin) throw StateError('Administrator access is required.');
        if (reason.trim().length < 10 || reason.length > 1000) {
          throw const FormatException(
            'Explain the moderation decision in 10 to 1000 characters.',
          );
        }
        await _api.call(
          'moderate_review',
          params: {
            'p_review_id': id,
            'p_hidden': hidden,
            'p_reason': reason.trim(),
          },
        );
        notice = hidden
            ? 'The review was hidden from public listings.'
            : 'The review is visible again.';
        return true;
      }) ??
      false;

  Future<bool> refresh() async {
    if (_disposed || !configured) return false;
    if (!initialized && !await initialize()) return false;
    final result =
        await _run(() async {
          await reloadCatalog();
          if (isAuthenticated) await _loadOwnAccount();
          return true;
        }) ??
        false;
    if (result && location != null) await searchWorkers();
    return result;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && initialized) unawaited(refresh());
  }

  @override
  void dispose() {
    _disposed = true;
    _sessionGeneration++;
    _searchGeneration++;
    WidgetsBinding.instance.removeObserver(this);
    _refreshDebounce?.cancel();
    unawaited(_authSubscription?.cancel());
    _freshnessTimer?.cancel();
    unawaited(_changeSubscription?.cancel());
    _repository?.dispose();
    super.dispose();
  }

  static List<Map<String, dynamic>> _rows(dynamic data) => data is List
      ? data
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList()
      : [];
}

String marketplaceError(Object exception) {
  if (exception is FormatException) return exception.message;
  if (exception is StateError) return exception.message.toString();
  if (exception is LocationAccessException) return exception.message;
  if (exception is AuthException) {
    final code = exception.code ?? '';
    if (code.contains('rate') || exception.statusCode == '429') {
      return 'Too many attempts. Wait a little and try again.';
    }
    if (code.contains('otp') || code.contains('token')) {
      return 'This verification code is invalid or expired. Request a new code.';
    }
    if (code.contains('phone_provider') || code.contains('sms')) {
      return 'Phone verification is not available. Check the SMS provider configuration.';
    }
    return 'Sign-in could not be completed. Check your code, connection and phone verification setup.';
  }
  if (exception is PostgrestException) {
    if (['PGRST202', 'PGRST205', '42P01', '42883'].contains(exception.code)) {
      return 'The marketplace database has not been set up for this app version.';
    }
    if (exception.code == '42501') {
      return 'You do not have permission to perform this action.';
    }
    if (exception.code == 'P0001' ||
        exception.code == '22023' ||
        exception.code == '23514') {
      return exception.message.length <= 240
          ? exception.message
          : 'Check the submitted details and try again.';
    }
    return 'The request could not be saved. Refresh and check your connection.';
  }
  if (exception is StorageException) {
    return 'The photo could not be uploaded. Check storage setup, image size and your connection.';
  }
  if (exception is TimeoutException) {
    return 'This took too long. Check your connection or choose your city manually.';
  }
  return 'The service could not be reached. Check your connection and try again.';
}
