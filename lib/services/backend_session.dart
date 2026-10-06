import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BackendSession extends ChangeNotifier {
  bool ready = false;
  String? error;
  String projectUrl = '';
  Map<String, dynamic>? profile;
  StreamSubscription<AuthState>? _auth;
  int _profileGeneration = 0;

  SupabaseClient get client => Supabase.instance.client;
  User? get user => ready ? client.auth.currentUser : null;
  bool get signedIn => user != null;
  bool get profileComplete => profile?['onboarding_completed'] == true;
  bool get isWorker => profile?['account_role'] == 'worker';
  String get displayName =>
      (profile?['full_name'] as String?)?.trim().isNotEmpty == true
      ? profile!['full_name'] as String
      : 'Khidmat member';

  static void validateConfig(String url, String key) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException('Enter a valid HTTPS Supabase project URL.');
    }
    if (key.startsWith('sb_secret_')) {
      throw const FormatException('Use a publishable key, never a secret key.');
    }
    if (!key.startsWith('sb_publishable_')) {
      try {
        final payload =
            jsonDecode(
                  utf8.decode(
                    base64Url.decode(base64Url.normalize(key.split('.')[1])),
                  ),
                )
                as Map<String, dynamic>;
        if (payload['role'] != 'anon') {
          throw const FormatException('Wrong key role');
        }
      } catch (_) {
        throw const FormatException(
          'Enter a Supabase publishable or legacy anon key.',
        );
      }
    }
  }

  Future<void> initialize() async {
    const url = String.fromEnvironment('SUPABASE_URL');
    const key = String.fromEnvironment('SUPABASE_ANON_KEY');
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = url.isNotEmpty
          ? url
          : prefs.getString('supabase_url') ?? '';
      final savedKey = key.isNotEmpty
          ? key
          : prefs.getString('supabase_key') ?? '';
      if (savedUrl.isNotEmpty && savedKey.isNotEmpty) {
        await configure(savedUrl, savedKey, persist: false);
      }
    } catch (e) {
      error = describeError(e);
    }
  }

  Future<void> configure(String url, String key, {bool persist = true}) async {
    validateConfig(url, key);
    if (ready) throw StateError('Restart the app to change its project.');
    await Supabase.initialize(url: url.trim(), publishableKey: key.trim());
    projectUrl = url.trim();
    ready = true;
    error = null;
    if (persist) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('supabase_url', projectUrl);
      await prefs.setString('supabase_key', key.trim());
    }
    _auth = client.auth.onAuthStateChange.listen(
      (event) {
        if (profile?['id'] != user?.id) profile = null;
        notifyListeners();
        unawaited(refreshProfile());
      },
      onError: (Object e) {
        error = describeError(e);
        notifyListeners();
      },
    );
    await refreshProfile();
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    final generation = ++_profileGeneration;
    final id = user?.id;
    if (id == null) {
      profile = null;
      notifyListeners();
      return;
    }
    try {
      final row = await client.from('profiles').select().eq('id', id).single();
      if (generation != _profileGeneration || user?.id != id) return;
      profile = row;
      error = null;
    } catch (e) {
      if (generation != _profileGeneration || user?.id != id) return;
      error = describeError(e);
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    await client.auth.signOut();
    profile = null;
    _profileGeneration++;
    notifyListeners();
  }

  @override
  void dispose() {
    _auth?.cancel();
    super.dispose();
  }
}

String describeError(Object error) {
  if (error is AuthException) return error.message;
  if (error is PostgrestException) {
    if (error.code == '23505') return 'This record already exists.';
    if (error.code == '42501') {
      return 'You do not have permission for this action.';
    }
    if (error.code == '42P01' || error.code == 'PGRST205') {
      return 'Finish the Supabase database setup before using this feature.';
    }
    return error.message;
  }
  if (error is StorageException) return error.message;
  if (error is FormatException) return error.message;
  if (error is StateError) return error.message.toString();
  return 'Could not complete the request. Check your connection and try again.';
}
