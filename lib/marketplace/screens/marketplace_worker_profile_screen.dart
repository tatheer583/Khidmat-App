import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../localization/app_language.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_ui.dart';
import '../../services/contact_actions.dart';
import '../services/marketplace_controller.dart';
import '../widgets/marketplace_ui.dart';

class MarketplaceWorkerProfileScreen extends StatefulWidget {
  const MarketplaceWorkerProfileScreen({super.key, required this.id});
  final String id;

  @override
  State<MarketplaceWorkerProfileScreen> createState() =>
      _MarketplaceWorkerProfileScreenState();
}

class _MarketplaceWorkerProfileScreenState
    extends State<MarketplaceWorkerProfileScreen> {
  late Future<MarketplaceWorker?> _worker;

  @override
  void initState() {
    super.initState();
    final controller = context.read<MarketplaceController>();
    _worker = Future<MarketplaceWorker?>.microtask(
      () => mounted ? controller.loadWorker(widget.id) : null,
    );
  }

  Future<void> _refresh() async {
    final next = context.read<MarketplaceController>().loadWorker(widget.id);
    setState(() => _worker = next);
    await next;
  }

  Future<void> _contact(bool whatsapp, {bool sms = false}) async {
    final controller = context.read<MarketplaceController>();
    if (!controller.isAuthenticated) {
      context.push('/marketplace/auth');
      return;
    }
    final details = await controller.requestContact(widget.id);
    if (details == null || !mounted) return;
    final phone = whatsapp && details.whatsapp.isNotEmpty
        ? details.whatsapp
        : details.phone;
    if (!isPakistaniPhone(phone)) {
      showMessage(context, 'A valid contact number is not available.');
      return;
    }
    final normalized = normalizePakistaniPhone(phone);
    if (sms) {
      await ContactActions.sms(
        context,
        normalized,
        context.tr('Hello, I found your services on Khidmat.'),
      );
      return;
    }
    final uri = whatsapp
        ? Uri.https('wa.me', normalized.substring(1), {
            'text': 'Assalam-o-Alaikum, I found your services on Khidmat.',
          })
        : Uri(scheme: 'tel', path: normalized);
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        showMessage(context, 'No compatible app is available on this device.');
      }
    } catch (_) {
      if (mounted) showMessage(context, 'The contact app could not be opened.');
    }
  }

  Future<void> _request(MarketplaceWorker worker) async {
    final controller = context.read<MarketplaceController>();
    if (!controller.isAuthenticated) {
      context.push('/marketplace/auth');
      return;
    }
    if (controller.profile?.isActive != true ||
        controller.profile?.isCustomer != true) {
      showMessage(
        context,
        'Complete an active customer profile before requesting work.',
      );
      context.push('/marketplace/account');
      return;
    }
    final form = GlobalKey<FormState>();
    final description = TextEditingController();
    final city = TextEditingController(
      text: controller.profile?.city ?? worker.city,
    );
    final neighbourhood = TextEditingController(
      text: controller.profile?.neighbourhood ?? '',
    );
    final address = TextEditingController();
    final price = TextEditingController();
    var scheduled = DateTime.now().add(const Duration(hours: 2));
    var submitting = false;
    String? error;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, update) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            24 + MediaQuery.viewInsetsOf(sheet).bottom,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  MarketplaceHeading('Request work', subtitle: worker.name),
                  const MarketplaceNotice(
                    message:
                        'A request is confirmed when the worker accepts. '
                        'Agree on the final scope, price and materials before work begins.',
                  ),
                  if (error != null)
                    MarketplaceNotice(message: error!, error: true),
                  marketplaceField(
                    description,
                    'Describe the work',
                    lines: 4,
                    maxLength: 2000,
                    validator: (v) => (v?.trim().length ?? 0) < 10
                        ? context.tr(
                            'Describe the work in at least 10 characters.',
                          )
                        : null,
                  ),
                  marketplaceField(
                    city,
                    'City',
                    validator: marketplaceRequired,
                    maxLength: 80,
                  ),
                  marketplaceField(
                    neighbourhood,
                    'Neighbourhood',
                    maxLength: 120,
                  ),
                  marketplaceField(
                    address,
                    'Work address (private)',
                    maxLength: 300,
                    hint: 'Shared only with this job’s participants',
                  ),
                  marketplaceField(
                    price,
                    'Your offered price (PKR, optional)',
                    keyboard: TextInputType.number,
                    validator: (v) =>
                        v!.trim().isEmpty ? null : nonNegativeNumber(v),
                    maxLength: 8,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    title: Text(DateFormat.yMMMd().add_jm().format(scheduled)),
                    subtitle: const LocalizedText('Requested date and time'),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: submitting
                        ? null
                        : () async {
                            final date = await showDatePicker(
                              context: sheet,
                              initialDate: scheduled,
                              firstDate: DateUtils.dateOnly(DateTime.now()),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date == null || !sheet.mounted) return;
                            final time = await showTimePicker(
                              context: sheet,
                              initialTime: TimeOfDay.fromDateTime(scheduled),
                            );
                            if (time != null && sheet.mounted) {
                              update(() {
                                scheduled = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            }
                          },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: submitting
                        ? null
                        : () async {
                            if (!form.currentState!.validate()) return;
                            if (!scheduled.isAfter(DateTime.now())) {
                              update(
                                () => error = context.tr(
                                  'Choose a future date and time.',
                                ),
                              );
                              return;
                            }
                            update(() {
                              submitting = true;
                              error = null;
                            });
                            final saved = await controller.requestJob(
                              workerId: worker.id,
                              description: description.text.trim(),
                              scheduledAt: scheduled,
                              city: city.text.trim(),
                              neighbourhood: neighbourhood.text.trim(),
                              address: address.text.trim(),
                              offeredPrice: double.tryParse(price.text.trim()),
                            );
                            if (!sheet.mounted) return;
                            if (saved) {
                              Navigator.pop(sheet);
                              if (mounted) {
                                showMessage(context, 'Job request sent.');
                                context.go('/marketplace/jobs');
                              }
                            } else {
                              update(() {
                                submitting = false;
                                error =
                                    controller.error ??
                                    'The request could not be sent. Please try again.';
                              });
                            }
                          },
                    child: LocalizedText(
                      submitting ? 'Sending request…' : 'Send job request',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    for (final field in [description, city, neighbourhood, address, price]) {
      field.dispose();
    }
  }

  Future<void> _report() async {
    final controller = context.read<MarketplaceController>();
    if (!controller.isAuthenticated) {
      context.push('/marketplace/auth');
      return;
    }
    final details = TextEditingController();
    final form = GlobalKey<FormState>();
    var reason = 'other';
    var sending = false;
    String? error;
    await showDialog<void>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, update) => AlertDialog(
          title: const LocalizedText('Report this profile'),
          content: SingleChildScrollView(
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (error != null)
                    MarketplaceNotice(message: error!, error: true),
                  DropdownButtonFormField<String>(
                    initialValue: reason,
                    isExpanded: true,
                    decoration: localizedDecoration(
                      context,
                      labelText: 'Reason',
                    ),
                    items:
                        [
                              'safety',
                              'fraud',
                              'harassment',
                              'inappropriate_profile',
                              'other',
                            ]
                            .map(
                              (r) => DropdownMenuItem(
                                value: r,
                                child: LocalizedText(reportReasonLabel(r)),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => update(() => reason = v!),
                  ),
                  const SizedBox(height: 16),
                  marketplaceField(
                    details,
                    'What happened?',
                    lines: 4,
                    maxLength: 2000,
                    validator: (v) => (v?.trim().length ?? 0) < 10
                        ? context.tr('Add at least 10 characters.')
                        : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: sending ? null : () => Navigator.pop(dialog),
              child: const LocalizedText('Cancel'),
            ),
            FilledButton(
              onPressed: sending
                  ? null
                  : () async {
                      if (!form.currentState!.validate()) return;
                      update(() => sending = true);
                      final sent = await controller.reportAccount(
                        widget.id,
                        reason,
                        details.text.trim(),
                      );
                      if (!dialog.mounted) return;
                      if (sent) {
                        Navigator.pop(dialog);
                        if (mounted) {
                          showMessage(context, 'Report submitted for review.');
                        }
                      } else {
                        update(() {
                          sending = false;
                          error = controller.error;
                        });
                      }
                    },
              child: LocalizedText(sending ? 'Submitting…' : 'Submit report'),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    details.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MarketplaceController>();
    return MarketplacePage(
      title: 'Worker profile',
      navigation: false,
      actions: [
        IconButton(
          tooltip: context.tr('Refresh profile'),
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
      child: FutureBuilder<MarketplaceWorker?>(
        future: _worker,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final worker = snapshot.data;
          if (worker == null) {
            return EmptyState(
              title: 'Profile unavailable',
              message:
                  controller.error ??
                  'This worker is no longer discoverable. Try another worker.',
              action: 'Try again',
              onAction: _refresh,
            );
          }
          final availability = worker.currentAvailability;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                if (controller.error != null)
                  MarketplaceNotice(message: controller.error!, error: true),
                Center(
                  child: MarketplacePhoto(
                    name: worker.name,
                    url: worker.avatarUrl,
                    radius: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  worker.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                LocalizedText(
                  worker.professionName,
                  textAlign: TextAlign.center,
                ),
                if (worker.verified)
                  const Center(
                    child: Chip(
                      avatar: Icon(Icons.verified_outlined, size: 18),
                      label: LocalizedText('Worker check completed'),
                    ),
                  ),
                const SizedBox(height: 12),
                Center(
                  child: Chip(
                    label: LocalizedText(availability.label),
                    avatar: Icon(
                      Icons.circle,
                      size: 12,
                      color: availability == WorkerAvailability.availableNow
                          ? AppColors.success
                          : AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.location_on_outlined),
                        title: Text(worker.serviceArea),
                        subtitle: LocalizedText(
                          worker.currentDistanceKm == null
                              ? 'Service area only · distance unavailable'
                              : 'About ${worker.currentDistanceKm!.toStringAsFixed(1)} km away',
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.history),
                        title: LocalizedText(
                          '${worker.experienceYears} years experience',
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.payments_outlined),
                        title: LocalizedText(
                          worker.rate > 0
                              ? 'From PKR ${worker.rate.toStringAsFixed(0)} / ${context.tr(worker.priceUnit)}'
                              : 'Price by agreement',
                        ),
                        subtitle: const LocalizedText(
                          'Confirm the final scope and price before work begins.',
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.star_outline),
                        title: LocalizedText(
                          worker.reviewCount == 0
                              ? 'No reviews yet'
                              : '${worker.rating.toStringAsFixed(1)} from ${worker.reviewCount} reviews',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const MarketplaceHeading('About this worker'),
                Text(
                  worker.description.isEmpty
                      ? context.tr('No description provided.')
                      : worker.description,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: worker.skills
                      .map((s) => Chip(label: LocalizedText(s)))
                      .toList(),
                ),
                if (worker.languages.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  LocalizedText('Languages: ${worker.languages.join(', ')}'),
                ],
                if (worker.workingDays.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  LocalizedText(
                    'Working hours: ${worker.startTime} – ${worker.endTime}',
                  ),
                  LocalizedText(
                    worker.workingDays
                        .where((d) => d >= 1 && d <= 7)
                        .map(
                          (d) => context.tr(
                            [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun',
                            ][d - 1],
                          ),
                        )
                        .join(', '),
                  ),
                ],
                if (worker.portfolioUrls.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const MarketplaceHeading('Previous work'),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: worker.portfolioUrls
                        .where(isSafeMarketplaceImage)
                        .map(
                          (url) => SizedBox(
                            width: 140,
                            height: 140,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 24),
                if (controller.userId != worker.id) ...[
                  FilledButton.icon(
                    onPressed:
                        controller.busy ||
                            ![
                              WorkerAvailability.availableNow,
                              WorkerAvailability.availableLater,
                            ].contains(availability)
                        ? null
                        : () => _request(worker),
                    icon: const Icon(Icons.work_outline),
                    label: const LocalizedText('Request work'),
                  ),
                  if (![
                    WorkerAvailability.availableNow,
                    WorkerAvailability.availableLater,
                  ].contains(availability))
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: LocalizedText(
                        'This worker is not currently accepting requests. Check back later.',
                      ),
                    ),
                  if (worker.shareContact) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton.icon(
                          onPressed: controller.busy
                              ? null
                              : () => _contact(false),
                          icon: const Icon(Icons.call_outlined),
                          label: const LocalizedText('Call'),
                        ),
                        OutlinedButton.icon(
                          onPressed: controller.busy
                              ? null
                              : () => _contact(true),
                          icon: const Icon(Icons.chat_outlined),
                          label: const LocalizedText('WhatsApp'),
                        ),
                        OutlinedButton.icon(
                          onPressed: controller.busy
                              ? null
                              : () => _contact(false, sms: true),
                          icon: const Icon(Icons.sms_outlined),
                          label: const LocalizedText('Send SMS'),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: controller.busy ? null : _report,
                    icon: const Icon(Icons.flag_outlined),
                    label: const LocalizedText('Report profile'),
                  ),
                ],
                const SizedBox(height: 24),
                const MarketplaceHeading('Reviews from completed jobs'),
                if (worker.reviews.isEmpty)
                  const LocalizedText(
                    'This worker has no published reviews yet.',
                  ),
                for (final review in worker.reviews)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '★' * review.rating.clamp(0, 5),
                            style: const TextStyle(color: AppColors.warning),
                          ),
                          if (review.comment.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(review.comment),
                          ],
                          if (review.createdAt != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              DateFormat.yMMMd().format(
                                review.createdAt!.toLocal(),
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                const MarketplaceNotice(
                  message:
                      'Availability can change. A profile or phone call does not guarantee a booking. '
                      'Never share verification codes or pay an unexpected advance to an unverified person.',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

String reportReasonLabel(String reason) => switch (reason) {
  'safety' => 'Safety concern',
  'fraud' => 'Fraud or scam',
  'harassment' => 'Harassment',
  'inappropriate_profile' => 'Inappropriate profile',
  _ => 'Other',
};
