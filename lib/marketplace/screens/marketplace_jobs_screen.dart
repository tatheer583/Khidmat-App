import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../localization/app_language.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_ui.dart';
import '../services/marketplace_controller.dart';
import '../widgets/marketplace_ui.dart';

class MarketplaceJobsScreen extends StatefulWidget {
  const MarketplaceJobsScreen({super.key});

  @override
  State<MarketplaceJobsScreen> createState() => _MarketplaceJobsScreenState();
}

class _MarketplaceJobsScreenState extends State<MarketplaceJobsScreen> {
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<MarketplaceController>().isAuthenticated) {
        context.read<MarketplaceController>().loadJobs();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MarketplaceController>();
    final jobs = controller.jobs
        .where(
          (job) => switch (_filter) {
            'As customer' => job.customerId == controller.userId,
            'As worker' => job.workerId == controller.userId,
            'Active' => ![
              'completed',
              'cancelled',
              'declined',
            ].contains(job.status),
            'Completed' => job.status == 'completed',
            _ => true,
          },
        )
        .toList();
    return MarketplacePage(
      title: 'My jobs',
      section: 1,
      child: !controller.isAuthenticated
          ? const MarketplaceSignIn(
              message: 'Sign in to see requests, bookings and completed jobs.',
            )
          : RefreshIndicator(
              onRefresh: () async {
                await controller.loadJobs();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  const MarketplaceHeading(
                    'Every job, in one place',
                    subtitle:
                        'Requests are confirmed when the worker accepts. Customers confirm completed work.',
                  ),
                  if (controller.error != null)
                    MarketplaceNotice(message: controller.error!, error: true),
                  if (controller.notice != null)
                    MarketplaceNotice(message: controller.notice!),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final filter in [
                        'All',
                        'Active',
                        'As customer',
                        'As worker',
                        'Completed',
                      ])
                        ChoiceChip(
                          label: LocalizedText(filter),
                          selected: _filter == filter,
                          onSelected: (_) => setState(() => _filter = filter),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (controller.busy) const LinearProgressIndicator(),
                  if (jobs.isEmpty && !controller.busy)
                    EmptyState(
                      title: 'No jobs here yet',
                      message:
                          'Find a worker to request a service, or publish your professional profile to receive work.',
                      icon: Icons.work_outline,
                      action: 'Explore services',
                      onAction: () => context.go('/marketplace'),
                    ),
                  for (final job in jobs) MarketplaceJobCard(job: job),
                  if (controller.canLoadMoreJobs)
                    OutlinedButton(
                      onPressed: controller.busy
                          ? null
                          : () => controller.loadJobs(append: true),
                      child: const LocalizedText('Load more jobs'),
                    ),
                ],
              ),
            ),
    );
  }
}

class MarketplaceJobCard extends StatelessWidget {
  const MarketplaceJobCard({super.key, required this.job});
  final MarketplaceJob job;

  Future<void> _transition(BuildContext context, String status) async {
    final controller = context.read<MarketplaceController>();
    if (['cancelled', 'declined', 'completed'].contains(status)) {
      final confirmed = await confirmAction(
        context,
        status == 'completed'
            ? 'Confirm completed work?'
            : '${jobActionLabel(status)}?',
        status == 'completed'
            ? 'Confirm only after the agreed work has been completed. You can leave a review afterwards.'
            : 'The other participant will be notified of this change.',
        confirm: jobActionLabel(status),
      );
      if (!confirmed || !context.mounted) return;
    }
    await controller.transitionJob(job.id, status);
  }

