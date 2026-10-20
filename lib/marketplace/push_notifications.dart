import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class PushBackend {
  String? get userId;
  Stream<String?> get authChanges;
  Future<void> register(String token, String platform);
  Future<void> unregister(String token);
}

class SupabasePushBackend implements PushBackend {
  SupabasePushBackend(this.client);
  final SupabaseClient client;
  @override
  String? get userId => client.auth.currentUser?.id;
  @override
  Stream<String?> get authChanges =>
      client.auth.onAuthStateChange.map((state) => state.session?.user.id);
  @override
  Future<void> register(String token, String platform) async {
    await client
        .rpc(
          'register_push_token',
          params: {'p_token': token, 'p_platform': platform},
        )
        .timeout(const Duration(seconds: 15));
  }

  @override
  Future<void> unregister(String token) async {
    await client
        .rpc('unregister_push_token', params: {'p_token': token})
        .timeout(const Duration(seconds: 15));
  }
}

/// Separate account registration from consent and OS provider operations.
abstract class PushTransport {
  bool get initialized;
  String get platform;
  Stream<String> get tokenChanges;
  Stream<void> get messages;
  Stream<void> get opened;
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<void> setAutoInit(bool enabled);
  Future<String?> getToken();
  Future<void> deleteToken();
}

class FirebasePushTransport implements PushTransport {
  @override
  bool get initialized => Firebase.apps.isNotEmpty;
  @override
  String get platform => Platform.isIOS ? 'ios' : 'android';
  @override
  Stream<String> get tokenChanges => FirebaseMessaging.instance.onTokenRefresh;
  @override
  Stream<void> get messages => FirebaseMessaging.onMessage.map((_) {});
  @override
  Stream<void> get opened => FirebaseMessaging.onMessageOpenedApp.map((_) {});
  @override
  Future<void> initialize() async {
    if (!initialized) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
          appId: String.fromEnvironment('FIREBASE_APP_ID'),
          messagingSenderId: String.fromEnvironment(
            'FIREBASE_MESSAGING_SENDER_ID',
          ),
          projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
          iosBundleId: String.fromEnvironment(
            'FIREBASE_IOS_BUNDLE_ID',
            defaultValue: 'com.khidmat.khidmat',
          ),
        ),
      );
    }
  }

  @override
  Future<bool> requestPermission() async {
    final permission = await FirebaseMessaging.instance.requestPermission();
    return permission.authorizationStatus == AuthorizationStatus.authorized ||
        permission.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<void> setAutoInit(bool enabled) async {
    if (initialized) {
      await FirebaseMessaging.instance.setAutoInitEnabled(enabled);
    }
  }

  @override
  Future<String?> getToken() async {
    if (Platform.isIOS &&
        await FirebaseMessaging.instance.getAPNSToken() == null) {
      throw StateError(
        'Apple push registration is not ready. Check Apple push configuration and try again.',
      );
    }
    return FirebaseMessaging.instance.getToken();
  }

  @override
  Future<void> deleteToken() async {
    if (initialized) await FirebaseMessaging.instance.deleteToken();
  }
}

class _PushCancelled implements Exception {}

/// Disabled until explicitly enabled. Logout waits for in-flight registration
/// before revoking a token; every operation is bound to its original account.
class OptionalPushService extends ChangeNotifier {
  OptionalPushService({
    this.client,
    this.onNotification,
    PushBackend? backend,
    PushTransport? transport,
    bool? configurationEnabled,
  }) : _backend =
           backend ?? (client == null ? null : SupabasePushBackend(client)),
       _transport = transport ?? FirebasePushTransport(),
       _configurationEnabled = configurationEnabled,
       _injected = backend != null && transport != null {
    _knownUser = _backend?.userId;
    _authChanges = _backend?.authChanges.listen(
      _authChanged,
      onError: (Object _) {
        _authChanged(null);
      },
    );
  }
  final SupabaseClient? client;
  final Future<void> Function()? onNotification;
  final PushBackend? _backend;
  final PushTransport _transport;
  final bool? _configurationEnabled;
  final bool _injected;
  bool enabled = false, busy = false, _disposed = false;
  String? error, _token, _tokenOwner, _enabledUser, _knownUser;
  int _generation = 0;
  Future<void> _queue = Future.value();
  Future<bool>? _enabling;
  StreamSubscription<String?>? _authChanges;
  StreamSubscription<String>? _tokenChanges;
  StreamSubscription<void>? _messages, _opened;
  static const _environmentConfigured =
      bool.fromEnvironment('ENABLE_PUSH') &&
      String.fromEnvironment('FIREBASE_API_KEY') != '' &&
      String.fromEnvironment('FIREBASE_APP_ID') != '' &&
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID') != '' &&
      String.fromEnvironment('FIREBASE_PROJECT_ID') != '';
  bool get configured =>
      _backend != null &&
      (_configurationEnabled ?? (_injected || _environmentConfigured));

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<T> _serial<T>(Future<T> Function() action) {
    final operation = _queue.then((_) => action());
    _queue = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return operation;
  }

  void _check(int generation, String user) {
    if (_disposed || generation != _generation || user != _backend?.userId) {
      throw _PushCancelled();
    }
  }

  void _authChanged(String? user) {
    if (_disposed || user == _knownUser) return;
    _knownUser = user;
    _generation++;
    enabled = false;
    _enabledUser = null;
    _changed();
    unawaited(
      _serial(() async {
        busy = true;
        _changed();
        await _cleanup();
        busy = false;
        _changed();
      }),
    );
  }

