import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../localization/app_language.dart';
import '../services/marketplace_controller.dart';
import '../widgets/marketplace_ui.dart';

class MarketplaceAuthScreen extends StatefulWidget {
  const MarketplaceAuthScreen({super.key});

  @override
  State<MarketplaceAuthScreen> createState() => _MarketplaceAuthScreenState();
}

class _MarketplaceAuthScreenState extends State<MarketplaceAuthScreen> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _code = TextEditingController();
  bool _sent = false;
  int _seconds = 0;
  Timer? _cooldown;

  @override
  void dispose() {
    _cooldown?.cancel();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (pakistanPhone(_phone.text) != null) {
      _form.currentState!.validate();
      return;
    }
    final sent = await context.read<MarketplaceController>().requestOtp(
      _phone.text,
    );
    if (!mounted || !sent) return;
    setState(() {
      _sent = true;
      _seconds = 60;
    });
    _cooldown?.cancel();
    _cooldown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _seconds--);
      if (_seconds <= 0) timer.cancel();
    });
  }

  Future<void> _verify() async {
    if (!_form.currentState!.validate()) return;
    final controller = context.read<MarketplaceController>();
    final verified = await controller.verifyOtp(_phone.text, _code.text.trim());
    if (mounted && verified) {
      context.go(
        controller.profile?.needsOnboarding != false
            ? '/marketplace/account'
            : '/marketplace',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MarketplaceController>();
    return MarketplacePage(
      title: 'Welcome to Khidmat',
      navigation: false,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: _form,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: SizedBox(
                      height: 180,
                      child: const MarketplaceAsset(
                        asset: 'assets/images/khidmat-team-hero.png',
                        label: 'Khidmat service professionals',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  LocalizedText(
                    _sent ? 'Check your messages' : 'Good help starts here',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const LocalizedText(
                    'Use your Pakistani mobile number to create an account or sign in. '
                    'We verify it with a code sent by SMS.',
                  ),
                  const SizedBox(height: 24),
                  if (!controller.configured)
                    const MarketplaceNotice(
                      message:
                          'Phone sign-in will be available after the marketplace is connected. '
                          'Your saved phone records remain available.',
                    ),
                  if (controller.error != null)
                    MarketplaceNotice(message: controller.error!, error: true),
                  TextFormField(
                    controller: _phone,
                    enabled: !_sent && !controller.busy,
                    decoration: localizedDecoration(
                      context,
                      labelText: 'Pakistani mobile number',
                      hintText: '0300 1234567',
                    ),
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    validator: pakistanPhone,
                    maxLength: 20,
                  ),
                  if (_sent) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _code,
                      decoration: localizedDecoration(
                        context,
                        labelText: 'Verification code',
                      ),
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      maxLength: 6,
                      validator: (value) =>
                          RegExp(r'^\d{6}$').hasMatch(value?.trim() ?? '')
                          ? null
                          : context.tr('Enter the 6-digit code from your SMS.'),
                      onFieldSubmitted: (_) =>
                          controller.busy ? null : _verify(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (controller.busy) const LinearProgressIndicator(),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: !controller.configured || controller.busy
                        ? null
                        : (_sent ? _verify : _send),
                    child: LocalizedText(
                      _sent ? 'Verify and continue' : 'Send verification code',
                    ),
                  ),
                  if (_sent) ...[
                    TextButton(
                      onPressed: _seconds > 0 || controller.busy
                          ? null
                          : () async {
                              _code.clear();
                              await _send();
                            },
                      child: LocalizedText(
                        _seconds > 0
                            ? 'Resend code in $_seconds seconds'
                            : 'Resend code',
                      ),
                    ),
                    TextButton(
                      onPressed: controller.busy
                          ? null
                          : () {
                              _cooldown?.cancel();
                              setState(() {
                                _sent = false;
                                _seconds = 0;
                              });
                              _code.clear();
                            },
                      child: const LocalizedText('Change phone number'),
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/marketplace/services'),
                    child: const LocalizedText('Explore services'),
                  ),
                  const LocalizedText(
                    'Lost access? You can sign in again with the same verified number. '
                    'If you no longer own the number, contact support before creating a replacement account.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