  Future<void> _review(BuildContext context) async {
    final controller = context.read<MarketplaceController>();
    final comment = TextEditingController();
    var rating = 0;
    var sending = false;
    String? error;
    await showDialog<void>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, update) => AlertDialog(
          title: const LocalizedText('Review this completed job'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LocalizedText('How was the work?'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 2,
                  children: [
                    for (var star = 1; star <= 5; star++)
                      IconButton(
                        tooltip: '$star ${context.tr('stars')}',
                        onPressed: sending
                            ? null
                            : () => update(() => rating = star),
                        icon: Icon(
                          star <= rating ? Icons.star : Icons.star_outline,
                          color: AppColors.warning,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                marketplaceField(
                  comment,
                  'Your review (optional)',
                  lines: 4,
                  maxLength: 1000,
                ),
                const LocalizedText(
                  'Share your experience with the work. Keep phone numbers and private addresses out of your review.',
                ),
                if (error != null)
                  MarketplaceNotice(message: error!, error: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: sending ? null : () => Navigator.pop(dialog),
              child: const LocalizedText('Cancel'),
            ),
            FilledButton(
              onPressed: rating == 0 || sending
                  ? null
                  : () async {
                      update(() => sending = true);
                      final saved = await controller.submitReview(
                        job.id,
                        rating,
                        comment.text.trim(),
                      );
                      if (!dialog.mounted) return;
                      if (saved) {
                        Navigator.pop(dialog);
                      } else {
                        update(() {
                          sending = false;
                          error = controller.error;
                        });
                      }
                    },
              child: LocalizedText(sending ? 'Saving…' : 'Submit review'),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    comment.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MarketplaceController>();
    final customer = controller.userId == job.customerId;
    final otherName = customer ? job.workerName : job.customerName;
    final transitions = job.allowedTransitions(controller.userId);
    return Card(
      child: ExpansionTile(
        key: ValueKey('${job.id}-${job.status}'),
        initiallyExpanded:
            job.status == 'pending' || job.status == 'completion_requested',
        leading: Icon(
          job.status == 'completed' ? Icons.task_alt : Icons.work_outline,
          color: job.status == 'completed'
              ? AppColors.success
              : AppColors.primaryLight,
        ),
        title: Text(
          otherName.isEmpty
              ? context.tr(
                  customer ? 'Your service request' : 'Customer request',
                )
              : otherName,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LocalizedText(jobStatusLabel(job.status)),
            Text(DateFormat.yMMMd().add_jm().format(job.scheduledAt.toLocal())),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.description),
                const SizedBox(height: 12),
                Text(
                  [
                    job.neighbourhood,
                    job.city,
                  ].where((s) => s.isNotEmpty).join(', '),
                ),
                if (job.address.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(job.address),
                  const LocalizedText(
                    'Private job address · shared with participants only',
                  ),
                ],
                const SizedBox(height: 12),
                LocalizedText(
                  job.offeredPrice == null
                      ? 'Price to be agreed'
                      : 'Offered price: PKR ${job.offeredPrice!.toStringAsFixed(0)}',
                ),
                const SizedBox(height: 16),
                if (job.status == 'completion_requested')
                  MarketplaceNotice(
                    message: customer
                        ? 'The worker has requested completion. Confirm the work is done, or return it to in progress.'
                        : 'Waiting for the customer to confirm completion.',
                  ),
                if (controller.profile?.isActive == true)
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      for (final status in transitions)
                        OutlinedButton(
                          onPressed: controller.busy
                              ? null
                              : () => _transition(context, status),
                          child: LocalizedText(jobActionLabel(status)),
                        ),
                      if (job.canReview(controller.userId))
                        FilledButton.icon(
                          onPressed: controller.busy
                              ? null
                              : () => _review(context),
                          icon: const Icon(Icons.star_outline),
                          label: const LocalizedText('Leave a review'),
                        ),
                    ],
                  ),
                if (job.reviewed && customer)
                  const LocalizedText('Your review has been submitted.'),
                if (customer)
                  TextButton(
                    onPressed: () =>
                        context.push('/marketplace/workers/${job.workerId}'),
                    child: const LocalizedText('View worker profile'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String jobStatusLabel(String status) => switch (status) {
  'pending' => 'Awaiting worker response',
  'accepted' => 'Booking confirmed',
  'in_progress' => 'Work in progress',
  'completion_requested' => 'Completion awaiting confirmation',
  'completed' => 'Completed',
  'cancelled' => 'Cancelled',
  'declined' => 'Declined',
  _ => 'Status unavailable',
};

String jobActionLabel(String status) => switch (status) {
  'accepted' => 'Accept request',
  'declined' => 'Decline request',
  'in_progress' => 'Mark in progress',
  'completion_requested' => 'Request completion',
  'completed' => 'Confirm completed',
  'cancelled' => 'Cancel job',
  _ => status,
};
