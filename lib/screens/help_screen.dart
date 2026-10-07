import 'package:flutter/material.dart';
import '../localization/app_language.dart';
import '../widgets/app_ui.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});
  @override
  Widget build(BuildContext context) => AppPage(
    title: 'How Khidmat works',
    navigation: false,
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _section(
          context,
          'Start with your profile',
          'Choose Worker or Work giver, add your name and city, and save your profile.',
        ),
        _section(
          context,
          'Keep useful contacts',
          'Add workers you know. Search by name, city or service in English, Urdu or Roman Urdu.',
        ),
        _section(
          context,
          'Plan and track work',
          'Save a job with a date, time, address and price. Update its status as the work progresses.',
        ),
        _section(
          context,
          'Agree directly',
          'Call, send SMS or share your request. A saved appointment does not notify another person or reserve their time.',
        ),
        _section(
          context,
          'Your phone, your records',
          'Khidmat works without an online account. Profiles, contacts and jobs are stored on this phone and do not sync to other phones.',
        ),
        _section(
          context,
          'Keep a backup',
          'Use Backup and restore before changing phones or uninstalling the app.',
        ),
        _section(
          context,
          'Phone and SMS',
          'The Call and Send SMS buttons open your phone’s dialer and messaging app. Your mobile provider’s usual charges apply.',
        ),
        _section(
          context,
          'Shared online services',
          'Shared worker discovery, OTP login and in-app live chat need an online service. They are not enabled in this version.',
        ),
      ],
    ),
  );
  Widget _section(BuildContext context, String title, String description) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LocalizedText(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            LocalizedText(description),
          ],
        ),
      );
}
