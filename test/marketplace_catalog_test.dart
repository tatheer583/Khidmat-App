import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:khidmat/marketplace/data/bundled_profession_catalog.dart';
import 'package:khidmat/marketplace/services/marketplace_controller.dart';
import 'marketplace_controller_test.dart' show FakeMarketplaceRepository;

class CatalogRepository extends FakeMarketplaceRepository {
  List<Map<String, dynamic>> catalogRows = [
    {
      'id': '20000000-0000-4000-8000-000000000001',
      'name': 'Operator configured service',
      'category': 'Operator category',
      'name_ur': 'مقامی خدمت',
      'skills': ['Operator skill'],
      'questions': [],
    },
  ];
  Object? catalogFailure;
  Completer<List<Map<String, dynamic>>>? pendingCatalog;
  int catalogRequests = 0;
  @override
  Future<List<Map<String, dynamic>>> fetchProfessions() async {
    catalogRequests++;
    if (pendingCatalog != null) return pendingCatalog!.future;
    if (catalogFailure != null) throw catalogFailure!;
    return catalogRows;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'bundled catalogue exactly matches all canonical seeded definitions',
    () async {
      final sql = await File(
        'supabase/migrations/202610090002_catalog.sql',
      ).readAsString();
      final records =
          RegExp(
                r"\('([^']+)','((?:[^']|'')*)','((?:[^']|'')*)','((?:[^']|'')*)','((?:[^']|'')*)',\s*'((?:[^']|'')*)',(\d+)\)",
                dotAll: true,
              )
              .allMatches(sql)
              .map(
                (match) => {
                  'id': match[1],
                  'category': match[2]!.replaceAll("''", "'"),
                  'name': match[3]!.replaceAll("''", "'"),
                  'name_ur': match[4]!.replaceAll("''", "'"),
                  'skills': jsonDecode(match[5]!.replaceAll("''", "'")),
                  'questions': jsonDecode(match[6]!.replaceAll("''", "'")),
                  'sort_order': int.parse(match[7]!),
                },
              )
              .toList();
      expect(records.length, 18);
      expect(bundledProfessionRows(), records);
      final professions = loadBundledProfessionCatalog();
      expect(professions.map((p) => p.id).toSet().length, 18);
      expect(professions.map((p) => p.category).toSet().length, 9);
      for (final profession in professions) {
        expect(profession.skills, isNotEmpty);
        expect(profession.nameUr, isNotEmpty);
        expect(
          profession.questions.map((q) => q.id).toSet().length,
          profession.questions.length,
        );
      }
    },
  );

  test(
    'all services exist synchronously without backend configuration, authentication or GPS',
    () async {
      final controller = MarketplaceController();
      addTearDown(controller.dispose);
      expect(
        controller.professions.length,
        18,
        reason: 'First frame must have actual service definitions.',
      );
      expect(controller.catalogSource, CatalogSource.bundled);
      expect(controller.catalogLoading, isFalse);
      expect(await controller.initialize(), isTrue);
      expect(controller.professionCategories.length, 9);
      expect(controller.workers, isEmpty);
      expect(controller.jobs, isEmpty);
      expect(controller.notifications, isEmpty);
      expect(controller.isAuthenticated, isFalse);
      expect(controller.locationPermission, LocationAccess.unknown);
    },
  );

  test(
    'bundled category, profession, skill and bilingual searches remain navigable',
    () {
      final controller = MarketplaceController();
      addTearDown(controller.dispose);
      expect(
        controller
            .filterProfessions(category: 'Construction')
            .map((p) => p.name),
        ['Mazdoor', 'Mason', 'Welder', 'Tile Installer'],
      );
      final electrician = controller
          .filterProfessions(query: 'الیکٹریشن')
          .single;
      expect(electrician.name, 'Electrician');
      expect(
        controller.filterProfessions(query: 'وائرنگ کی مرمت').single.id,
        electrician.id,
      );
      expect(
        controller.filterProfessions(query: 'بجلی کی خدمات').map((p) => p.name),
        ['Electrician', 'Solar Technician'],
      );
      expect(
        controller
            .filterProfessions(
              professionId: electrician.id,
              skillId: 'Wiring Repair',
            )
            .single
            .id,
        electrician.id,
      );
      expect(
        controller.filterProfessions(query: 'interior painting').single.name,
        'Painter',
      );
      expect(
        controller.filterProfessions(query: 'AC repair').single.name,
        'AC Technician',
      );
      expect(controller.filterProfessions(query: ' elec ').map((p) => p.name), [
        'Electrician',
        'Solar Technician',
      ]);
      expect(controller.filterProfessions(query: 'AC').map((p) => p.name), [
        'AC Technician',
      ]);
      expect(
        controller.filterProfessions(
          category: 'Construction',
          skillId: 'Wiring Repair',
        ),
        isEmpty,
      );
      expect(
        controller.filterProfessions(query: 'unlisted service query'),
        isEmpty,
      );
    },
  );

