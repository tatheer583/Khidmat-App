import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/marketplace_controller.dart';
import 'services/secure_auth_storage.dart';

/// Public client configuration only. Administrative keys belong on the server.
class MarketplaceConfiguration {
  const MarketplaceConfiguration({required this.url, required this.key});
  final String url, key;

  factory MarketplaceConfiguration.fromEnvironment() =>
      const MarketplaceConfiguration(
        url: String.fromEnvironment('SUPABASE_URL'),
        key: String.fromEnvironment(
          'SUPABASE_PUBLISHABLE_KEY',
          defaultValue: String.fromEnvironment('SUPABASE_ANON_KEY'),
        ),
      );

  bool get configured => url.isNotEmpty && key.isNotEmpty;

  void validate({bool allowLocalDevelopment = false}) {
    final uri = Uri.tryParse(url);
    final local =
        uri != null &&
        ['localhost', '127.0.0.1', '10.0.2.2', '::1'].contains(uri.host);
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        !(uri.scheme == 'https' ||
            (allowLocalDevelopment && local && uri.scheme == 'http')) ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException(
        'Configure a valid HTTPS Supabase project URL.',
      );
    }
    if (key.startsWith('sb_publishable_') && key.length > 20) return;
    if (key.startsWith('sb_secret_')) {
      throw const FormatException(
        'A server secret cannot be used in the mobile app. Use the publishable key.',
      );
    }
    try {
      final parts = key.split('.');
      if (parts.length != 3) throw const FormatException();
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map || payload['role'] != 'anon') {
        throw const FormatException();
      }
    } catch (_) {
      throw const FormatException(
        'Use a Supabase publishable or legacy anon key. Administrative keys are prohibited.',
      );
    }
  }
}

Future<MarketplaceController> bootstrapMarketplace() async {
  final configuration = MarketplaceConfiguration.fromEnvironment();
  if (!configuration.configured) return MarketplaceController();
  try {
    configuration.validate(allowLocalDevelopment: kDebugMode);
    await Supabase.initialize(
      url: configuration.url,
      publishableKey: configuration.key,
      debug: false,
      authOptions: FlutterAuthClientOptions(
        detectSessionInUri: false,
        localStorage: SecureAuthStorage(projectUrl: configuration.url),
      ),
    );
    return MarketplaceController(client: Supabase.instance.client);
  } catch (_) {
    // Never echo SDK errors that might include URLs, headers or session data.
    return MarketplaceController(
      configurationError:
          'Online services could not start. Check the app configuration and secure device storage. Saved phone records remain available.',
    );
  }
}
