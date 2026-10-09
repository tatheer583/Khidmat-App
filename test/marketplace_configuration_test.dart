import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:khidmat/marketplace/bootstrap.dart';
import 'package:khidmat/marketplace/push_notifications.dart';

String jwtForRole(String role) =>
    'header.${base64Url.encode(utf8.encode(jsonEncode({'role': role}))).replaceAll('=', '')}.signature';

void main() {
  test(
    'client accepts publishable and legacy anon keys but rejects administrative credentials',
    () {
      const url = 'https://example.supabase.co';
      expect(
        () => const MarketplaceConfiguration(
          url: url,
          key: 'sb_publishable_example_public_key',
        ).validate(),
        returnsNormally,
      );
      expect(
        () => MarketplaceConfiguration(
          url: url,
          key: jwtForRole('anon'),
        ).validate(),
        returnsNormally,
      );
      for (final key in [
        'sb_secret_private_key',
        jwtForRole('service_role'),
        jwtForRole('authenticated'),
        'arbitrary-key',
      ]) {
        expect(
          () => MarketplaceConfiguration(url: url, key: key).validate(),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'production configuration requires TLS and debug only permits known local hosts',
    () {
      const key = 'sb_publishable_example_public_key';
      for (final url in [
        'http://example.supabase.co',
        'https://user:password@example.supabase.co',
        'https://example.supabase.co?token=private',
      ]) {
        expect(
          () => MarketplaceConfiguration(url: url, key: key).validate(),
          throwsFormatException,
        );
      }
      const local = MarketplaceConfiguration(
        url: 'http://10.0.2.2:54321',
        key: key,
      );
      expect(local.validate, throwsFormatException);
      expect(
        () => local.validate(allowLocalDevelopment: true),
        returnsNormally,
      );
    },
  );
  test(
    'unconfigured push neither initializes a provider nor reports delivery success',
    () async {
      final push = OptionalPushService();
      expect(push.configured, isFalse);
      expect(await push.enable(), isFalse);
      expect(push.enabled, isFalse);
      expect(push.error, isNotNull);
      push.dispose();
    },
  );
}
