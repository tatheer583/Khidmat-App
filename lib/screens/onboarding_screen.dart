import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../localization/app_language.dart';
import '../services/backend_session.dart';
import '../widgets/live_ui.dart';

class OnboardingScreen extends StatefulWidget {
  final bool editing;
  const OnboardingScreen({super.key, this.editing = false});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _profession = TextEditingController();
  final _experience = TextEditingController(text: '0');
  final _bio = TextEditingController();
  String? _role;
  int _step = 0;
  bool _busy = false;
  String? _error;
  bool _loaded = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profile = context.watch<BackendSession>().profile;
    if (!_loaded && profile != null) {
      _name.text = profile['full_name'] as String? ?? '';
      _city.text = profile['city'] as String? ?? '';
      _address.text = profile['location'] as String? ?? '';
      _profession.text = profile['profession'] as String? ?? '';
      _experience.text = (profile['experience_years'] ?? 0).toString();
      _bio.text = profile['bio'] as String? ?? '';
      if (widget.editing) _role = profile['account_role'] as String?;
      _loaded = true;
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _city,
      _address,
      _profession,
      _experience,
      _bio,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final session = context.read<BackendSession>();
    try {
      final saved = await session.client.rpc(
        'complete_profile',
        params: {
          'p_full_name': _name.text.trim(),
          'p_role': _role,
          'p_city': _city.text.trim(),
          'p_location': _address.text.trim(),
          'p_profession': _profession.text.trim(),
          'p_experience_years': int.parse(_experience.text),
          'p_bio': _bio.text.trim(),
        },
      );
      session.acceptProfile(Map<String, dynamic>.from(saved as Map));
      if (session.profileComplete && mounted) context.go('/home');
    } catch (e) {
      if (mounted) setState(() => _error = describeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _roleChoice(
    String value,
    String label,
    String description,
    IconData icon,
  ) => Card(
    color: _role == value
        ? Theme.of(context).colorScheme.primaryContainer
        : null,
    child: ListTile(
      leading: Icon(icon),
      title: LocalizedText(label),
      subtitle: LocalizedText(description),
      trailing: _role == value ? const Icon(Icons.check_circle) : null,
      onTap: () => setState(() => _role = value),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final session = context.watch<BackendSession>();
    return Scaffold(
      appBar: AppBar(
        title: const LocalizedText('Complete your profile'),
        automaticallyImplyLeading: widget.editing,
        actions: const [LanguageButton()],
      ),
      body: session.profile == null
          ? Center(
              child: session.error == null
                  ? const CircularProgressIndicator()
                  : Notice(session.error!, retry: session.refreshProfile),
            )
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  LinearProgressIndicator(value: _step == 0 ? 0.5 : 1),
                  const SizedBox(height: 24),
                  if (_step == 0) ...[
                    LocalizedText(
                      'How will you use Khidmat?',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),
                    _roleChoice(
                      'worker',
                      'Worker',
                      'I offer services and receive jobs.',
                      Icons.handyman_outlined,
                    ),
                    _roleChoice(
                      'customer',
                      'Work giver',
                      'I need help and want to hire workers.',
                      Icons.person_search_outlined,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _role == null
                          ? null
                          : () => setState(() => _step = 1),
                      child: const LocalizedText('Continue'),
                    ),
                  ] else ...[
                    LocalizedText(
                      _role == 'worker' ? 'Worker' : 'Work giver',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      errorBuilder: (context, error) => LocalizedText(error),
                      controller: _name,
                      maxLength: 100,
                      decoration: localizedDecoration(
                        context,
                        labelText: 'Your name',
                      ),
                      validator: (v) => v == null || v.trim().length < 2
                          ? context.tr('Enter your name')
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      errorBuilder: (context, error) => LocalizedText(error),
                      controller: _city,
                      maxLength: 80,
                      decoration: localizedDecoration(
                        context,
                        labelText: 'City',
                      ),
                      validator: (v) => v == null || v.trim().length < 2
                          ? context.tr('Enter your city')
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      errorBuilder: (context, error) => LocalizedText(error),
                      controller: _address,
                      maxLength: 300,
                      maxLines: 2,
                      decoration: localizedDecoration(
                        context,
                        labelText: 'Default service address',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      errorBuilder: (context, error) => LocalizedText(error),
                      controller: _profession,
                      maxLength: 100,
                      decoration: localizedDecoration(
                        context,
                        labelText: 'Profession',
                      ),
                      validator: (v) =>
                          _role == 'worker' &&
                              (v == null || v.trim().length < 2)
                          ? context.tr('Enter your profession')
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      errorBuilder: (context, error) => LocalizedText(error),
                      controller: _experience,
                      keyboardType: TextInputType.number,
                      decoration: localizedDecoration(
                        context,
                        labelText: 'Working experience (years)',
                      ),
                      validator: (v) {
                        final years = int.tryParse(v ?? '');
                        return years == null || years < 0 || years > 60
                            ? context.tr('Enter experience from 0 to 60 years')
                            : null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      errorBuilder: (context, error) => LocalizedText(error),
                      controller: _bio,
                      maxLength: 2000,
                      maxLines: 4,
                      decoration: localizedDecoration(
                        context,
                        labelText: 'About you / work details',
                        helperText: _role == 'worker'
                            ? 'Tell customers about your skills and experience.'
                            : 'Describe the kind of help you usually need.',
                      ),
                      validator: (v) =>
                          _role == 'worker' &&
                              (v == null || v.trim().length < 10)
                          ? context.tr('Add a short description')
                          : null,
                    ),
                    if (_error != null) Notice(_error!),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _busy ? null : _save,
                      child: LocalizedText(
                        _busy ? 'Saving…' : 'Continue to dashboard',
                      ),
                    ),
                    TextButton(
                      onPressed: _busy ? null : () => setState(() => _step = 0),
                      child: const LocalizedText('Choose your role'),
                    ),
                  ],
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () async {
                            try {
                              await session.signOut();
                            } catch (e) {
                              if (context.mounted) {
                                showMessage(context, describeError(e));
                              }
                            }
                          },
                    child: const LocalizedText('Sign out'),
                  ),
                ],
              ),
            ),
    );
  }
}
