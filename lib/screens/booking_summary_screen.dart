import '../localization/app_language.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/live_booking.dart';
import '../services/backend_session.dart';
import '../services/khidmat_repository.dart';
import '../widgets/live_ui.dart';

class BookingSummaryScreen extends StatefulWidget {
  final String bookingId;
  const BookingSummaryScreen({super.key, required this.bookingId});
  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  late Stream<List<Map<String, dynamic>>> _booking;
  late Stream<List<Map<String, dynamic>>> _events;
  bool _busy = false;
  KhidmatRepository get _repo =>
      KhidmatRepository(context.read<BackendSession>().client);
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(BookingSummaryScreen old) {
    super.didUpdateWidget(old);
    if (old.bookingId != widget.bookingId) _load();
  }

  void _load() {
    _booking = _repo.watchBooking(widget.bookingId);
    _events = _repo.events(widget.bookingId);
  }

  Future<void> _transition(String status) async {
    if (_busy) return;
    if (status == 'cancelled' || status == 'declined') {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: LocalizedText(
            status == 'cancelled' ? 'Cancel booking?' : 'Decline this job?',
          ),
          content: const LocalizedText(
            'The other person will see this change immediately.',
          ),
          actions: [
            const LanguageButton(),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const LocalizedText('Keep booking'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const LocalizedText('Confirm'),
            ),
          ],
        ),
      );
      if (accepted != true || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      await _repo.transition(widget.bookingId, status);
    } catch (e) {
      if (mounted) showMessage(context, describeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _review(LiveBooking booking) async {
    if (_busy) return;
    final comment = TextEditingController();
    int stars = 5;
    final submit = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: const LocalizedText('Rate this service'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                value: stars,
                items: List.generate(
                  5,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: LocalizedText('${i + 1} stars'),
                  ),
                ),
                onChanged: (v) => update(() => stars = v!),
              ),
              TextField(
                controller: comment,
                maxLength: 1000,
                maxLines: 3,
                decoration: localizedDecoration(
                  context,
                  labelText: 'Your feedback',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const LocalizedText('Close'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const LocalizedText('Submit'),
            ),
          ],
        ),
      ),
    );
    final text = comment.text;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    comment.dispose();
    if (submit != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _repo.review(booking, stars, text);
      if (mounted) showMessage(context, 'Thank you for your review.');
    } catch (e) {
      if (mounted) showMessage(context, describeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const LocalizedText('Booking details'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/bookings'),
      ),
      actions: [
        IconButton(
          tooltip: context.tr('Refresh'),
          onPressed: () => setState(_load),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: StreamBuilder<List<Map<String, dynamic>>>(
      stream: _booking,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Notice(
              describeError(snapshot.error!),
              retry: () => setState(_load),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.isEmpty) {
          return const Center(child: Notice('Booking not found.'));
        }
        final booking = LiveBooking(snapshot.data!.first);
        final provider =
            context.read<BackendSession>().user!.id == booking.providerUserId;
        final phone = booking.provider['phone'] as String? ?? '';
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            LocalizedText(
              booking.statusLabel,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            LocalizedText(
              'Reference: ${booking.id}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            LocalizedText(
              booking.service,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            LocalizedText('Provider: ${booking.providerName}'),
            const SizedBox(height: 12),
            LocalizedText('${booking.date} • ${booking.slot} (Pakistan time)'),
            LocalizedText('Rs. ${booking.price} • Cash after service'),
            const SizedBox(height: 12),
            LocalizedText(booking.address, translate: false),
            if (booking.notes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: LocalizedText(booking.notes, translate: false),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/booking/${booking.id}/chat'),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const LocalizedText('Open conversation'),
            ),
            if (!provider && phone.isNotEmpty)
              TextButton.icon(
                onPressed: () async {
                  try {
                    final opened = await launchUrl(
                      Uri(scheme: 'tel', path: phone),
                    );
                    if (!opened && context.mounted) {
                      showMessage(context, 'Could not open the dialer.');
                    }
                  } catch (_) {
                    if (context.mounted) {
                      showMessage(context, 'Could not open the dialer.');
                    }
                  }
                },
                icon: const Icon(Icons.phone_outlined),
                label: const LocalizedText('Call provider'),
              ),
            if (provider && booking.status == 'pending') ...[
              ElevatedButton(
                onPressed: _busy ? null : () => _transition('accepted'),
                child: const LocalizedText('Accept job'),
              ),
              TextButton(
                onPressed: _busy ? null : () => _transition('declined'),
                child: const LocalizedText('Decline'),
              ),
            ],
            if (provider && booking.status == 'accepted')
              ElevatedButton(
                onPressed: _busy ? null : () => _transition('on_the_way'),
                child: const LocalizedText('Mark on the way'),
              ),
            if (provider && ['accepted', 'on_the_way'].contains(booking.status))
              ElevatedButton(
                onPressed: _busy ? null : () => _transition('in_progress'),
                child: const LocalizedText('Start service'),
              ),
            if (provider && booking.status == 'in_progress')
              ElevatedButton(
                onPressed: _busy ? null : () => _transition('completed'),
                child: const LocalizedText('Mark completed'),
              ),
            if (!provider && booking.canCancel)
              TextButton(
                onPressed: _busy ? null : () => _transition('cancelled'),
                child: const LocalizedText('Cancel booking'),
              ),
            if (!provider && booking.status == 'completed')
              OutlinedButton(
                onPressed: _busy ? null : () => _review(booking),
                child: const LocalizedText('Leave a verified review'),
              ),
            if (_busy) const LinearProgressIndicator(),
            const SizedBox(height: 24),
            LocalizedText(
              'Activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _events,
              builder: (ctx, events) {
                if (events.hasError) {
                  return Notice(describeError(events.error!));
                }
                if (!events.hasData) return const LinearProgressIndicator();
                return Column(
                  children: events.data!
                      .map(
                        (event) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.check_circle_outline),
                          title: LocalizedText(
                            (event['status'] as String).replaceAll('_', ' '),
                          ),
                          subtitle: LocalizedText(
                            DateTime.parse(
                              event['created_at'] as String,
                            ).toLocal().toString(),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        );
      },
    ),
  );
}
