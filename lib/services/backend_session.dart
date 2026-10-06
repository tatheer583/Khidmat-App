import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'deadline_client.dart';

const authRedirectUrl = 'com.khidmat.khidmat://login-callback/';
const serviceSetupMessage =
    'Khidmat services are not ready yet. The app owner needs to finish service setup. Please try again later.';

class BackendSession extends ChangeNotifier {
  bool ready = false;
  bool initializing = false;
  bool checkingServices = false;
  bool serviceAvailable = true;
  bool profileLoading = false;
  bool recoveringPassword = false;
  bool? phoneEnabled;
  bool? emailEnabled;
  String? error;
  String? serviceError;
  String projectUrl = '';
  String _publicKey = '';
  Map<String, dynamic>? profile;
  StreamSubscription<AuthState>? _auth;
  final _http = DeadlineClient();
  int _profileGeneration = 0;
  bool _disposed = false;

  SupabaseClient get client => Supabase.instance.client;
  User? get user => ready ? client.auth.currentUser : null;
  bool get signedIn => user != null;
  bool get profileComplete => profile?['onboarding_completed'] == true;
  bool get isWorker => profile?['account_role'] == 'worker';
  String get displayName =>
      (profile?['full_name'] as String?)?.trim().isNotEmpty == true
      ? profile!['full_name'] as String
      : 'Khidmat member';

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  static void validateConfig(String url, String key) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw const FormatException('Enter a valid HTTPS Supabase project URL.');
    }
    if (key.startsWith('sb_secret_')) {
      throw const FormatException('Use a publishable key, never a secret key.');
    }
    if (key.startsWith('sb_publishable_') && key.length > 20) return;
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

  Future<void> initialize() async {
    initializing = true;
    _changed();
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
    } finally {
      initializing = false;
      _changed();
    }
  }

  Future<void> configure(String url, String key, {bool persist = true}) async {
    validateConfig(url.trim(), key.trim());
    if (ready) throw StateError('Restart the app to change its project.');
    projectUrl = url.trim().replaceFirst(RegExp(r'/$'), '');
    _publicKey = key.trim();
    await Supabase.initialize(
      url: projectUrl,
      publishableKey: _publicKey,
      httpClient: _http,
    );
    ready = true;
    serviceAvailable = false;
    error = null;
    _auth = client.auth.onAuthStateChange.listen(
      (event) {
        if (profile?['id'] != user?.id) profile = null;
        if (event.event == AuthChangeEvent.passwordRecovery) {
          recoveringPassword = true;
        }
        if (event.event == AuthChangeEvent.signedOut) {
          recoveringPassword = false;
        }
        if (serviceAvailable) {
          unawaited(refreshProfile());
        } else {
          _changed();
        }
      },
      onError: (Object e) {
        error = describeError(e);
        _changed();
      },
    );
    if (persist) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('supabase_url', projectUrl);
      await prefs.setString('supabase_key', _publicKey);
    }
    await checkServices();
  }

  /// A public, data-free health RPC verifies database, storage and publication.
  /// Use the public key so an expired user token cannot masquerade as an outage.
  Future<void> checkServices() async {
    if (!ready || checkingServices) return;
    checkingServices = true;
    serviceError = null;
    _changed();
    try {
      final responses = await Future.wait([
        _http.post(
          Uri.parse('$projectUrl/rest/v1/rpc/app_health'),
          headers: {'apikey': _publicKey, 'Content-Type': 'application/json'},
          body: '{}',
        ),
        _http.get(
          Uri.parse('$projectUrl/auth/v1/settings'),
          headers: {'apikey': _publicKey},
        ),
      ]);
      final health = responses[0];
      if (health.statusCode == 404) throw StateError(serviceSetupMessage);
      if (health.statusCode != 200) {
        throw StateError(
          'Could not connect to Khidmat. Check your connection and try again.',
        );
      }
      final status = jsonDecode(health.body) as Map<String, dynamic>;
      if (status['ready'] != true) throw StateError(serviceSetupMessage);
      final auth = responses[1];
      if (auth.statusCode != 200) {
        throw StateError(
          'Sign in is temporarily unavailable. Please try again.',
        );
      }
      final settings = jsonDecode(auth.body) as Map<String, dynamic>;
      final external = settings['external'] as Map<String, dynamic>? ?? {};
      phoneEnabled = external['phone'] == true;
      emailEnabled = external['email'] == true;
      serviceAvailable = true;
    } catch (e) {
      serviceAvailable = false;
      serviceError = describeError(e);
    } finally {
      checkingServices = false;
      _changed();
    }
    if (serviceAvailable && signedIn) await refreshProfile();
  }

  Future<void> refreshProfile() async {
    final generation = ++_profileGeneration;
    final id = user?.id;
    if (id == null) {
      profile = null;
      profileLoading = false;
      error = null;
      _changed();
      return;
    }
    profileLoading = true;
    error = null;
    _changed();
    try {
      final row = await client
          .from('profiles')
          .select()
          .eq('id', id)
          .single()
          .timeout(const Duration(seconds: 20));
      if (generation != _profileGeneration || user?.id != id || _disposed) {
        return;
      }
      profile = row;
    } catch (e) {
      if (generation != _profileGeneration || user?.id != id || _disposed) {
        return;
      }
      error = describeError(e);
    } finally {
      if (generation == _profileGeneration) {
        profileLoading = false;
        _changed();
      }
    }
  }

  // Use the committed RPC response; a failed second GET must not undo a save.
  void acceptProfile(Map<String, dynamic> row) {
    if (row['id'] != user?.id) return;
    _profileGeneration++;
    profile = row;
    profileLoading = false;
    error = null;
    _changed();
  }

  void passwordUpdated() {
    recoveringPassword = false;
    _changed();
  }

  Future<void> signOut() async {
    await client.auth.signOut(scope: SignOutScope.local);
    profile = null;
    profileLoading = false;
    recoveringPassword = false;
    error = null;
    _profileGeneration++;
    _changed();
  }

  @override
  void dispose() {
    _disposed = true;
    _profileGeneration++;
    _auth?.cancel();
    super.dispose();
  }
}

String describeError(Object error) {
  if (error is TimeoutException) {
    return 'The connection took too long. Please try again.';
  }
  if (error is AuthException) {
    if (error.code == 'phone_provider_disabled' ||
        error.message.toLowerCase().contains('phone logins are disabled')) {
      return 'Phone sign in is not available yet. Please use email.';
    }
    return error.message;
  }
  if (error is PostgrestException) {
    if (error.code == '23505') return 'This record already exists.';
    if (error.code == '42501') {
      return 'You do not have permission for this action.';
    }
    if (['42P01', 'PGRST202', 'PGRST205'].contains(error.code)) {
      return serviceSetupMessage;
    }
    if (error.code == 'PGRST116') return 'Your profile could not be loaded.';
    if (error.code == 'P0001') return error.message;
    return 'Could not save or load this information. Please try again.';
  }
  if (error is StorageException) {
    return 'Could not upload or load the photo. Please try again.';
  }
  if (error is FormatException) return error.message;
  if (error is StateError) return error.message.toString();
  return 'Could not complete the request. Check your connection and try again.';
}
