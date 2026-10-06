import '../localization/app_language.dart';
import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      actions: const [LanguageButton()],
      title: const LocalizedText('Using Khidmat'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        ListTile(
          title: LocalizedText('Find a provider'),
          subtitle: LocalizedText(
            'Enter your city and describe the work. Only approved, available listings appear.',
          ),
        ),
        ListTile(
          title: LocalizedText('Book a service'),
          subtitle: LocalizedText(
            'Review the provider-authorized quote, choose a date and time, and enter your full address. '
            'The request stays pending until the provider accepts it.',
          ),
        ),
        ListTile(
          title: LocalizedText('Updates and chat'),
          subtitle: LocalizedText(
            'Open My bookings to see current status and chat with the other participant. '
            'You can share photos of the work.',
          ),
        ),
        ListTile(
          title: LocalizedText('Payment'),
          subtitle: LocalizedText(
            'Pay cash after service. Additional work or materials must be agreed with the provider.',
          ),
        ),
        ListTile(
          title: LocalizedText('Offer your services'),
          subtitle: LocalizedText(
            'Create a listing in the provider dashboard. The app owner reviews it before publication. '
            'Set your authorized prices and available daily times.',
          ),
        ),
        ListTile(
          title: LocalizedText('Reviews'),
          subtitle: LocalizedText(
            'A customer can review each completed booking once. New providers have no review history.',
          ),
        ),
      ],
    ),
  );
}
