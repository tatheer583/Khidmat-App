import '../localization/app_language.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/live_ui.dart';

class ProviderListScreen extends StatelessWidget {
  const ProviderListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final providers = state.rankedProviders;
    return Scaffold(
      appBar: AppBar(
        title: LocalizedText('Providers in ${state.searchCity}'),
        actions: [
          const LanguageButton(),
          IconButton(
            tooltip: context.tr('Activity log'),
            icon: const Icon(Icons.timeline),
            onPressed: () => context.push('/logs'),
          ),
        ],
      ),
      body: state.isProcessing && providers == null
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
          ? Center(
              child: Notice(
                state.error!,
                retry: () {
                  unawaited(
                    state.startPipeline(
                      state.currentQuery ?? '',
                      city: state.searchCity,
                    ),
                  );
                },
              ),
            )
          : providers == null || providers.isEmpty
          ? const Center(
              child: Notice(
                'No approved providers are available for this service '
                'in your city yet. Try another service or city.',
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: providers.length,
              itemBuilder: (context, index) {
                final report = providers[index];
                final p = report.provider;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (p.avatar != null)
                              SizedBox(
                                width: 52,
                                height: 52,
                                child: StoredImage(
                                  bucket: 'avatars',
                                  path: p.avatar!,
                                  height: 52,
                                ),
                              )
                            else
                              const CircleAvatar(
                                child: Icon(Icons.person_outline),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LocalizedText(
                                    p.name,
                                    translate: false,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  LocalizedText(
                                    '${context.tr(p.category)} • ${p.location}',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        LocalizedText(
                          p.reviewCount > 0
                              ? '${p.rating.toStringAsFixed(1)} ★ • ${p.reviewCount} verified reviews • ${p.completedJobs} completed jobs'
                              : 'New provider • No reviews yet',
                        ),
                        const SizedBox(height: 10),
                        LocalizedText('Booking rate: Rs. ${p.priceMin}'),
                        const SizedBox(height: 6),
                        LocalizedText(
                          'Available times: ${p.availableSlots.join(', ')}',
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          child: Column(
                            children: [
                              LocalizedText(
                                '${p.experienceYears} years of experience',
                              ),
                              TextButton(
                                onPressed: () =>
                                    context.push('/worker/${p.id}'),
                                child: const LocalizedText(
                                  'View worker profile',
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: state.isProcessing
                                ? null
                                : () {
                                    unawaited(state.startNegotiation(report));
                                    context.push('/negotiation');
                                  },
                            child: const LocalizedText('View quote & book'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
