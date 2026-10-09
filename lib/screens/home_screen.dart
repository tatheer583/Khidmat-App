import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../localization/app_language.dart';
import '../models/local_data.dart';
import '../services/local_store.dart';
import '../services/contact_actions.dart';
import '../theme/app_colors.dart';
import '../widgets/app_ui.dart';
import '../widgets/khidmat_brand.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<LocalStore>();
    final profile = store.profile;
    if (profile == null) return const SizedBox.shrink();
    final worker = profile.role == AccountRole.worker;
    final jobs = store.roleJobs;
    final active = jobs.where((j) => j.status.active).toList();
    final completed = jobs.where((j) => j.status == JobStatus.completed).length;
    return AppPage(
      title: worker ? 'Worker dashboard' : 'Work giver dashboard',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: AppColors.cardGradient,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const KhidmatBrandMark(size: 48),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        profile.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                LocalizedText(
                  worker
                      ? 'Your work, organized.'
                      : 'Good help starts with good contacts.',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(profile.city),
                if (worker) ...[
                  LocalizedText(profile.profession),
                  LocalizedText(
                    '${profile.experienceYears} years of experience',
                  ),
                ],
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () => context.push('/jobs/new'),
                  icon: const Icon(Icons.add),
                  label: LocalizedText(worker ? 'Add job' : 'Plan a service'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _Metric('Active jobs', active.length)),
              const SizedBox(width: 8),
              Expanded(child: _Metric('Completed', completed)),
              const SizedBox(width: 8),
              Expanded(child: _Metric('Saved workers', store.workers.length)),
            ],
          ),
          const SizedBox(height: 20),
          if (store.notice != null) InfoCard(store.notice!),
          LocalizedText(
            'Next appointments',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (active.isEmpty)
            EmptyState(
              title: 'A clear day ahead',
              message: 'Add an appointment to keep track of your work.',
              icon: Icons.calendar_today_outlined,
            )
          else
            ...active.take(3).map(JobCard.new),
          if (active.isNotEmpty)
            TextButton(
              onPressed: () => context.go('/jobs'),
              child: const LocalizedText('View all jobs'),
            ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.people_outline),
              title: const LocalizedText('Saved workers'),
              subtitle: const LocalizedText(
                'People you can call for local services.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/contacts'),
            ),
          ),
          if (worker)
            Card(
              child: ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const LocalizedText('Share my profile'),
                subtitle: const LocalizedText(
                  'Send your profession and contact details.',
                ),
                onTap: () => ContactActions.shareText(
                  context,
                  ContactActions.profileText(context, profile),
                ),
              ),
            ),
          const SizedBox(height: 12),
          const LocalizedText(
            'Saved on this phone',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
    decoration: BoxDecoration(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        Text('$value', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        LocalizedText(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}
