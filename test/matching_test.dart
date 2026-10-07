import 'package:flutter_test/flutter_test.dart';
import 'package:khidmat/models/local_data.dart';
import 'package:khidmat/services/service_matcher.dart';

void main() {
  test('Pakistani and international phone numbers normalize safely', () {
    expect(cleanPhone('0300 123-4567'), '+923001234567');
    expect(cleanPhone('0092 (300) 1234567'), '+923001234567');
    expect(validPhone('+44 7911 123456'), isTrue);
    expect(validPhone('phone 03001234567'), isFalse);
    expect(validPhone(''), isFalse);
    expect(validPhone('', optional: true), isTrue);
  });
  test(
    'English, Urdu and Roman Urdu service searches respect word boundaries',
    () {
      expect(serviceForQuery('facial'), 'Beautician');
      expect(serviceForQuery('AC repair'), 'AC Technician');
      expect(serviceForQuery('بجلی کا کام'), 'Electrician');
      expect(serviceForQuery('pani leak'), 'Plumber');
      expect(serviceForQuery('account'), isNull);
    },
  );
  test(
    'search returns only saved matching workers with favorite/category filters',
    () {
      const workers = [
        WorkerContact(
          id: '1',
          name: 'Ali',
          phone: '03001234567',
          category: 'Plumber',
          city: 'Lahore',
        ),
        WorkerContact(
          id: '2',
          name: 'Zain',
          phone: '03011234567',
          category: 'Plumber',
          city: 'Lahore',
          favorite: true,
        ),
        WorkerContact(
          id: '3',
          name: 'Sara',
          phone: '03021234567',
          category: 'Electrician',
          city: 'Karachi',
        ),
      ];
      expect(findSavedWorkers(workers, 'pani').map((w) => w.id), ['2', '1']);
      expect(findSavedWorkers(workers, '', favoritesOnly: true).single.id, '2');
      expect(findSavedWorkers(workers, 'Karachi').single.id, '3');
      expect(
        findSavedWorkers(workers, '', category: 'Electrician').single.id,
        '3',
      );
      expect(findSavedWorkers([], 'plumber'), isEmpty);
    },
  );
}
