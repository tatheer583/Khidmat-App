import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../localization/app_language.dart';
import '../models/local_data.dart';
import '../services/local_store.dart';
import '../services/contact_actions.dart';
import '../widgets/app_ui.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final profile = context.watch<LocalStore>().profile;
    if (profile == null) return const SizedBox.shrink();
    return AppPage(
      title: 'My profile',
      section: 3,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(child: PersonAvatar(profile.name, radius: 40)),
          const SizedBox(height: 20),
          Text(
            profile.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          LocalizedText(profile.role.label, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(profile.city),
                ),
                if (profile.phone.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.call_outlined),
                    title: Text(profile.phone),
                  ),
                if (profile.role == AccountRole.worker) ...[
                  ListTile(
                    leading: const Icon(Icons.handyman_outlined),
                    title: LocalizedText(profile.profession),
                  ),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: LocalizedText(
                      '${profile.experienceYears} years of experience',
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (profile.details.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(profile.details),
            ),
          OutlinedButton.icon(
            onPressed: () => context.push('/profile/edit'),
            icon: const Icon(Icons.edit_outlined),
            label: const LocalizedText('Edit profile and account type'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => ContactActions.shareText(
              context,
              ContactActions.profileText(context, profile),
            ),
            icon: const Icon(Icons.share_outlined),
            label: const LocalizedText('Share my profile'),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: const LocalizedText('Backup and restore'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/backup'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.help_outline),
              title: const LocalizedText('How Khidmat works'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/help'),
            ),
          ),
          const SizedBox(height: 16),
          const LocalizedText(
            'Saved on this phone',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text('Khidmat 2.0.0', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
