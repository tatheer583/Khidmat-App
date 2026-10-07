import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../localization/app_language.dart';
import '../services/local_store.dart';
import '../services/contact_actions.dart';
import '../widgets/app_ui.dart';

class WorkerProfileScreen extends StatelessWidget {
  const WorkerProfileScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<LocalStore>();
    final worker = store.worker(id);
    return AppPage(
      title: 'Worker details',
      section: 1,
      actions: [
        if (worker != null)
          IconButton(
            tooltip: context.tr('Edit worker'),
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/contacts/$id/edit'),
          ),
      ],
      child: worker == null
          ? const EmptyState(
              title: 'Contact not found',
              message: 'This worker contact was removed.',
            )
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(child: PersonAvatar(worker.name, radius: 44)),
                const SizedBox(height: 20),
                Text(
                  worker.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                LocalizedText(worker.category, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.location_on_outlined),
                        title: Text(worker.city),
                      ),
                      ListTile(
                        leading: const Icon(Icons.call_outlined),
                        title: Text(worker.phone),
                      ),
                      ListTile(
                        leading: const Icon(Icons.history),
                        title: LocalizedText(
                          '${worker.experienceYears} years of experience',
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.payments_outlined),
                        title: LocalizedText(
                          worker.rate == 0
                              ? 'Price to be agreed'
                              : 'Rs. ${worker.rate}',
                        ),
                        subtitle: const LocalizedText('Starting rate'),
                      ),
                    ],
                  ),
                ),
                if (worker.details.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(worker.details),
                  ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () =>
                          ContactActions.call(context, worker.phone),
                      icon: const Icon(Icons.call_outlined),
                      label: const LocalizedText('Call'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => ContactActions.sms(
                        context,
                        worker.phone,
                        context.tr(
                          'Hello, I would like to ask about your services.',
                        ),
                      ),
                      icon: const Icon(Icons.sms_outlined),
                      label: const LocalizedText('Send SMS'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => ContactActions.shareText(
                        context,
                        ContactActions.workerText(context, worker),
                      ),
                      icon: const Icon(Icons.share_outlined),
                      label: const LocalizedText('Share worker'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => context.push('/jobs/new?worker=$id'),
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: const LocalizedText('Plan an appointment'),
                ),
                TextButton.icon(
                  onPressed: store.busy
                      ? null
                      : () async {
                          try {
                            await store.saveWorker(
                              worker.withFavorite(!worker.favorite),
                            );
                          } catch (e) {
                            if (context.mounted) {
                              showMessage(context, localError(e));
                            }
                          }
                        },
                  icon: Icon(
                    worker.favorite ? Icons.favorite : Icons.favorite_border,
                  ),
                  label: LocalizedText(
                    worker.favorite
                        ? 'Remove from favorites'
                        : 'Add to favorites',
                  ),
                ),
                const SizedBox(height: 20),
                const InfoCard(
                  'Confirm the worker’s availability and final price directly before the appointment.',
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const LocalizedText('Delete contact'),
                  onPressed: store.busy
                      ? null
                      : () async {
                          if (!await confirmAction(
                            context,
                            'Delete contact?',
                            'The contact will be removed. Your existing job records will stay.',
                          )) {
                            return;
                          }
                          try {
                            await store.removeWorker(id);
                            if (context.mounted) context.go('/contacts');
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
