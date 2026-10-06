import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../localization/app_language.dart';
import '../services/backend_session.dart';
import '../widgets/live_ui.dart';

class ConnectionScreen extends StatelessWidget {
  const ConnectionScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final session = context.watch<BackendSession>();
    final busy =
        session.initializing ||
        session.checkingServices ||
        session.profileLoading;
    final message = session.serviceError ?? session.error;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khidmat'),
        actions: const [LanguageButton()],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    busy ? Icons.handshake_outlined : Icons.cloud_off_outlined,
                    size: 64,
                  ),
                  const SizedBox(height: 24),
                  LocalizedText(
                    busy ? 'Connecting to Khidmat…' : 'Unable to connect',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  if (busy)
                    const CircularProgressIndicator()
                  else ...[
                    Notice(message ?? 'Your profile could not be loaded.'),
                    ElevatedButton.icon(
                      onPressed: session.serviceAvailable
                          ? session.refreshProfile
                          : session.checkServices,
                      icon: const Icon(Icons.refresh),
                      label: const LocalizedText('Try again'),
                    ),
                  ],
                  if (session.signedIn && !busy)
                    TextButton(
                      onPressed: () async {
                        try {
                          await session.signOut();
                        } catch (e) {
                          if (context.mounted) {
                            showMessage(context, describeError(e));
                          }
                        }
                      },
                      child: const LocalizedText('Sign out'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
