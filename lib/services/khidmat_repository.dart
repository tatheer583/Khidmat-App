import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/provider_model.dart';
import '../models/live_booking.dart';

class KhidmatRepository {
  final SupabaseClient client;
  KhidmatRepository(this.client);
  String get userId => client.auth.currentUser!.id;

  Future<List<ServiceProvider>> findProviders(
    String category,
    String city,
  ) async {
    var query = client
        .from('providers')
        .select()
        .eq('is_approved', true)
        .eq('is_available', true)
        .ilike(
          'city',
          city
              .trim()
              .replaceAll(r'\', r'\\')
              .replaceAll('%', r'\%')
              .replaceAll('_', r'\_'),
        );
    if (category != 'General Service') query = query.eq('category', category);
    final rows = await query.order('rating', ascending: false).limit(100);
    return rows
        .map(ServiceProvider.fromJson)
        .where((p) => p.availableSlots.isNotEmpty && p.ownerId != userId)
        .toList();
  }

  Future<Map<String, dynamic>> getQuote(String providerId) async =>
      Map<String, dynamic>.from(
        await client.rpc(
              'quote_provider',
              params: {'p_provider_id': providerId},
            )
            as Map,
      );

  Future<LiveBooking> createBooking(
    String quoteId,
    DateTime day,
    String slot,
    String address,
    String notes,
  ) async {
    final date = day.toIso8601String().split('T').first;
    final row = await client.rpc(
      'create_booking',
      params: {
        'p_quote_id': quoteId,
        'p_date': date,
        'p_slot': slot,
        'p_location': address.trim(),
        'p_notes': notes.trim(),
      },
    );
    return LiveBooking(Map<String, dynamic>.from(row as Map));
  }

  Future<List<String>> availableSlots(String providerId, DateTime day) async =>
      List<String>.from(
        await client.rpc(
              'available_slots',
              params: {
                'p_provider_id': providerId,
                'p_date': day.toIso8601String().split('T').first,
              },
            )
            as List,
      );

  Stream<List<Map<String, dynamic>>> bookings() => _watchRows(
    'bookings',
    () => client
        .from('bookings')
        .select()
        .order('created_at', ascending: false)
        .limit(100),
  );
  Stream<List<Map<String, dynamic>>> watchBooking(String id) => _watchRows(
    'bookings',
    () => client.from('bookings').select().eq('id', id),
    column: 'id',
    value: id,
  );
  Stream<List<Map<String, dynamic>>> events(String id) => _watchRows(
    'booking_events',
    () =>
        client.from('booking_events').select().eq('booking_id', id).order('id'),
    column: 'booking_id',
    value: id,
  );
  Stream<List<Map<String, dynamic>>> messages(String id) => _watchRows(
    'messages',
    () => client
        .from('messages')
        .select()
        .eq('booking_id', id)
        .order('created_at', ascending: false)
        .limit(200),
    column: 'booking_id',
    value: id,
  );

  /// A channel join can precede its PostgreSQL subscription. Re-read when the
  /// server confirms that subscription, closing the initial snapshot gap.
  /// Also resync on reconnect. Serialized reads prevent stale responses from
  /// overwriting newer changes; all snapshots still pass through database RLS.
  Stream<List<Map<String, dynamic>>> _watchRows(
    String table,
    Future<List<Map<String, dynamic>>> Function() read, {
    String? column,
    String? value,
  }) {
    late StreamController<List<Map<String, dynamic>>> controller;
    RealtimeChannel? channel;
    bool cancelled = false;
    bool reading = false;
    bool dirty = false;
    Object? realtimeError;
    Future<void> refresh() async {
      dirty = true;
      if (reading || cancelled) return;
      reading = true;
      try {
        while (dirty && !cancelled) {
          dirty = false;
          try {
            final rows = await read().timeout(const Duration(seconds: 20));
            if (!cancelled) {
              controller.add(rows);
              if (realtimeError != null) controller.addError(realtimeError!);
            }
          } catch (error, stack) {
            if (!cancelled) controller.addError(error, stack);
          }
        }
      } finally {
        reading = false;
      }
    }

    controller = StreamController(
      onListen: () {
        channel = client
            .channel('khidmat-$table-${const Uuid().v4()}')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: table,
              filter: column == null
                  ? null
                  : PostgresChangeFilter(
                      type: PostgresChangeFilterType.eq,
                      column: column,
                      value: value!,
                    ),
              callback: (_) => unawaited(refresh()),
            )
            .onSystemEvents((payload) {
              if (payload['extension'] == 'postgres_changes' &&
                  payload['status'] == 'ok') {
                realtimeError = null;
                unawaited(refresh());
              }
            })
            .subscribe((status, [error]) {
              if (status == RealtimeSubscribeStatus.subscribed) {
                realtimeError = null;
                unawaited(refresh());
              } else if (!cancelled &&
                  (status == RealtimeSubscribeStatus.channelError ||
                      status == RealtimeSubscribeStatus.timedOut ||
                      status == RealtimeSubscribeStatus.closed)) {
                realtimeError = StateError(
                  'Live updates disconnected. Please try again.',
                );
                controller.addError(realtimeError!);
              }
            });
        unawaited(refresh());
      },
      onCancel: () async {
        cancelled = true;
        if (channel != null) await client.removeChannel(channel!);
      },
    );
    return controller.stream;
  }

