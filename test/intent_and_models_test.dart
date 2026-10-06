import 'package:flutter_test/flutter_test.dart';
import 'package:khidmat/agents/faham_agent.dart';
import 'package:khidmat/agents/bharosa_agent.dart';
import 'package:khidmat/models/provider_model.dart';
import 'package:khidmat/models/live_booking.dart';
import 'package:khidmat/screens/otp_screen.dart';
import 'package:khidmat/services/backend_session.dart';

void main() {
  test('short AC keyword does not misclassify teacher or facial', () {
    expect(FahamAgent.parse('I need a teacher').serviceType, 'Tutor');
    expect(FahamAgent.parse('facial chahiye').serviceType, 'Beautician');
    expect(FahamAgent.parse('AC repair chahiye').serviceType, 'AC Technician');
    expect(FahamAgent.parse('مجھے پلمبر چاہیے').serviceType, 'Plumber');
    expect(FahamAgent.parse('بجلی کا مسئلہ ہے').serviceType, 'Electrician');
  });
  test('only explicit budgets are extracted and k units are honored', () {
    expect(FahamAgent.parse('Plumber, budget 2k').budget, 2000);
    expect(FahamAgent.parse('Plumber for house 1234').budget, isNull);
  });
  test('Pakistan local phone numbers become E164', () {
    expect(normalizePhone('0300 1234567'), '+923001234567');
    expect(normalizePhone('+92 300 1234567'), '+923001234567');
    expect(() => normalizePhone('123'), throwsFormatException);
  });
  test('privileged credentials cannot be used as app keys', () {
    expect(
      () => BackendSession.validateConfig(
        'https://example.supabase.co',
        'sb_secret_test',
      ),
      throwsFormatException,
    );
    expect(
      () => BackendSession.validateConfig(
        'http://example.supabase.co',
        'sb_publishable_test',
      ),
      throwsFormatException,
    );
  });
  test('new providers have no invented trust score', () {
    final provider = ServiceProvider.fromJson({
      'id': 'provider',
      'user_id': 'owner',
      'name': 'Real Provider',
      'category': 'Plumber',
      'location': 'Islamabad',
      'price_min': 1200,
      'price_max': 1500,
      'available_slots': ['09:00'],
    });
    final report = BharosaAgent.evaluate(provider);
    expect(provider.rating, 0);
    expect(provider.distanceKm.isNaN, isTrue);
    expect(report.trustScore, 0);
    expect(report.explanation, contains('reviews will appear'));
  });
  test('booking actions depend on the server status', () {
    expect(LiveBooking({'status': 'pending'}).canCancel, isTrue);
    expect(LiveBooking({'status': 'in_progress'}).canCancel, isFalse);
    expect(LiveBooking({'status': 'completed'}).terminal, isTrue);
  });
}
