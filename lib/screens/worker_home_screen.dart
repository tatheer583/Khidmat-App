import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../localization/app_language.dart';
import '../services/backend_session.dart';

class WorkerHomeScreen extends StatelessWidget {
  const WorkerHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final session = context.watch<BackendSession>();
    final profile = session.profile!;
    return Scaffold(
      appBar: AppBar(
        title: const LocalizedText('Worker dashboard'),
        actions: [
          const LanguageButton(),
          IconButton(
            tooltip: context.tr('My account'),
            onPressed: () => context.push('/account'),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          LocalizedText(
            'Welcome, ${session.displayName}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          const LocalizedText('Manage your listing and incoming work.'),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LocalizedText('Your worker profile'),
                  const SizedBox(height: 12),
                  LocalizedText(
                    profile['profession'] as String? ?? '',
                    translate: false,
                  ),
                  LocalizedText(
                    '${profile['experience_years'] ?? 0} years of experience',
                  ),
                  const SizedBox(height: 12),
                  LocalizedText(
                    profile['bio'] as String? ?? '',
                    translate: false,
                  ),
                  TextButton(
                    onPressed: () => context.push('/profile/edit'),
                    child: const LocalizedText('Edit profile'),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.work_outline),
              title: const LocalizedText('My jobs'),
              subtitle: const LocalizedText(
                'Requests, accepted jobs and conversations.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/bookings'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: const LocalizedText('Edit service listing'),
              subtitle: const LocalizedText('Set your rates and availability.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/provider'),
            ),
          ),
        ],
      ),
    );
  }
}