  Future<void> transition(String id, String status) async {
    await client.rpc(
      'transition_booking',
      params: {'p_booking_id': id, 'p_status': status},
    );
  }

  Future<Map<String, dynamic>?> ownProvider() async => await client
      .from('providers')
      .select()
      .eq('user_id', userId)
      .maybeSingle();

  Future<void> saveProvider(
    Map<String, dynamic> data, {
    bool exists = false,
  }) async {
    if (exists) {
      await client.from('providers').update(data).eq('user_id', userId);
    } else {
      await client.from('providers').insert({...data, 'user_id': userId});
    }
  }

  Future<String> uploadImage(XFile image, {String? bookingId}) async {
    final bytes = await image.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      throw const FormatException('Choose an image smaller than 5 MB.');
    }
    // Identify the actual bytes rather than trusting a filename's extension.
    final png =
        bytes.length >= 8 &&
        bytes[0] == 137 &&
        bytes[1] == 80 &&
        bytes[2] == 78 &&
        bytes[3] == 71;
    final jpeg =
        bytes.length >= 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255;
    final webp =
        bytes.length >= 12 &&
        bytes[0] == 82 &&
        bytes[1] == 73 &&
        bytes[2] == 70 &&
        bytes[3] == 70 &&
        bytes[8] == 87 &&
        bytes[9] == 69 &&
        bytes[10] == 66 &&
        bytes[11] == 80;
    if (!png && !jpeg && !webp) {
      throw const FormatException('Choose a JPEG, PNG or WebP image.');
    }
    final ext = png
        ? 'png'
        : jpeg
        ? 'jpg'
        : 'webp';
    final mime = png
        ? 'image/png'
        : jpeg
        ? 'image/jpeg'
        : 'image/webp';
    final fileId = const Uuid().v4();
    final prefix = bookingId == null ? userId : '$bookingId/$userId';
    final path = '$prefix/$fileId.$ext';
    await client.storage
        .from(bookingId == null ? 'avatars' : 'booking-media')
        .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mime));
    return path;
  }

  Future<void> sendMessage(
    String bookingId,
    String body, {
    XFile? image,
  }) async {
    String? path;
    try {
      if (image != null) path = await uploadImage(image, bookingId: bookingId);
      if (body.trim().isEmpty && path == null) return;
      await client.from('messages').insert({
        'booking_id': bookingId,
        'sender_id': userId,
        'body': body.trim(),
        'attachment_path': path,
      });
    } catch (error) {
      // A lost response may follow a committed insert. Delete only after a
      // definite database rejection, never after an ambiguous network failure.
      if (path != null && error is PostgrestException) {
        try {
          await client.storage.from('booking-media').remove([path]);
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<String> signedImage(String bucket, String path) =>
      client.storage.from(bucket).createSignedUrl(path, 3600);

  Future<void> review(LiveBooking booking, int stars, String comment) async {
    await client.from('reviews').insert({
      'booking_id': booking.id,
      'customer_id': userId,
      'provider_id': booking.providerId,
      'stars': stars,
      'comment': comment.trim(),
    });
  }
}