  Future<bool> enable() {
    if (_disposed) return Future.value(false);
    if (enabled && _enabledUser == _backend?.userId) return Future.value(true);
    if (_enabling != null) return _enabling!;
    final user = _backend?.userId;
    if (!configured || user == null) {
      error = configured
          ? 'Sign in to enable push notifications.'
          : 'Push notifications require provider setup. In-app notification history remains available.';
      _changed();
      return Future.value(false);
    }
    final generation = ++_generation;
    final operation = _serial(() => _enable(generation, user));
    _enabling = operation;
    unawaited(
      operation.then((_) {
        if (identical(_enabling, operation)) _enabling = null;
      }),
    );
    return operation;
  }

  Future<bool> _enable(int generation, String user) async {
    busy = true;
    error = null;
    _changed();
    try {
      _check(generation, user);
      await _transport.initialize().timeout(const Duration(seconds: 20));
      _check(generation, user);
      if (!await _transport.requestPermission()) {
        throw StateError(
          'Notification permission was not granted. You can enable it in device settings.',
        );
      }
      _check(generation, user);
      await _transport.setAutoInit(true).timeout(const Duration(seconds: 15));
      _check(generation, user);
      final token = await _transport.getToken().timeout(
        const Duration(seconds: 20),
      );
      _check(generation, user);
      if (token == null) {
        throw StateError(
          'The push provider did not return a device token. Try again.',
        );
      }
      // Retain before RPC: a server commit may succeed even if its response fails.
      _token = token;
      _tokenOwner = user;
      await _backend!.register(token, _transport.platform);
      _check(generation, user);
      await _cancelSubscriptions();
      _check(generation, user);
      _tokenChanges = _transport.tokenChanges.listen(
        (token) {
          unawaited(_serial(() => _refreshToken(token, generation, user)));
        },
        onError: (Object _) {
          _authChanged(null);
        },
      );
      _messages = _transport.messages.listen(
        (_) => _notify(generation, user),
        onError: (Object _) {
          _authChanged(null);
        },
      );
      _opened = _transport.opened.listen(
        (_) => _notify(generation, user),
        onError: (Object _) {
          _authChanged(null);
        },
      );
      _enabledUser = user;
      enabled = true;
      return true;
    } on _PushCancelled {
      await _cleanup();
      return false;
    } catch (exception) {
      error = exception is StateError
          ? exception.message.toString()
          : 'Push notifications could not be enabled. Check provider and device settings.';
      await _cleanup(preserveError: true);
      return false;
    } finally {
      busy = false;
      _changed();
    }
  }

  Future<void> _refreshToken(String token, int generation, String user) async {
    try {
      _check(generation, user);
      if (!enabled || _token == token) return;
      final previous = _token;
      // Rotated tokens are already invalid; free the old device slot first.
      if (previous != null) {
        await _backend!.unregister(previous);
        _check(generation, user);
      }
      _token = token;
      _tokenOwner = user;
      await _backend!.register(token, _transport.platform);
      _check(generation, user);
    } on _PushCancelled {
      await _cleanup();
    } catch (_) {
      _generation++;
      error = 'Push registration needs a retry.';
      await _cleanup(preserveError: true);
      _changed();
    }
  }

  void _notify(int generation, String user) {
    if (_disposed ||
        !enabled ||
        generation != _generation ||
        user != _backend?.userId) {
      return;
    }
    final notification = onNotification;
    if (notification != null) {
      unawaited(
        notification().catchError((Object _) {
          if (!_disposed) {
            error = 'Open notification history to refresh your latest updates.';
            _changed();
          }
        }),
      );
    }
  }

  Future<void> _cancelSubscriptions() async {
    final subscriptions = [_tokenChanges, _messages, _opened];
    _tokenChanges = null;
    _messages = null;
    _opened = null;
    for (final subscription in subscriptions) {
      try {
        await subscription?.cancel();
      } catch (_) {
        /* Generation guards also stop callbacks. */
      }
    }
  }

  Future<bool> _cleanup({bool preserveError = false}) async {
    enabled = false;
    _enabledUser = null;
    await _cancelSubscriptions();
    final token = _token, owner = _tokenOwner;
    var serverRemoved = token == null;
    var providerRevoked = !_transport.initialized;
    var autoInitDisabled = !_transport.initialized;
    if (token != null && owner == _backend?.userId) {
      try {
        await _backend!.unregister(token);
        serverRemoved = true;
      } catch (_) {
        /* Provider deletion also invalidates late server commits. */
      }
    }
    if (_transport.initialized) {
      try {
        await _transport
            .setAutoInit(false)
            .timeout(const Duration(seconds: 15));
        autoInitDisabled = true;
      } catch (_) {
        /* Still attempt token deletion if auto-init setting failed. */
      }
      try {
        await _transport.deleteToken().timeout(const Duration(seconds: 15));
        providerRevoked = true;
      } catch (_) {
        /* Retain token when both revocation methods fail. */
      }
    }
    if (serverRemoved || providerRevoked) {
      _token = null;
      _tokenOwner = null;
    }
    final revoked =
        autoInitDisabled &&
        providerRevoked &&
        (serverRemoved || owner != _backend?.userId);
    if (!revoked && !preserveError) {
      error =
          'Device registration could not be fully revoked. Retry when connected.';
    } else if (!revoked && preserveError) {
      error =
          'Push setup failed and device cleanup needs a retry when connected.';
    }
    return revoked;
  }

  Future<bool> disable() {
    if (_disposed) return Future.value(false);
    _generation++;
    enabled = false;
    _enabledUser = null;
    _changed();
    return _serial(() async {
      busy = true;
      error = null;
      _changed();
      try {
        return await _cleanup();
      } finally {
        busy = false;
        _changed();
      }
    });
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    enabled = false;
    unawaited(_authChanges?.cancel());
    // Pending enable cancels before attaching listeners. Never initialize here.
    unawaited(
      _serial(() async {
        await _cleanup();
      }),
    );
    super.dispose();
  }
}
