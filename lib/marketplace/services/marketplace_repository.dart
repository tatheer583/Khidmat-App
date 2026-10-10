import 'dart:async';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Injectable boundary for authenticated API calls; tests never replace real
/// production login with a demo session or an arbitrary verification code.
abstract class MarketplaceRepository {
  String? get userId;
  String? get phone;
  Stream<void> get authChanges;
  Stream<void> get changes;
  Future<void> requestOtp(String phone);
  Future<void> verifyOtp(String phone, String token);
  Future<void> signOut();
  Future<List<Map<String, dynamic>>> fetchProfessions();
  Future<Map<String, dynamic>?> fetchProfile();
  Future<List<Map<String, dynamic>>> fetchJobs({
    int offset = 0,
    int limit = 20,
  });
  Future<List<Map<String, dynamic>>> fetchNotifications({
    int offset = 0,
    int limit = 30,
  });
  Future<dynamic> call(
    String function, {
    Map<String, dynamic> params = const {},
  });
  Future<String> uploadImage(
    Uint8List bytes,
    String extension,
    String mimeType,
  );
  void watchUser(String? userId);
  void dispose();
}

class SupabaseMarketplaceRepository implements MarketplaceRepository {
  SupabaseMarketplaceRepository(this.client);
  final SupabaseClient client;
  final _changes = StreamController<void>.broadcast();
  RealtimeChannel? _channel;
  bool _disposed = false;
  @override
  String? get userId => client.auth.currentUser?.id;
  @override
  String? get phone => client.auth.currentUser?.phone;
  @override
  Stream<void> get authChanges => client.auth.onAuthStateChange.map((_) {});
  @override
  Stream<void> get changes => _changes.stream;
  @override
  Future<void> requestOtp(String phone) =>
      client.auth.signInWithOtp(phone: phone);
  @override
  Future<void> verifyOtp(String phone, String token) async {
    final result = await client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
    if (result.session == null || result.user == null) {
      throw const AuthException('Verification did not return a valid session.');
    }
  }

  @override
  Future<void> signOut() => client.auth.signOut();

  static List<Map<String, dynamic>> _rows(dynamic data) => (data as List)
      .map((row) => Map<String, dynamic>.from(row as Map))
      .toList();
  @override
  Future<List<Map<String, dynamic>>> fetchProfessions() async => _rows(
    await client
        .from('professions')
        .select()
        .eq('active', true)
        .order('sort_order')
        .order('name'),
  );
  @override
  Future<Map<String, dynamic>?> fetchProfile() async {
    final uid = userId;
    if (uid == null) return null;
    return await client.from('profiles').select().eq('id', uid).maybeSingle();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchJobs({
    int offset = 0,
    int limit = 20,
  }) async {
    final uid = userId;
    if (uid == null) return [];
    return _rows(
      await client
          .from('jobs')
          .select()
          .or('customer_id.eq.$uid,worker_id.eq.$uid')
          .order('created_at', ascending: false)
          .order('id')
          .range(offset, offset + limit - 1),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> fetchNotifications({
    int offset = 0,
    int limit = 30,
  }) async {
    if (userId == null) return [];
    return _rows(
      await client
          .from('notifications')
          .select()
          .eq('user_id', userId!)
          .order('created_at', ascending: false)
          .order('id')
          .range(offset, offset + limit - 1),
    );
  }

  @override
  Future<dynamic> call(
    String function, {
    Map<String, dynamic> params = const {},
  }) => client.rpc(function, params: params);

  @override
  Future<String> uploadImage(
    Uint8List bytes,
    String extension,
    String mimeType,
  ) async {
    final uid = userId;
    if (uid == null) throw const AuthException('Sign in to add photos.');
    final path = '$uid/${const Uuid().v4()}.$extension';
    await client.storage
        .from('worker-media')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: false),
        );
    return client.storage.from('worker-media').getPublicUrl(path);
  }

  @override
  void watchUser(String? userId) {
    final previous = _channel;
    if (previous != null) unawaited(client.removeChannel(previous));
    _channel = null;
    if (userId == null || _disposed) return;
    void changed(PostgresChangePayload _) {
      if (!_disposed) _changes.add(null);
    }

    _channel = client
        .channel('khidmat-own-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'jobs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'customer_id',
            value: userId,
          ),
          callback: changed,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'jobs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'worker_id',
            value: userId,
          ),
          callback: changed,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: changed,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: changed,
        )
        .subscribe();
  }

  @override
  void dispose() {
    _disposed = true;
    if (_channel != null) unawaited(client.removeChannel(_channel!));
    unawaited(_changes.close());
  }
}
