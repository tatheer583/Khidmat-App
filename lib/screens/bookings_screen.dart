import '../localization/app_language.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/live_booking.dart';
import '../services/backend_session.dart';
import '../services/khidmat_repository.dart';
import '../widgets/live_ui.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});
  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  late Stream<List<Map<String, dynamic>>> _stream;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _stream = KhidmatRepository(
      context.read<BackendSession>().client,
    ).bookings();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const LocalizedText('Bookings & jobs'),
      actions: [
        const LanguageButton(),
        IconButton(
          tooltip: context.tr('Refresh'),
          onPressed: () => setState(_load),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: StreamBuilder<List<Map<String, dynamic>>>(
      stream: _stream,
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
        final rows = snapshot.data!;
        if (rows.isEmpty) {
          return const Center(
            child: Notice('Your bookings and provider jobs will appear here.'),
          );
        }
        final userId = context.read<BackendSession>().user!.id;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final booking = LiveBooking(rows[index]);
            final isProvider = booking.providerUserId == userId;
            return Card(
              child: ListTile(
                leading: Icon(
                  isProvider ? Icons.work_outline : Icons.receipt_long,
                ),
                title: LocalizedText(
                  '${context.tr(booking.service)} • ${context.tr(booking.statusLabel)}',
                ),
                subtitle: LocalizedText(
                  '${isProvider ? context.tr('Your job') : booking.providerName}\n${context.tr('${booking.date} at ${booking.slot} • Rs. ${booking.price}')}',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/booking/${booking.id}'),
              ),
            );
          },
        );
      },
    ),
  );
}
