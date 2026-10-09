import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../localization/app_language.dart';
import '../../widgets/app_ui.dart';
import '../widgets/marketplace_ui.dart';

class MarketplaceHelpScreen extends StatelessWidget {
  const MarketplaceHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const supportEmail = String.fromEnvironment('KHIDMAT_SUPPORT_EMAIL');
    final hasSupport = RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    ).hasMatch(supportEmail);
    return MarketplacePage(
      title: 'Help and safety',
      navigation: false,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const MarketplaceHeading('Find local help'),
          const LocalizedText(
            'Choose your city or use device location, then select a profession and skill. '
            'Compare experience, prices, availability and reviews. Send a request with the work details and a proposed time.',
          ),
          const SizedBox(height: 20),
          const MarketplaceHeading('Agree on the work'),
          const LocalizedText(
            'The worker must accept your request to confirm the booking. Agree on the scope, '
            'materials and final price directly. A starting price is an estimate for the stated pricing unit.',
          ),
          const SizedBox(height: 20),
          const MarketplaceHeading('Offer your services'),
          const LocalizedText(
            'Verify your mobile number, complete your account details and add the worker role. '
            'Build your professional profile in four steps. You can save a private draft and return later. '
            'Publish your profile when the required details are ready.',
          ),
          const SizedBox(height: 20),
          const MarketplaceHeading('Keep your availability accurate'),
          const LocalizedText(
            'Available now requires a recent location update and expires after 15 minutes. '
            'Choose Available later, Busy or Offline when appropriate. Your usual working schedule is separate from your current availability.',
          ),
          const SizedBox(height: 20),
          const MarketplaceHeading('Complete and review'),
          const LocalizedText(
            'Workers update the job as work progresses and request completion. '
            'The customer confirms completion, then can leave one review for that job.',
          ),
          const SizedBox(height: 20),
          const MarketplaceHeading('Stay safe'),
          const LocalizedText(
            'Keep verification codes private. Confirm who you are dealing with and discuss the work before paying. '
            'Use Report profile to send a concern to the operator. A verified phone number is not proof of identity or qualifications.',
          ),
          const SizedBox(height: 20),
          const MarketplaceHeading('Contact support'),
          if (hasSupport)
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  final opened = await launchUrl(
                    Uri(
                      scheme: 'mailto',
                      path: supportEmail,
                      queryParameters: {'subject': 'Khidmat support request'},
                    ),
                  );
                  if (!opened && context.mounted) {
                    showMessage(context, 'No email app is available.');
                  }
                } catch (_) {
                  if (context.mounted) {
                    showMessage(context, 'The email app could not be opened.');
                  }
                }
              },
              icon: const Icon(Icons.mail_outline),
              label: Text(supportEmail),
            )
          else
            const MarketplaceNotice(
              message:
                  'A support contact has not been configured for this installation. '
                  'Profile reports are stored for review when the marketplace is connected.',
            ),
          const SizedBox(height: 16),
          const MarketplaceHeading('Saved phone records'),
          const LocalizedText(
            'Your older contacts and appointment notes stay in Saved records. '
            'These records are separate from online bookings and do not notify other people.',
          ),
        ],
      ),
    );
  }
}
