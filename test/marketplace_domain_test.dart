import 'package:flutter_test/flutter_test.dart';
import 'package:khidmat/marketplace/models/marketplace_models.dart';

void main() {
  test(
    'Pakistani mobile normalization rejects arbitrary/international numbers',
    () {
      for (final value in [
        '0300 123-4567',
        '0092 (300) 1234567',
        '923001234567',
        '+923001234567',
      ]) {
        expect(normalizePakistaniPhone(value), '+923001234567');
      }
      for (final value in [
        '1234567',
        '+447911123456',
        '+9203012345678',
        'phone03001234567',
        '03+001234567',
        '',
      ]) {
        expect(() => normalizePakistaniPhone(value), throwsFormatException);
      }
    },
  );

  test(
    'geographic search sends bounded server filters and manual city has no fabricated coordinates',
    () {
      const filters = WorkerSearch(
        query: 'wiring',
        professionId: 'electrician',
        skillId: 'Wiring repair',
        radiusKm: 12,
        minPrice: 100,
        maxPrice: 1500,
        minRating: 4,
        minExperience: 3,
        availableOnly: true,
      );
      final request = filters.toRpc(
        const SearchLocation(city: 'Lahore', neighbourhood: 'Model Town'),
        offset: 20,
      );
      expect(request['p_latitude'], isNull);
      expect(request['p_longitude'], isNull);
      expect(request['p_city'], 'Lahore');
      expect(request['p_offset'], 20);
      expect(request['p_limit'], 20);
      expect(request['p_skill'], 'Wiring repair');
      expect(request['p_available_only'], isTrue);
      final device = filters.toRpc(
        const SearchLocation(latitude: 31.52, longitude: 74.35, isDevice: true),
      );
      expect(device['p_city'], isNull);
      expect(device['p_latitude'], 31.52);
      expect(
        () => const WorkerSearch(radiusKm: double.nan).validate(),
        throwsFormatException,
      );
      expect(
        () => const WorkerSearch(minPrice: 100, maxPrice: 50).validate(),
        throwsFormatException,
      );
      expect(
        () => const WorkerSearch(minRating: 6).validate(),
        throwsFormatException,
      );
      expect(
        () => filters.toRpc(const SearchLocation(city: 'Lahore'), offset: -1),
        throwsFormatException,
      );
      expect(
        () => filters.toRpc(const SearchLocation(city: 'Lahore'), limit: 51),
        throwsFormatException,
      );
      expect(
        () => const SearchLocation(latitude: 31.5).validate(),
        throwsFormatException,
      );
    },
  );

  test(
    'availability and distance become unknown when timestamps are absent, stale or implausible',
    () {
      final now = DateTime.utc(2026, 10, 9, 12);
      Map<String, dynamic> row(DateTime? availability, DateTime? location) => {
        'id': 'worker',
        'name': 'Aslam',
        'availability': 'available_now',
        'distance_km': 2.5,
        'availability_updated_at': availability?.toIso8601String(),
        'location_updated_at': location?.toIso8601String(),
      };
      final fresh = now.subtract(const Duration(minutes: 2));
      final recent = MarketplaceWorker.fromJson(row(fresh, fresh), now: now);
      expect(recent.availability, WorkerAvailability.availableNow);
      expect(recent.distanceKm, 2.5);
      final stale = MarketplaceWorker.fromJson(
        row(fresh, now.subtract(const Duration(minutes: 16))),
        now: now,
      );
      expect(stale.availability, WorkerAvailability.unknown);
      expect(stale.distanceKm, isNull);
      expect(
        MarketplaceWorker.fromJson(row(null, null), now: now).availability,
        WorkerAvailability.unknown,
      );
      expect(
        MarketplaceWorker.fromJson(
          row(now.add(const Duration(days: 1)), fresh),
          now: now,
        ).availability,
        WorkerAvailability.unknown,
      );
      expect(
        WorkerAvailability.offline.fresh(now: now),
        WorkerAvailability.offline,
      );
      expect(
        WorkerAvailability.busy.fresh(
          updatedAt: now.subtract(const Duration(hours: 25)),
          now: now,
        ),
        WorkerAvailability.unknown,
      );
    },
  );

  test(
    'profession config drives questions; drafts can be saved before publishing',
    () {
      final profession = Profession.fromJson({
        'id': 'electrician',
        'name': 'Electrician',
        'category': 'Electrical Services',
        'skills': ['Wiring repair'],
        'questions': [
          {
            'key': 'experience_type',
            'label': 'Type of work',
            'type': 'select',
            'required': true,
            'options': ['Residential', 'Commercial'],
          },
          {
            'key': 'tools',
            'label': 'Own tools',
            'type': 'boolean',
            'required': true,
          },
          {
            'key': 'equipment',
            'label': 'Equipment',
            'type': 'multiselect',
            'options': ['Fans', 'Lights'],
          },
        ],
      });
      expect(
        () =>
            const WorkerDraft(professionId: 'electrician').validate(profession),
        returnsNormally,
      );
      WorkerDraft published(Map<String, dynamic> answers) => WorkerDraft(
        professionId: 'electrician',
        skillIds: ['Wiring repair'],
        description: 'Residential wiring repair and installations.',
        rate: 1000,
        published: true,
        answers: answers,
      );
      expect(() => published({}).validate(profession), throwsFormatException);
      expect(
        () => published({
          'experience_type': 'Unlisted',
          'tools': true,
        }).validate(profession),
        throwsFormatException,
      );
      expect(
        () => published({
          'experience_type': 'Residential',
          'tools': false,
          'equipment': ['Fans'],
        }).validate(profession),
        returnsNormally,
      );
      expect(
        () => published({
          'experience_type': 'Residential',
          'tools': true,
          'equipment': ['Pipes'],
        }).validate(profession),
        throwsFormatException,
      );
      expect(
        () => const WorkerDraft(
          professionId: 'electrician',
          skillIds: ['Plumbing'],
        ).validate(profession),
        throwsFormatException,
      );
      expect(
        published({'experience_type': 'Residential', 'tools': true}).toJson(),
        isNot(contains('latitude')),
      );
    },
  );

  test(
    'only participants transition jobs and customer confirms completion before reviewing',
    () {
      MarketplaceJob job(String status, {bool reviewed = false}) =>
          MarketplaceJob(
            id: 'job',
            customerId: 'customer',
            workerId: 'worker',
            status: status,
            scheduledAt: DateTime.utc(2026),
            reviewed: reviewed,
          );
      expect(job('pending').allowedTransitions('stranger'), isEmpty);
      expect(job('pending').allowedTransitions('customer'), ['cancelled']);
      expect(job('pending').allowedTransitions('worker'), [
        'accepted',
        'declined',
      ]);
      expect(job('in_progress').allowedTransitions('worker'), [
        'completion_requested',
        'cancelled',
      ]);
      expect(job('in_progress').allowedTransitions('customer'), ['cancelled']);
      expect(job('completion_requested').allowedTransitions('worker'), [
        'in_progress',
      ]);
      expect(job('completion_requested').allowedTransitions('customer'), [
        'completed',
        'in_progress',
      ]);
      expect(job('completion_requested').canReview('customer'), isFalse);
      expect(job('completed').canReview('worker'), isFalse);
      expect(job('completed').canReview('customer'), isTrue);
      expect(job('completed', reviewed: true).canReview('customer'), isFalse);
      expect(job('completed').allowedTransitions('customer'), isEmpty);
    },
  );
}
