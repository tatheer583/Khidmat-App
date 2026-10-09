import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:khidmat/marketplace/services/marketplace_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'Supabase adapter sends OTP to real auth endpoint and provider rejection leaves no session',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final received = <Map<String, dynamic>>[];
      server.listen((request) async {
        received.add({
          'path': request.uri.path,
          'body': jsonDecode(await utf8.decoder.bind(request).join()),
        });
        request.response.headers.contentType = ContentType.json;
        request.response.statusCode = 400;
        request.response.write(
          jsonEncode({
            'code': 'sms_send_failed',
            'msg': 'SMS provider is not configured',
          }),
        );
        await request.response.close();
      });
      final client = SupabaseClient(
        'http://127.0.0.1:${server.port}',
        'public-test-key',
      );
      final repository = SupabaseMarketplaceRepository(client);
      addTearDown(() async {
        repository.dispose();
        await client.dispose();
        await server.close(force: true);
      });
      await expectLater(
        repository.requestOtp('+923001234567'),
        throwsA(isA<AuthException>()),
      );
      expect(received.single['path'], '/auth/v1/otp');
      expect((received.single['body'] as Map)['phone'], '+923001234567');
      expect(repository.userId, isNull);
    },
  );

  test(
    'Supabase adapter requests active catalog and server geographic RPC without downloading worker table',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final paths = <String>[];
      Map<String, dynamic>? payload;
      Map<String, String>? query;
      server.listen((request) async {
        paths.add(request.uri.path);
        request.response.headers.contentType = ContentType.json;
        if (request.method == 'GET') {
          query = request.uri.queryParameters;
          request.response.write(
            '[{"id":"profession","name":"Electrician","category":"Electrical Services","skills":[],"questions":[]}]',
          );
        } else {
          payload =
              jsonDecode(await utf8.decoder.bind(request).join())
                  as Map<String, dynamic>;
          request.response.write(
            '[{"id":"worker","name":"Aslam","distance_km":null}]',
          );
        }
        await request.response.close();
      });
      final client = SupabaseClient(
        'http://127.0.0.1:${server.port}',
        'public-test-key',
      );
      final repository = SupabaseMarketplaceRepository(client);
      addTearDown(() async {
        repository.dispose();
        await client.dispose();
        await server.close(force: true);
      });
      expect(
        (await repository.fetchProfessions()).single['name'],
        'Electrician',
      );
      expect(query!['active'], 'eq.true');
      final workers = await repository.call(
        'search_workers',
        params: {
          'p_city': 'Lahore',
          'p_latitude': null,
          'p_longitude': null,
          'p_limit': 20,
          'p_offset': 40,
        },
      );
      expect((workers as List).single['id'], 'worker');
      expect(payload!['p_offset'], 40);
      expect(payload!['p_latitude'], isNull);
      expect(paths, ['/rest/v1/professions', '/rest/v1/rpc/search_workers']);
    },
  );
}
