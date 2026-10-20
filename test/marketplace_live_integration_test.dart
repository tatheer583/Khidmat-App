import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khidmat/marketplace/bootstrap.dart';
import 'package:khidmat/marketplace/models/marketplace_models.dart';

/// Opt-in against a dedicated staging project and genuinely verified accounts.
/// Credentials are read from an ignored --dart-define-from-file, never source.
/// This exercises the deployed API, not SMS delivery or mobile OS behavior.
void main() {
  const enabled = bool.fromEnvironment('RUN_LIVE_MARKETPLACE_TESTS');
  test(
    'staging customer and worker complete an authorized job and review across separate sessions',
    () async {
      const url = String.fromEnvironment('SUPABASE_URL');
      const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
      const expectedProject = String.fromEnvironment(
        'TEST_STAGING_PROJECT_REF',
      );
      const customerPhone = String.fromEnvironment('TEST_CUSTOMER_PHONE');
      const workerPhone = String.fromEnvironment('TEST_WORKER_PHONE');
      const customerPassword = String.fromEnvironment('TEST_CUSTOMER_PASSWORD');
      const workerPassword = String.fromEnvironment('TEST_WORKER_PASSWORD');
      expect(
        const bool.fromEnvironment('TEST_ENVIRONMENT_IS_STAGING'),
        isTrue,
        reason:
            'This test creates retained test records and must never run in production.',
      );
      expect(expectedProject, isNotEmpty);
      expect(Uri.parse(url).host.split('.').first, expectedProject);
      MarketplaceConfiguration(url: url, key: key).validate();
      expect(customerPhone, isNot(workerPhone));
      expect(customerPassword, isNotEmpty);
      expect(workerPassword, isNotEmpty);
      final customer = SupabaseClient(url, key);
      final worker = SupabaseClient(url, key);
      Map<String, dynamic>? workerDetails;
      try {
        await customer.auth.signInWithPassword(
          phone: normalizePakistaniPhone(customerPhone),
          password: customerPassword,
        );
        await worker.auth.signInWithPassword(
          phone: normalizePakistaniPhone(workerPhone),
          password: workerPassword,
        );
        final customerUser = (await customer.auth.getUser()).user;
        final workerUser = (await worker.auth.getUser()).user;
        expect(
          DateTime.tryParse(customerUser?.phoneConfirmedAt ?? ''),
          isNotNull,
        );
        expect(
          DateTime.tryParse(workerUser?.phoneConfirmedAt ?? ''),
          isNotNull,
        );
        final customerId = customer.auth.currentUser!.id;
        final workerId = worker.auth.currentUser!.id;
        await customer.rpc(
          'save_profile',
          params: {
            'p_profile': {
              'full_name': 'Dedicated staging customer',
              'city': 'Lahore',
              'neighbourhood': 'QA test area',
              'roles': ['customer'],
              'whatsapp': '',
            },
          },
        );
        await worker.rpc(
          'save_profile',
          params: {
            'p_profile': {
              'full_name': 'Dedicated staging worker',
              'city': 'Lahore',
              'neighbourhood': 'QA test area',
              'roles': ['worker'],
              'whatsapp': '',
            },
          },
        );
        final catalog = await customer
            .from('professions')
            .select()
            .eq('active', true)
            .order('sort_order')
            .limit(1);
        final profession = Profession.fromJson(catalog.single);
        final answers = <String, dynamic>{};
        for (final question in profession.questions) {
          answers[question.id] = switch (question.type) {
            'boolean' => false,
            'number' => 0,
            'select' => question.options.first,
            'multiselect' => [question.options.first],
            _ => 'Staging test response',
          };
        }
        workerDetails = WorkerDraft(
          professionId: profession.id,
          skillIds: [profession.skills.first.id],
          description:
              'Dedicated staging test profile. This is not a real service listing.',
          rate: 100,
          rateUnit: 'day',
          answers: answers,
          published: true,
        ).toJson();
        await worker.rpc(
          'save_worker_profile',
          params: {
            'p_profile': workerDetails,
            'p_latitude': 31.5204,
            'p_longitude': 74.3587,
          },
        );
        await worker.rpc(
          'set_worker_availability',
          params: {
            'p_status': 'available_now',
            'p_latitude': 31.5204,
            'p_longitude': 74.3587,
          },
        );
        final results = await customer.rpc(
          'search_workers',
          params: {
            'p_latitude': 31.5204,
            'p_longitude': 74.3587,
            'p_profession_id': profession.id,
            'p_available_only': true,
            'p_limit': 20,
            'p_query': 'Dedicated staging worker',
          },
        );
        expect((results as List).any((r) => r['id'] == workerId), isTrue);
        expect(
          results.every(
            (r) => !r.containsKey('latitude') && !r.containsKey('longitude'),
          ),
          isTrue,
        );
        final job = await customer.rpc(
          'create_job',
          params: {
            'p_worker_id': workerId,
            'p_profession_id': profession.id,
            'p_description':
                'Dedicated staging integration test service request.',
            'p_scheduled_at': DateTime.now()
                .toUtc()
                .add(const Duration(days: 2))
                .toIso8601String(),
            'p_city': 'Lahore',
            'p_neighbourhood': 'QA test area',
            'p_address': 'Staging test address',
            'p_offered_price': 100,
          },
        );
        final jobId = job['id'];
        expect(job['customer_id'], customerId);
        await expectLater(
          customer.rpc(
            'transition_job',
            params: {'p_job_id': jobId, 'p_status': 'accepted'},
          ),
          throwsA(isA<PostgrestException>()),
        );
        for (final status in [
          'accepted',
          'in_progress',
          'completion_requested',
        ]) {
          await worker.rpc(
            'transition_job',
            params: {'p_job_id': jobId, 'p_status': status},
          );
        }
        await customer.rpc(
          'transition_job',
          params: {'p_job_id': jobId, 'p_status': 'completed'},
        );
        expect(
          (await worker
              .from('jobs')
              .select()
              .eq('id', jobId)
              .single())['status'],
          'completed',
        );
        await customer.rpc(
          'review_job',
          params: {
            'p_job_id': jobId,
            'p_rating': 5,
            'p_comment': 'Dedicated staging test review.',
          },
        );
        await expectLater(
          customer.rpc(
            'review_job',
            params: {'p_job_id': jobId, 'p_rating': 5},
          ),
          throwsA(isA<PostgrestException>()),
        );
        expect(
          await customer
              .from('notifications')
              .select()
              .neq('user_id', customerId),
          isEmpty,
        );
        expect(
          await customer.from('profiles').select().eq('id', workerId),
          isEmpty,
        );
      } finally {
        // Retain the audit history; hide only this explicitly designated test listing.
        try {
          if (workerDetails != null && worker.auth.currentUser != null) {
            await worker.rpc(
              'save_worker_profile',
              params: {
                'p_profile': {...workerDetails, 'published': false},
              },
            );
            await worker.rpc(
              'set_worker_availability',
              params: {'p_status': 'offline'},
            );
          }
        } finally {
          try {
            await customer.dispose();
          } finally {
            await worker.dispose();
          }
        }
      }
    },
    skip: !enabled
        ? 'Requires an isolated configured staging project and verified test accounts.'
        : false,
  );
}
