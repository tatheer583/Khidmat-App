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

  Stream<List<Map<String, dynamic>>> bookings() => client
      .from('bookings')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .limit(100);
  Stream<List<Map<String, dynamic>>> watchBooking(String id) =>
      client.from('bookings').stream(primaryKey: ['id']).eq('id', id);
  Stream<List<Map<String, dynamic>>> events(String id) => client
      .from('booking_events')
      .stream(primaryKey: ['id'])
      .eq('booking_id', id)
      .order('id');
  Stream<List<Map<String, dynamic>>> messages(String id) => client
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('booking_id', id)
      .order('created_at', ascending: false)
      .limit(200);

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
