import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:khidmat/services/khidmat_repository.dart';

// Runs only when explicitly requested against the disposable CI stack.
void main() {
  test(
    'the app repository resyncs its initial gap and receives live jobs, chat and photos',
    () => HttpOverrides.runWithHttpOverrides(() async {
      final file = Platform.environment['KHIDMAT_TEST_CONFIG'];
      if (file == null) {
        throw StateError(
          'KHIDMAT_TEST_CONFIG must name the local test configuration',
        );
      }
      final config =
          jsonDecode(await File(file).readAsString()) as Map<String, dynamic>;
      final url = config['API_URL'] as String;
      expect(['localhost', '127.0.0.1'], contains(Uri.parse(url).host));
      final clients = <SupabaseClient>[];
      final subscriptions = <StreamSubscription<List<Map<String, dynamic>>>>[];
      SupabaseClient makeClient(String key) {
        final client = SupabaseClient(
          url,
          key,
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        );
        clients.add(client);
        return client;
      }

      try {
        final admin = makeClient(config['SERVICE_ROLE_KEY'] as String);
        Future<SupabaseClient> account(String role) async {
          final email = '$role-${const Uuid().v4()}@example.test';
          const password = 'Local-Only-Password-847!';
          await admin.auth.admin.createUser(
            AdminUserAttributes(
              email: email,
              password: password,
              emailConfirm: true,
            ),
          );
          final client = makeClient(config['ANON_KEY'] as String);
          await client.auth.signInWithPassword(
            email: email,
            password: password,
          );
          return client;
        }

        final customer = await account('dart-customer');
        final worker = await account('dart-worker');
        final outsider = await account('dart-outsider');
        final listing = await admin
            .from('providers')
            .insert({
              'user_id': worker.auth.currentUser!.id,
              'name': 'Dart Test Worker',
              'category': 'Plumber',
              'city': 'Islamabad',
              'location': 'G-13',
              'price_min': 1200,
              'price_max': 1500,
              'is_approved': true,
              'available_slots': ['09:00', '12:00'],
            })
            .select()
            .single();
        final customerRepo = KhidmatRepository(customer);
        final workerRepo = KhidmatRepository(worker);
        final initial = Completer<void>();
        final incoming = Completer<Map<String, dynamic>>();
        String? bookingId;
        List<Map<String, dynamic>> latestJobs = [];
        void matchIncoming() {
          if (bookingId != null &&
              latestJobs.any((row) => row['id'] == bookingId) &&
              !incoming.isCompleted) {
            incoming.complete(
              latestJobs.firstWhere((row) => row['id'] == bookingId),
            );
          }
        }

        subscriptions.add(
          workerRepo.bookings().listen(
            (rows) {
              if (!initial.isCompleted) initial.complete();
              latestJobs = rows;
              matchIncoming();
            },
            onError: (Object e) {
              if (!initial.isCompleted) initial.completeError(e);
              if (!incoming.isCompleted) incoming.completeError(e);
            },
          ),
        );
        // Insert immediately after initial HTTP snapshot, deliberately before the
        // server may have finished establishing its Postgres subscription.
        await initial.future.timeout(const Duration(seconds: 20));
        final quote = await customerRepo.getQuote(listing['id'] as String);
        final day = DateTime.now().toUtc().add(const Duration(hours: 29));
        final booking = await customerRepo.createBooking(
          quote['id'] as String,
          day,
          '09:00',
          'House 12, G-13, Islamabad',
          'Leaking pipe',
        );
        bookingId = booking.id;
        matchIncoming();
        expect(
          (await incoming.future.timeout(
            const Duration(seconds: 30),
          ))['status'],
          'pending',
        );

        final received = Completer<Map<String, dynamic>>();
        subscriptions.add(
          workerRepo
              .messages(booking.id)
              .listen(
                (rows) {
                  if (rows.any((row) => row['body'] == 'Pipe photo') &&
                      !received.isCompleted) {
                    received.complete(
                      rows.firstWhere((row) => row['body'] == 'Pipe photo'),
                    );
                  }
                },
                onError: (Object e) {
                  if (!received.isCompleted) received.completeError(e);
                },
              ),
        );
        final bytes = base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aTr8AAAAASUVORK5CYII=',
        );
        await customerRepo.sendMessage(
          booking.id,
          'Pipe photo',
          image: XFile.fromData(
            bytes,
            name: 'photo.png',
            mimeType: 'image/png',
          ),
        );
        final message = await received.future.timeout(
          const Duration(seconds: 30),
        );
        final path = message['attachment_path'] as String;
        expect(
          await worker.storage.from('booking-media').download(path),
          bytes,
        );
        await expectLater(
          outsider.storage.from('booking-media').download(path),
          throwsA(isA<StorageException>()),
        );

        final accepted = Completer<void>();
        subscriptions.add(
          customerRepo
              .watchBooking(booking.id)
              .listen(
                (rows) {
                  if (rows.any((row) => row['status'] == 'accepted') &&
                      !accepted.isCompleted) {
                    accepted.complete();
                  }
                },
                onError: (Object e) {
                  if (!accepted.isCompleted) accepted.completeError(e);
                },
              ),
        );
        await workerRepo.transition(booking.id, 'accepted');
        await accepted.future.timeout(const Duration(seconds: 30));
        expect(
          await customerRepo.availableSlots(listing['id'] as String, day),
          ['12:00'],
        );
      } finally {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
        for (final client in clients) {
          await client.dispose();
        }
      }
    }, _RealNetworking()),
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

class _RealNetworking extends HttpOverrides {}
