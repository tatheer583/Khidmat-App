import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khidmat/marketplace/data/bundled_profession_catalog.dart';
import 'package:khidmat/marketplace/services/marketplace_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

  test(
    'Urdu service queries send canonical labels over HTTP while names and ambiguous aliases remain unchanged',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var catalog = bundledProfessionRows();
      final requests = <Map<String, dynamic>>[];
      server.listen((request) async {
        request.response.headers.contentType = ContentType.json;
        if (request.uri.path == '/rest/v1/professions') {
          request.response.write(jsonEncode(catalog));
        } else {
          expect(request.uri.path, '/rest/v1/rpc/search_workers');
          requests.add(
            Map<String, dynamic>.from(
              jsonDecode(await utf8.decoder.bind(request).join()) as Map,
            ),
          );
          request.response.write('[]');
        }
        await request.response.close();
      });
      final client = SupabaseClient(
        'http://127.0.0.1:${server.port}',
        'public-test-key',
      );
      final controller = MarketplaceController(client: client);
      addTearDown(() async {
        controller.dispose();
        await client.dispose();
        await server.close(force: true);
      });
      expect(await controller.initialize(), isTrue);
      await controller.setManualLocation('Lahore', 'Model Town');
      final electrician = controller.professions
          .where((profession) => profession.name == 'Electrician')
          .single;
      const typedQuery = ' وائرنگ   کی مرمت ';
      expect(
        await controller.searchWorkers(
          filters: WorkerSearch(
            query: typedQuery,
            professionId: electrician.id,
            skillId: 'Wiring Repair',
          ),
        ),
        isTrue,
      );
      expect(requests.last['p_query'], 'Wiring Repair');
      expect(requests.last['p_profession_id'], electrician.id);
      expect(requests.last['p_skill'], 'Wiring Repair');
      expect(requests.last['p_city'], 'Lahore');
      expect(requests.last['p_latitude'], isNull);
      expect(requests.last['p_longitude'], isNull);
      expect(controller.search.query, typedQuery);
      for (final entry in {
        'بجلی کی خدمات': 'Electrical Services',
        'الیکٹریشن': 'Electrician',
        'اسلم مستری': 'اسلم مستری',
        'لاہور': 'لاہور',
        'Aslam Electrician': 'Aslam Electrician',
      }.entries) {
        expect(
          await controller.searchWorkers(
            filters: WorkerSearch(query: entry.key),
          ),
          isTrue,
        );
        expect(requests.last['p_query'], entry.value);
        expect(controller.search.query, entry.key);
        expect(requests.last['p_profession_id'], isNull);
        expect(requests.last['p_skill'], isNull);
      }
      catalog = [
        for (final row in catalog.take(2)) {...row, 'name_ur': 'مشترک خدمت'},
      ];
      await controller.reloadCatalog();
      expect(
        await controller.searchWorkers(
          filters: const WorkerSearch(query: 'مشترک خدمت'),
        ),
        isTrue,
      );
      expect(requests.last['p_query'], 'مشترک خدمت');
      expect(requests.last['p_profession_id'], isNull);
      expect(requests.last['p_skill'], isNull);
      expect(controller.workers, isEmpty);
    },
  );
}
