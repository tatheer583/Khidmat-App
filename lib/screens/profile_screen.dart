import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../localization/app_language.dart';
import '../models/local_data.dart';
import '../services/local_store.dart';
import '../widgets/app_ui.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.creating = false});
  final bool creating;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _city = TextEditingController(),
      _phone = TextEditingController();
  final _years = TextEditingController(text: '0'),
      _details = TextEditingController();
  AccountRole _role = AccountRole.customer;
  String _profession = 'Plumber';
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    final p = context.read<LocalStore>().profile;
    if (p != null) {
      _name.text = p.name;
      _city.text = p.city;
      _phone.text = p.phone;
      _years.text = p.experienceYears.toString();
      _details.text = p.details;
      _role = p.role;
      _profession = p.profession;
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _city, _phone, _years, _details]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<LocalStore>().saveProfile(
        KhidmatProfile(
          name: _name.text.trim(),
          city: _city.text.trim(),
          phone: cleanPhone(_phone.text),
          role: _role,
          profession: _profession,
          experienceYears: int.tryParse(_years.text.trim()) ?? 0,
          details: _details.text.trim(),
        ),
      );
      if (mounted) {
        showMessage(context, 'Profile saved on your phone.');
        context.go('/home');
      }
    } catch (e) {
      if (mounted) showMessage(context, localError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: widget.creating ? 'Create your profile' : 'Edit profile',
    navigation: false,
    child: Form(
      key: _form,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          LocalizedText(
            'How will you use Khidmat?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: AccountRole.values
                .map(
                  (role) => ChoiceChip(
                    label: LocalizedText(role.label),
                    selected: _role == role,
                    avatar: Icon(
                      role == AccountRole.worker
                          ? Icons.handyman
                          : Icons.home_outlined,
                      size: 18,
                    ),
                    onSelected: _busy
                        ? null
                        : (_) => setState(() => _role = role),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          formField(context, _name, 'Your name', validator: requiredText),
          formField(
            context,
            _city,
            'City',
            validator: requiredText,
            maxLength: 80,
          ),
          formField(
            context,
            _phone,
            'Phone number (optional)',
            keyboard: TextInputType.phone,
            maxLength: 30,
            validator: (value) => phoneValidator(value, optional: true),
          ),
          if (_role == AccountRole.worker) ...[
            DropdownButtonFormField<String>(
              initialValue: _profession,
              decoration: localizedDecoration(context, labelText: 'Profession'),
              items: serviceCategories
                  .map(
                    (s) => DropdownMenuItem(value: s, child: LocalizedText(s)),
                  )
                  .toList(),
              onChanged: _busy ? null : (v) => setState(() => _profession = v!),
            ),
            const SizedBox(height: 20),
            formField(
              context,
              _years,
              'Working experience (years)',
              keyboard: TextInputType.number,
              validator: yearsValidator,
              maxLength: 2,
            ),
            formField(
              context,
              _details,
              'About you / work details',
              lines: 4,
              maxLength: 2000,
            ),
          ],
          const InfoCard(
            'This profile is saved on this phone. Share your details directly with people you want to work with.',
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _busy ? null : _save,
            child: LocalizedText(_busy ? 'Saving…' : 'Save profile'),
          ),
        ],
      ),
    ),
  );
}
