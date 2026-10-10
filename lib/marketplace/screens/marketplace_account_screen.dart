import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../localization/app_language.dart';
import '../../widgets/app_ui.dart';
import '../services/marketplace_controller.dart';
import '../widgets/marketplace_ui.dart';

class MarketplaceAccountScreen extends StatefulWidget {
  const MarketplaceAccountScreen({super.key});

  @override
  State<MarketplaceAccountScreen> createState() =>
      _MarketplaceAccountScreenState();
}

class _MarketplaceAccountScreenState extends State<MarketplaceAccountScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _city = TextEditingController();
  final _neighbourhood = TextEditingController(),
      _whatsapp = TextEditingController();
  String? _loadedUser;
  bool _customer = true, _worker = false;

  @override
  void dispose() {
    for (final field in [_name, _city, _neighbourhood, _whatsapp]) {
      field.dispose();
    }
    super.dispose();
  }

  void _populate(MarketplaceProfile profile) {
    if (_loadedUser == profile.id) return;
    _loadedUser = profile.id;
    _name.text = profile.fullName;
    _city.text = profile.city;
    _neighbourhood.text = profile.neighbourhood;
    _whatsapp.text = profile.whatsapp;
    _customer = profile.isCustomer;
    _worker = profile.isWorker;
    if (!_customer && !_worker) _customer = true;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final controller = context.read<MarketplaceController>();
    final saved = await controller.saveAccount(
      fullName: _name.text.trim(),
      city: _city.text.trim(),
      neighbourhood: _neighbourhood.text.trim(),
      whatsapp: _whatsapp.text.trim(),
      roles: [if (_customer) 'customer', if (_worker) 'worker'],
    );
    if (mounted && saved) {
      showMessage(context, 'Account saved.');
      if (_worker && controller.ownWorker == null) {
        context.go('/marketplace/worker/edit');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MarketplaceController>();
    final profile = controller.profile;
    if (profile != null) _populate(profile);
    return MarketplacePage(
      title: 'My account',
      section: 3,
      child: !controller.isAuthenticated
          ? const MarketplaceSignIn(
              message: 'Sign in to manage your account and job history.',
            )
          : Form(
              key: _form,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (profile?.needsOnboarding ?? true)
                    const MarketplaceNotice(
                      message:
                          'Your phone is verified. Add your name, city and how you want to use Khidmat. '
                          'You can finish your worker profile later.',
                    ),
                  if (profile != null && !profile.isActive)
                    MarketplaceNotice(
                      error: true,
                      message:
                          'Your account is ${profile.status}. Marketplace actions are restricted. '
                          'Contact support if you think this is a mistake.',
                    ),
                  if (controller.error != null)
                    MarketplaceNotice(message: controller.error!, error: true),
                  Center(
                    child: MarketplacePhoto(
                      name: profile?.fullName ?? '',
                      url: profile?.avatarUrl,
                      radius: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      profile?.phone ?? '',
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                  const SizedBox(height: 24),
                  marketplaceField(
                    _name,
                    'Full name',
                    validator: marketplaceRequired,
                  ),
                  marketplaceField(
                    _city,
                    'City',
                    validator: marketplaceRequired,
                    maxLength: 80,
                  ),
                  marketplaceField(
                    _neighbourhood,
                    'Neighbourhood (optional)',
                    maxLength: 100,
                  ),
                  marketplaceField(
                    _whatsapp,
                    'WhatsApp number (if different)',
                    keyboard: TextInputType.phone,
                    validator: (v) => pakistanPhone(v, optional: true),
                    maxLength: 20,
                  ),
                  const MarketplaceHeading(
                    'How will you use Khidmat?',
                    subtitle:
                        'You can request work and offer services with the same account.',
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const LocalizedText('Find workers'),
                    value: _customer,
                    onChanged: (v) => setState(() {
                      _customer = v!;
                      if (!_customer) _worker = true;
                    }),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const LocalizedText('Offer my services'),
                    value: _worker,
                    onChanged: (v) => setState(() {
                      _worker = v!;
                      if (!_worker) _customer = true;
                    }),
                  ),
                  const SizedBox(height: 20),
                  if (controller.busy) const LinearProgressIndicator(),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed:
                        controller.busy ||
                            (profile != null && !profile.isActive)
                        ? null
                        : _save,
                    child: const LocalizedText('Save account'),
                  ),
                  const SizedBox(height: 20),
                  if (profile?.isWorker == true)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.handyman_outlined),
                        title: const LocalizedText('My professional profile'),
                        subtitle: const LocalizedText(
                          'Services, prices, schedule and availability',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/marketplace/worker/edit'),
                      ),
                    ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.work_outline),
                      title: const LocalizedText('My job history'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/marketplace/jobs'),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const LocalizedText('Privacy and account data'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/marketplace/privacy'),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const LocalizedText('Help and safety'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/marketplace/help'),
                    ),
                  ),
                  if (controller.isAdmin)
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.admin_panel_settings_outlined,
                        ),
                        title: const LocalizedText('Administration'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/marketplace/admin'),
                      ),
                    ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: controller.busy
                        ? null
                        : () async {
                            final signedOut = await controller.signOut();
                            if (context.mounted && signedOut) {
                              context.go('/marketplace');
                            }
                          },
                    icon: const Icon(Icons.logout),
                    label: const LocalizedText('Log out'),
                  ),
                ],
              ),
            ),
    );
  }
}
