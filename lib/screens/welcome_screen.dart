import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../localization/app_language.dart';
import '../widgets/app_ui.dart';
import '../widgets/khidmat_brand.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Khidmat',
    navigation: false,
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: KhidmatBrandMark(size: 88)),
              const SizedBox(height: 24),
              Text(
                'Khidmat · خدمت',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              const LocalizedText(
                'Trusted local help, in your language.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: () => context.go('/marketplace'),
                icon: const Icon(Icons.travel_explore),
                label: const LocalizedText('Find local workers'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.push('/profile/create'),
                child: const LocalizedText('Get started'),
              ),
              const SizedBox(height: 20),
              const InfoCard(
                'Keep worker contacts, plan service appointments and manage your jobs.',
                icon: Icons.handyman_outlined,
              ),
              const SizedBox(height: 8),
              const InfoCard(
                'Your records stay on this phone. Call, send SMS or share a request to agree on work.',
                icon: Icons.phone_android,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => context.push('/backup'),
                child: const LocalizedText('Restore backup'),
              ),
              TextButton(
                onPressed: () => context.push('/help'),
                child: const LocalizedText('How Khidmat works'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
