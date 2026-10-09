import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../localization/app_language.dart';
import '../../widgets/app_ui.dart';
import '../services/marketplace_controller.dart';
import '../widgets/marketplace_ui.dart';

class MarketplacePrivacyScreen extends StatefulWidget {
  const MarketplacePrivacyScreen({super.key});

  @override
  State<MarketplacePrivacyScreen> createState() =>
      _MarketplacePrivacyScreenState();
}

class _MarketplacePrivacyScreenState extends State<MarketplacePrivacyScreen> {
  bool _exporting = false;

  Future<void> _export() async {
    setState(() => _exporting = true);
    final controller = context.read<MarketplaceController>();
    File? file;
    try {
      final data = await controller.exportAccount();
      if (data == null || !mounted) return;
      final folder = await getTemporaryDirectory();
      file = File(
        '${folder.path}${Platform.pathSeparator}khidmat-account-${DateTime.now().microsecondsSinceEpoch}.json',
      );
      await file.writeAsString(data, flush: true);
      if (!mounted) return;
      final render = context.findRenderObject();
      final origin = render is RenderBox && render.hasSize
          ? render.localToGlobal(Offset.zero) & render.size
          : null;
      await SharePlus.instance.share(
        ShareParams(
          title: context.tr('My Khidmat account data'),
          files: [XFile(file.path, mimeType: 'application/json')],
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {
      if (mounted) {
        showMessage(
          context,
          'Your export could not be shared. Please try again.',
        );
      }
    } finally {
      // The export contains private information; remove our temporary copy after sharing.
      if (file != null) {
        try {
          await file.delete();
        } catch (_) {}
      }
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MarketplaceController>();
    return MarketplacePage(
      title: 'Privacy and account data',
      navigation: false,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const MarketplaceHeading('You decide what you share'),
          const MarketplaceNotice(
            message:
                'Device location is requested only when you choose to use it. '
                'Khidmat does not continuously track you in the background.',
          ),
          const MarketplaceHeading('Your public worker profile'),
          const LocalizedText(
            'Customers can see your professional name, service area, skills, prices, '
            'working hours, portfolio and completed-job reviews when your profile is published. '
            'Upload photos and write descriptions that you are comfortable making public.',
          ),
          const SizedBox(height: 20),
          const MarketplaceHeading('Your location and contact details'),
          const LocalizedText(
            'Your exact worker coordinates are kept private. Customers see an approximate distance '
            'when a sufficiently recent service location is available. Your home address is not part of your public profile. '
            'Phone and WhatsApp details are shared with eligible signed-in customers only if you enable contact sharing.',
          ),
          const SizedBox(height: 16),
          if (controller.isAuthenticated &&
              controller.profile?.isWorker == true)
            OutlinedButton(
              onPressed: () => context.go('/marketplace/worker/edit'),
              child: const LocalizedText(
                'Manage my public profile and contact sharing',
              ),
            ),
          const SizedBox(height: 20),
          const MarketplaceHeading('Job details and reviews'),
          const LocalizedText(
            'Your private work address and job details are accessible to the job’s participants. '
            'Reviews are public. Keep personal phone numbers, identity documents and private addresses out of reviews.',
          ),
          const SizedBox(height: 20),
          if (!controller.isAuthenticated)
            const MarketplaceSignIn(
              message:
                  'Sign in to export your account data or manage your account.',
            ),
          if (controller.error != null)
            MarketplaceNotice(message: controller.error!, error: true),
          if (controller.isAuthenticated) ...[
            const MarketplaceHeading('Your account data'),
            const LocalizedText(
              'Export a copy of your profile, job records, reviews and reports. '
              'The exported file contains personal information; choose a private destination.',
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: controller.busy || _exporting ? null : _export,
              icon: const Icon(Icons.download_outlined),
              label: LocalizedText(
                _exporting ? 'Preparing export…' : 'Export my account data',
              ),
            ),
            const SizedBox(height: 24),
            const MarketplaceHeading('Deactivate your account'),
            const LocalizedText(
              'Deactivation hides your worker profile, cancels pending requests, removes your saved service coordinates '
              'and signs you out. Resolve accepted or ongoing work first. Job history and account records are retained; '
              'this does not delete your data. Contact support about data removal or reactivation.',
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: controller.busy
                  ? null
                  : () async {
                      final confirmed = await confirmAction(
                        context,
                        'Deactivate your account?',
                        'Your profile will be hidden and pending requests cancelled. Your account records and job history will be retained.',
                        confirm: 'Deactivate account',
                      );
                      if (!confirmed || !context.mounted) return;
                      final deactivated = await controller.deactivateAccount();
                      if (context.mounted && deactivated) {
                        context.go('/marketplace');
                      }
                    },
              icon: const Icon(Icons.person_off_outlined),
              label: const LocalizedText('Deactivate account'),
            ),
          ],
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => context.push('/marketplace/help'),
            child: const LocalizedText('Contact support and get help'),
          ),
        ],
      ),
    );
  }
}
