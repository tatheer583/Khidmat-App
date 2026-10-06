import '../localization/app_language.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/backend_session.dart';
import '../widgets/live_ui.dart';

const serviceCategories = [
  'AC Technician',
  'Plumber',
  'Electrician',
  'Tutor',
  'Beautician',
  'Carpenter',
  'Painter',
  'Deep Cleaning',
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _query = TextEditingController();
  final _city = TextEditingController(text: 'Islamabad');
  bool _initialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final city = context.watch<BackendSession>().profile?['city'] as String?;
    if (!_initialized && city != null && city.isNotEmpty) {
      _city.text = city;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _query.dispose();
    _city.dispose();
    super.dispose();
  }

  void _search([String? category]) {
    final query = category ?? _query.text.trim();
    if (query.isEmpty || _city.text.trim().isEmpty) {
      showMessage(context, 'Enter your city and the service you need.');
      return;
    }
    FocusScope.of(context).unfocus();
    unawaited(context.read<AppState>().startPipeline(query, city: _city.text));
    context.push('/providers');
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<BackendSession>();
    return Scaffold(
      appBar: AppBar(
        title: const LocalizedText('Work giver dashboard'),
        actions: [
          const LanguageButton(),
          IconButton(
            tooltip: context.tr('My bookings'),
            icon: const Icon(Icons.receipt_long),
            onPressed: () => context.push('/bookings'),
          ),
          IconButton(
            tooltip: context.tr('My account'),
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/account'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          LocalizedText(
            'Assalamu Alaikum, ${session.displayName}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          LocalizedText(
            'What can we help with?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const LocalizedText(
            'Describe your request in English, Urdu or Roman Urdu.',
          ),
          if (session.error != null)
            Notice(session.error!, retry: session.refreshProfile),
          const SizedBox(height: 24),
          TextField(
            controller: _city,
            maxLength: 80,
            decoration: localizedDecoration(
              context,
              labelText: 'Your city',
              prefixIcon: Icon(Icons.location_city),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _query,
            maxLength: 500,
            maxLines: 3,
            decoration: localizedDecoration(
              context,
              labelText: 'What service do you need?',
              hintText: 'Plumber chahiye, pipe leak ho raha hai',
            ),
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _search(),
            icon: const Icon(Icons.search),
            label: const LocalizedText('Find available providers'),
          ),
          const SizedBox(height: 32),
          LocalizedText(
            'Quick services',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: serviceCategories
                .map(
                  (category) => ActionChip(
                    label: LocalizedText(category),
                    onPressed: () => _search(category),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 32),
          Card(
            child: ListTile(
              leading: const Icon(Icons.work_outline),
              title: const LocalizedText('Profile details'),
              subtitle: const LocalizedText(
                'Edit your profile or change your account type.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/profile/edit'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.history),
              title: const LocalizedText('My bookings and jobs'),
              subtitle: const LocalizedText(
                'Status updates and conversations.',
              ),
              onTap: () => context.push('/bookings'),
            ),
          ),
        ],
      ),
    );
  }
}
