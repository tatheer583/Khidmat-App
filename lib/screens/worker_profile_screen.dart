import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../agents/bharosa_agent.dart';
import '../localization/app_language.dart';
import '../models/provider_model.dart';
import '../services/app_state.dart';
import '../services/backend_session.dart';
import '../widgets/live_ui.dart';

class WorkerProfileScreen extends StatefulWidget {
  final String providerId;
  const WorkerProfileScreen({super.key, required this.providerId});
  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  late Future<Map<String, dynamic>> _profile;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(WorkerProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.providerId != widget.providerId) _load();
  }

  void _load() {
    _profile = context
        .read<BackendSession>()
        .client
        .from('providers')
        .select()
        .eq('id', widget.providerId)
        .single();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const LocalizedText('Worker profile'),
      actions: const [LanguageButton()],
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Notice(
            describeError(snapshot.error!),
            retry: () => setState(_load),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final worker = ServiceProvider.fromJson(snapshot.data!);
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (worker.avatar != null)
              StoredImage(bucket: 'avatars', path: worker.avatar!, height: 160),
            const SizedBox(height: 20),
            LocalizedText(
              worker.name,
              translate: false,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            LocalizedText(worker.category),
            LocalizedText(worker.location, translate: false),
            const SizedBox(height: 16),
            LocalizedText('${worker.experienceYears} years of experience'),
            const SizedBox(height: 16),
            LocalizedText(worker.description, translate: false),
            const SizedBox(height: 20),
            LocalizedText(
              worker.reviewCount == 0
                  ? 'New provider • No reviews yet'
                  : '${worker.rating.toStringAsFixed(1)} ★ • ${worker.reviewCount} verified reviews • ${worker.completedJobs} completed jobs',
            ),
            LocalizedText('Booking rate: Rs. ${worker.priceMin}'),
            LocalizedText(
              'Available times: ${worker.availableSlots.join(', ')}',
            ),
            const SizedBox(height: 24),
            if (worker.ownerId != context.read<BackendSession>().user?.id)
              ElevatedButton(
                onPressed:
                    worker.availableSlots.isEmpty ||
                        snapshot.data!['is_available'] != true
                    ? null
                    : () {
                        unawaited(
                          context.read<AppState>().startNegotiation(
                            BharosaAgent.evaluate(worker),
                          ),
                        );
                        context.push('/negotiation');
                      },
                child: const LocalizedText('View quote & book'),
              ),
          ],
        );
      },
    ),
  );
}
