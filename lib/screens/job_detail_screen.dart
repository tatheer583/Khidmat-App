import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../localization/app_language.dart';
import '../models/local_data.dart';
import '../services/local_store.dart';
import '../services/contact_actions.dart';
import '../widgets/app_ui.dart';

class JobDetailScreen extends StatelessWidget {
  const JobDetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<LocalStore>();
    final job = store.job(id);
    return AppPage(
      title: 'Job details',
      section: 2,
      actions: [
        if (job != null)
          IconButton(
            tooltip: context.tr('Edit job'),
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/jobs/$id/edit'),
          ),
      ],
      child: job == null
          ? const EmptyState(
              title: 'Job not found',
              message: 'This job record was removed.',
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                LocalizedText(
                  job.service,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: PersonAvatar(job.personName),
                    title: Text(job.personName),
                    subtitle: Text(
                      job.phone.isEmpty
                          ? context.tr('No phone number saved')
                          : job.phone,
                    ),
                  ),
                ),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: Text(jobDate(context, job.scheduledAt)),
                        subtitle: Text(jobTime(context, job.scheduledAt)),
                      ),
                      ListTile(
                        leading: const Icon(Icons.location_on_outlined),
                        title: Text(job.address),
                      ),
                      ListTile(
                        leading: const Icon(Icons.payments_outlined),
                        title: LocalizedText(
                          job.amount == 0
                              ? 'Price to be agreed'
                              : 'Rs. ${job.amount}',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<JobStatus>(
                  key: ValueKey((job.status, store.busy)),
                  initialValue: job.status,
                  decoration: localizedDecoration(
                    context,
                    labelText: 'Record status',
                  ),
                  items: JobStatus.values
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: LocalizedText(s.label),
                        ),
                      )
                      .toList(),
                  onChanged: store.busy
                      ? null
                      : (status) async {
                          if (status == null) return;
                          try {
                            await store.updateStatus(id, status);
                            if (context.mounted) {
                              showMessage(context, 'Job status saved.');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              showMessage(context, localError(e));
                            }
                          }
                        },
                ),
                const SizedBox(height: 16),
                const LocalizedText(
                  'Update this record after agreeing with the other person.',
                ),
                const SizedBox(height: 20),
                if (job.notes.isNotEmpty) ...[
                  Text(job.notes),
                  const SizedBox(height: 20),
                ],
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: job.phone.isEmpty
                          ? null
                          : () => ContactActions.call(context, job.phone),
                      icon: const Icon(Icons.call_outlined),
                      label: const LocalizedText('Call'),
                    ),
                    OutlinedButton.icon(
                      onPressed: job.phone.isEmpty
                          ? null
                          : () => ContactActions.sms(
                              context,
                              job.phone,
                              ContactActions.jobText(context, job),
                            ),
                      icon: const Icon(Icons.sms_outlined),
                      label: const LocalizedText('Send SMS'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => ContactActions.shareText(
                        context,
                        ContactActions.jobText(context, job),
                      ),
                      icon: const Icon(Icons.share_outlined),
                      label: const LocalizedText('Share request'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const LocalizedText('Delete job'),
                  onPressed: store.busy
                      ? null
                      : () async {
                          if (!await confirmAction(
                            context,
                            'Delete job?',
                            'This removes the job record from this phone.',
                          )) {
                            return;
                          }
                          try {
                            await store.removeJob(id);
                            if (context.mounted) context.go('/jobs');
                          } catch (e) {
                            if (context.mounted) {
                              showMessage(context, localError(e));
                            }
                          }
                        },
                ),
              ],
            ),
    );
  }
}