  test(
    'offline worker search retains service filters without fabricating online activity or clearing account errors',
    () async {
      final controller = MarketplaceController();
      addTearDown(controller.dispose);
      final electrician = controller
          .filterProfessions(query: 'Electrician')
          .single;
      controller.error = 'An independent account error';
      expect(
        await controller.searchWorkers(
          filters: WorkerSearch(
            query: 'wiring',
            professionId: electrician.id,
            skillId: 'Wiring Repair',
          ),
        ),
        isFalse,
      );
      expect(controller.search.professionId, electrician.id);
      expect(controller.search.skillId, 'Wiring Repair');
      expect(controller.search.query, 'wiring');
      expect(controller.workerSearchError, contains('online connection'));
      expect(controller.error, 'An independent account error');
      expect(controller.catalogError, isNull);
      expect(controller.workers, isEmpty);
      expect(controller.canLoadMore, isFalse);
      expect(controller.workerSearchLoading, isFalse);
      await controller.setManualLocation('Lahore', 'Model Town');
      await controller.searchWorkers();
      expect(controller.search.professionId, electrician.id);
      expect(controller.workers, isEmpty);
    },
  );

  test(
    'catalogue remains visible during loading and real server definitions replace bundled ones',
    () async {
      final repository = CatalogRepository()
        ..pendingCatalog = Completer<List<Map<String, dynamic>>>();
      final controller = MarketplaceController(repository: repository);
      addTearDown(controller.dispose);
      final initializing = controller.initialize();
      expect(controller.catalogLoading, isTrue);
      expect(controller.professions.length, 18);
      expect(controller.catalogSource, CatalogSource.bundled);
      repository.pendingCatalog!.complete(repository.catalogRows);
      expect(await initializing, isTrue);
      expect(controller.catalogLoading, isFalse);
      expect(controller.catalogError, isNull);
      expect(controller.catalogSource, CatalogSource.server);
      expect(controller.professions.single.name, 'Operator configured service');
      expect(
        controller.filterProfessions(skillId: 'Operator skill').single.name,
        'Operator configured service',
      );
    },
  );

  test(
    'network failure uses service fallback and separates catalogue, worker and account failures',
    () async {
      final repository = CatalogRepository()
        ..catalogFailure = StateError('Catalogue connection unavailable');
      final controller = MarketplaceController(repository: repository);
      addTearDown(controller.dispose);
      expect(await controller.initialize(), isTrue);
      expect(controller.professions.length, 18);
      expect(controller.catalogSource, CatalogSource.bundled);
      expect(controller.catalogError, 'Catalogue connection unavailable');
      expect(controller.error, isNull);
      await controller.setManualLocation('Lahore', '');
      repository.delayedCalls['search_workers'] = Completer<dynamic>();
      final searching = controller.searchWorkers();
      repository.delayedCalls['search_workers']!.completeError(
        StateError('Worker connection unavailable'),
      );
      expect(await searching, isFalse);
      expect(controller.workers, isEmpty);
      expect(controller.workerSearchError, 'Worker connection unavailable');
      expect(controller.catalogError, 'Catalogue connection unavailable');
      expect(controller.error, isNull);
    },
  );

  test(
    'refresh recovers failed catalogue fetch and adopts server changes',
    () async {
      final repository = CatalogRepository()
        ..catalogFailure = StateError('Unavailable');
      final controller = MarketplaceController(repository: repository);
      addTearDown(controller.dispose);
      await controller.initialize();
      expect(controller.catalogSource, CatalogSource.bundled);
      repository.catalogFailure = null;
      expect(await controller.refresh(), isTrue);
      expect(controller.catalogSource, CatalogSource.server);
      expect(controller.professions.length, 1);
      expect(controller.catalogError, isNull);
      expect(repository.catalogRequests, 2);
      repository.catalogRows = [
        {
          ...repository.catalogRows.single,
          'skills': ['New server skill'],
        },
      ];
      await controller.reloadCatalog();
      expect(
        controller.professions.single.skills.single.id,
        'New server skill',
      );
    },
  );

  test(
    'successful empty server catalogue is authoritative and failed refresh retains server definitions',
    () async {
      final repository = CatalogRepository()..catalogRows = [];
      final controller = MarketplaceController(repository: repository);
      addTearDown(controller.dispose);
      await controller.initialize();
      expect(controller.catalogSource, CatalogSource.server);
      expect(controller.professions, isEmpty);
      repository.catalogFailure = StateError('Temporary outage');
      expect(await controller.reloadCatalog(), isFalse);
      expect(controller.catalogSource, CatalogSource.server);
      expect(controller.professions, isEmpty);
      expect(controller.catalogError, isNotNull);
    },
  );

  test(
    'concurrent catalogue retries share one request and malformed records cannot erase fallback',
    () async {
      final repository = CatalogRepository()
        ..pendingCatalog = Completer<List<Map<String, dynamic>>>();
      final controller = MarketplaceController(repository: repository);
      addTearDown(controller.dispose);
      final first = controller.reloadCatalog(),
          second = controller.reloadCatalog();
      expect(identical(first, second), isTrue);
      expect(repository.catalogRequests, 1);
      repository.pendingCatalog!.complete([
        {'id': '', 'name': '', 'category': ''},
      ]);
      expect(await first, isFalse);
      expect(await second, isFalse);
      expect(controller.catalogSource, CatalogSource.bundled);
      expect(controller.professions.length, 18);
      expect(controller.catalogError, contains('could not be read'));
    },
  );
}
