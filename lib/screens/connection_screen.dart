import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../localization/app_language.dart';
import '../services/backend_session.dart';
import '../theme/app_colors.dart';
import '../widgets/khidmat_brand.dart';
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
    final needsOwnerSetup = message == serviceSetupMessage;
    final showingProfileError =
        !busy && session.serviceAvailable && session.error != null;
    return Scaffold(
      appBar: AppBar(actions: const [LanguageButton()]),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const KhidmatBrandMark(size: 78),
                  const SizedBox(height: 22),
                  const LocalizedText(
                    'Khidmat',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  LocalizedText(
                    busy
                        ? 'Connecting to Khidmat…'
                        : needsOwnerSetup
                        ? 'Khidmat setup is not complete'
                        : showingProfileError
                        ? 'Your profile could not be loaded'
                        : 'Unable to connect',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  if (busy)
                    const CircularProgressIndicator()
                  else ...[
                    LocalizedText(
                      needsOwnerSetup
                          ? 'Khidmat needs one setup step before anyone can sign in. Ask the app owner to install the database using the steps below.'
                          : showingProfileError
                          ? 'We could not load your profile. Check your connection, then try again.'
                          : 'Your phone cannot reach Khidmat. Check Wi-Fi or mobile data, then try again.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 18),
                    if (needsOwnerSetup)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          border: Border.all(color: AppColors.divider),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              needsOwnerSetup
                                  ? Icons.build_circle_outlined
                                  : Icons.wifi_off_rounded,
                              color: AppColors.primaryLight,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: LocalizedText(
                                serviceSetupMessage,
                                textAlign: TextAlign.start,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: session.serviceAvailable
                          ? session.refreshProfile
                          : session.checkServices,
                      icon: const Icon(Icons.refresh),
                      label: const LocalizedText('Try again'),
                    ),
                    if (needsOwnerSetup)
                      TextButton.icon(
                        onPressed: () => launchUrl(
                          Uri.parse(
                            'https://github.com/tatheer583/Khidmat-App/blob/main/docs/ACTIVATE-SUPABASE.md',
                          ),
                          mode: LaunchMode.externalApplication,
                        ),
                        icon: const Icon(Icons.open_in_new),
                        label: const LocalizedText('View setup steps'),
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
