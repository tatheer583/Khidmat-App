import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:khidmat/marketplace/services/secure_auth_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'secure storage failure is surfaced without clearing legacy or secure records',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'preserved': 'encrypted-record',
      });
      SharedPreferences.setMockInitialValues({
        'sb-project-auth-token': 'retained-legacy',
        'app_language': 'ur',
      });
      final storage = SecureAuthStorage(
        projectUrl: 'https://project.supabase.co',
        storage: _UnavailableStorage(),
      );
      await expectLater(
        storage.initialize(),
        throwsA(isA<PlatformException>()),
      );
      expect(
        await const FlutterSecureStorage().read(key: 'preserved'),
        'encrypted-record',
      );
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('sb-project-auth-token'), 'retained-legacy');
      expect(preferences.getString('app_language'), 'ur');
    },
  );

  test(
    'legacy session copies only its backend namespace and preserves original settings',
    () async {
      final session = jsonEncode({
        'access_token': 'old-access',
        'refresh_token': 'old-refresh',
      });
      SharedPreferences.setMockInitialValues({
        'sb-project-auth-token': session,
        'sb-other-auth-token':
            '{"access_token":"different","refresh_token":"different"}',
        'supabase_url': 'https://project.supabase.co',
        'app_language': 'ur',
      });
      final storage = SecureAuthStorage(
        projectUrl: 'https://project.supabase.co',
      );
      await storage.initialize();
      expect(await storage.accessToken(), session);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('sb-project-auth-token'), session);
      expect(
        preferences.getString('supabase_url'),
        'https://project.supabase.co',
      );
      expect(preferences.getString('app_language'), 'ur');
      await storage.removePersistedSession();
      await SecureAuthStorage(
        projectUrl: 'https://project.supabase.co',
      ).initialize();
      expect(
        await storage.accessToken(),
        isNull,
        reason: 'Logout must not resurrect the retained legacy session.',
      );
      expect(
        await SecureAuthStorage(
          projectUrl: 'https://other.supabase.co',
        ).accessToken(),
        isNull,
      );
    },
  );

  test(
    'malformed legacy sessions cannot overwrite encrypted sessions',
    () async {
      SharedPreferences.setMockInitialValues({
        'sb-project-auth-token': '{"access_token":false}',
      });
      final storage = SecureAuthStorage(
        projectUrl: 'https://project.supabase.co',
      );
      await storage.initialize();
      expect(await storage.hasAccessToken(), isFalse);
      await storage.persistSession('secure-session');
      await storage.initialize();
      expect(await storage.accessToken(), 'secure-session');
    },
  );
}

class _UnavailableStorage extends FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
  }) async {
    throw PlatformException(
      code: 'key_unavailable',
      message: 'The OS key is temporarily unavailable.',
    );
  }
}
