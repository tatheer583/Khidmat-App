import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:khidmat/marketplace/push_notifications.dart';

class TestPushBackend implements PushBackend {
  String? uid = 'account-a';
  final accounts = StreamController<String?>.broadcast(sync: true);
  final registered = <String, String>{};
  final calls = <String>[];
  final registrationStarted = Completer<void>();
  Completer<void>? registrationDelay;
  bool failRegistration = false, failUnregister = false;
  @override
  String? get userId => uid;
  @override
  Stream<String?> get authChanges => accounts.stream;
  void switchUser(String? user) {
    uid = user;
    accounts.add(user);
  }

  @override
  Future<void> register(String token, String platform) async {
    final owner = uid!;
    calls.add('register-start:$owner:$token');
    if (!registrationStarted.isCompleted) registrationStarted.complete();
    await registrationDelay?.future;
    registered[token] = owner;
    calls.add('register-done:$owner:$token');
    if (failRegistration) {
      throw Exception('Private server response must not be exposed');
    }
  }

  @override
  Future<void> unregister(String token) async {
    calls.add('unregister:$uid:$token');
    if (failUnregister) {
      throw Exception('Private server response must not be exposed');
    }
    if (registered[token] == uid) registered.remove(token);
  }
}

class TestPushTransport implements PushTransport {
  @override
  bool initialized = false;
  @override
  String get platform => 'android';
  final tokenEvents = StreamController<String>.broadcast(sync: true);
  final messageEvents = StreamController<void>.broadcast(sync: true);
  final openedEvents = StreamController<void>.broadcast(sync: true);
  final permissionStarted = Completer<void>();
  Completer<bool>? permissionDelay;
  bool permission = true, autoInit = false, failDelete = false;
  int initializations = 0, permissionRequests = 0, deletions = 0;
  @override
  Stream<String> get tokenChanges => tokenEvents.stream;
  @override
  Stream<void> get messages => messageEvents.stream;
  @override
  Stream<void> get opened => openedEvents.stream;
  @override
  Future<void> initialize() async {
    initialized = true;
    initializations++;
  }

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    if (!permissionStarted.isCompleted) permissionStarted.complete();
    return permissionDelay == null ? permission : permissionDelay!.future;
  }

  @override
  Future<void> setAutoInit(bool enabled) async {
    autoInit = enabled;
  }

  @override
  Future<String?> getToken() async => 'device-token';
  @override
  Future<void> deleteToken() async {
    deletions++;
    if (failDelete) {
      throw Exception('Private provider response must not be exposed');
    }
  }

  bool get hasListeners =>
      tokenEvents.hasListener ||
      messageEvents.hasListener ||
      openedEvents.hasListener;
}

Future<void> settlePushQueue() => Future<void>.delayed(Duration.zero);

