import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Stores refresh/access sessions in the operating system credential store.
/// The backend host namespaces sessions; existing offline preferences are kept.
class SecureAuthStorage extends LocalStorage {
  SecureAuthStorage({required String projectUrl, FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(
              resetOnError: false,
              migrateWithBackup: true,
            ),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
              synchronizable: false,
            ),
          ),
      _key = 'khidmat.marketplace.session.${Uri.parse(projectUrl).host}',
      _legacyKey =
          'sb-${Uri.parse(projectUrl).host.split('.').first}-auth-token';

  final FlutterSecureStorage _storage;
  final String _key;
  final String _legacyKey;

  @override
  Future<void> initialize() async {
    if (await _storage.read(key: _key) != null) return;
    if (await _storage.read(key: '$_key.migrated') == 'true') return;
    final preferences = await SharedPreferences.getInstance();
    final legacy = preferences.getString(_legacyKey);
    if (legacy == null) return;
    try {
      final session = jsonDecode(legacy);
      if (session is! Map ||
          session['access_token'] is! String ||
          (session['access_token'] as String).isEmpty ||
          session['refresh_token'] is! String ||
          (session['refresh_token'] as String).isEmpty) {
        return;
      }
    } on FormatException {
      return;
    }
    await _storage.write(key: _key, value: legacy);
    if (await _storage.read(key: _key) != legacy) {
      throw StateError('The existing session could not be saved securely.');
    }
    await _storage.write(key: '$_key.migrated', value: 'true');
    // Retain the original and all connection preferences for recoverability.
  }

  @override
  Future<String?> accessToken() => _storage.read(key: _key);
  @override
  Future<bool> hasAccessToken() async => (await accessToken()) != null;
  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _key, value: persistSessionString);
  @override
  Future<void> removePersistedSession() async {
    await _storage.write(key: '$_key.migrated', value: 'true');
    await _storage.delete(key: _key);
  }
}