void main() {
  test(
    'push is off until explicit enable and missing configuration never initializes provider',
    () async {
      final backend = TestPushBackend(), transport = TestPushTransport();
      final service = OptionalPushService(
        backend: backend,
        transport: transport,
        configurationEnabled: false,
      );
      expect(service.enabled, isFalse);
      expect(transport.initializations, 0);
      expect(await service.enable(), isFalse);
      expect(transport.permissionRequests, 0);
      expect(backend.calls, isEmpty);
      service.dispose();
      await settlePushQueue();
      expect(transport.initializations, 0);
    },
  );

  test(
    'enable binds consent and listeners to one account; disable removes token and listeners',
    () async {
      final backend = TestPushBackend(), transport = TestPushTransport();
      var received = 0;
      final service = OptionalPushService(
        backend: backend,
        transport: transport,
        onNotification: () async {
          received++;
        },
      );
      expect(transport.initializations, 0);
      expect(await service.enable(), isTrue);
      expect(service.enabled, isTrue);
      expect(backend.registered, {'device-token': 'account-a'});
      transport.messageEvents.add(null);
      await settlePushQueue();
      expect(received, 1);
      expect(await service.disable(), isTrue);
      expect(backend.registered, isEmpty);
      expect(transport.autoInit, isFalse);
      expect(transport.hasListeners, isFalse);
      transport.messageEvents.add(null);
      expect(received, 1);
      service.dispose();
      await settlePushQueue();
    },
  );

  test(
    'logout waits for delayed registration then revokes it before ending the authenticated session',
    () async {
      final backend = TestPushBackend()..registrationDelay = Completer<void>();
      final transport = TestPushTransport();
      final service = OptionalPushService(
        backend: backend,
        transport: transport,
      );
      final enabling = service.enable();
      await backend.registrationStarted.future;
      var loggedOut = false;
      final logout = () async {
        await service.disable();
        backend.switchUser(null);
        loggedOut = true;
      }();
      await settlePushQueue();
      expect(loggedOut, isFalse);
      expect(backend.userId, 'account-a');
      backend.registrationDelay!.complete();
      expect(await enabling, isFalse);
      await logout;
      expect(backend.registered, isEmpty);
      expect(backend.calls, [
        'register-start:account-a:device-token',
        'register-done:account-a:device-token',
        'unregister:account-a:device-token',
      ]);
      expect(service.enabled, isFalse);
      expect(transport.hasListeners, isFalse);
      service.dispose();
      await settlePushQueue();
    },
  );

  test(
    'account change during registration never assigns old consent to a new account',
    () async {
      final backend = TestPushBackend()..registrationDelay = Completer<void>();
      final transport = TestPushTransport();
      final service = OptionalPushService(
        backend: backend,
        transport: transport,
      );
      final enabling = service.enable();
      await backend.registrationStarted.future;
      backend.switchUser('account-b');
      backend.registrationDelay!.complete();
      expect(await enabling, isFalse);
      await service.disable();
      expect(service.enabled, isFalse);
      expect(transport.deletions, greaterThan(0));
      expect(transport.hasListeners, isFalse);
      expect(
        backend.calls.where(
          (call) => call.startsWith('register-start:account-b'),
        ),
        isEmpty,
      );
      service.dispose();
      await settlePushQueue();
    },
  );

  test(
    'dispose cancels delayed enable without orphan listeners or device registration',
    () async {
      final backend = TestPushBackend()..registrationDelay = Completer<void>();
      final transport = TestPushTransport();
      final service = OptionalPushService(
        backend: backend,
        transport: transport,
      );
      final enabling = service.enable();
      await backend.registrationStarted.future;
      service.dispose();
      backend.registrationDelay!.complete();
      expect(await enabling, isFalse);
      await settlePushQueue();
      expect(backend.registered, isEmpty);
      expect(transport.hasListeners, isFalse);
      expect(backend.accounts.hasListener, isFalse);
      expect(service.enabled, isFalse);
    },
  );

  test(
    'disable while OS consent is pending never registers or attaches listeners afterwards',
    () async {
      final backend = TestPushBackend();
      final transport = TestPushTransport()
        ..permissionDelay = Completer<bool>();
      final service = OptionalPushService(
        backend: backend,
        transport: transport,
      );
      final enabling = service.enable();
      await transport.permissionStarted.future;
      final disabling = service.disable();
      transport.permissionDelay!.complete(true);
      expect(await enabling, isFalse);
      expect(await disabling, isTrue);
      expect(backend.calls, isEmpty);
      expect(transport.hasListeners, isFalse);
      service.dispose();
      await settlePushQueue();
    },
  );

  test(
    'partial server failure rolls back registration and exposes no private provider messages',
    () async {
      final backend = TestPushBackend()..failRegistration = true;
      final transport = TestPushTransport();
      final service = OptionalPushService(
        backend: backend,
        transport: transport,
      );
      expect(await service.enable(), isFalse);
      expect(backend.registered, isEmpty);
      expect(transport.deletions, 1);
      expect(transport.hasListeners, isFalse);
      expect(service.error, isNot(contains('Private')));
      service.dispose();
      await settlePushQueue();
    },
  );

  test(
    'failed revocation is reported and retained token can be removed by retry',
    () async {
      final backend = TestPushBackend();
      final transport = TestPushTransport();
      final service = OptionalPushService(
        backend: backend,
        transport: transport,
      );
      expect(await service.enable(), isTrue);
      backend.failUnregister = true;
      transport.failDelete = true;
      expect(await service.disable(), isFalse);
      expect(service.error, contains('Retry'));
      expect(service.enabled, isFalse);
      expect(transport.hasListeners, isFalse);
      backend.failUnregister = false;
      transport.failDelete = false;
      expect(await service.disable(), isTrue);
      expect(backend.registered, isEmpty);
      service.dispose();
      await settlePushQueue();
    },
  );

  test(
    'token rotation removes obsolete device slot and does not request permission again',
    () async {
      final backend = TestPushBackend(), transport = TestPushTransport();
      final service = OptionalPushService(
        backend: backend,
        transport: transport,
      );
      expect(await service.enable(), isTrue);
      transport.tokenEvents.add('replacement-token');
      await settlePushQueue();
      expect(backend.registered, {'replacement-token': 'account-a'});
      expect(transport.permissionRequests, 1);
      await service.disable();
      service.dispose();
      await settlePushQueue();
    },
  );
}
