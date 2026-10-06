import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../localization/app_language.dart';
import '../services/backend_session.dart';
import '../widgets/live_ui.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});
  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _password.dispose();
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
      await session.client.auth.updateUser(
        UserAttributes(password: _password.text),
      );
      if (!mounted) return;
      showMessage(context, 'Password updated.');
      session.passwordUpdated();
    } catch (e) {
      if (mounted) setState(() => _error = describeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const LocalizedText('Choose a new password'),
      actions: const [LanguageButton()],
    ),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextFormField(
            controller: _password,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            decoration: localizedDecoration(context, labelText: 'Password'),
            validator: (v) => v == null || v.length < 8
                ? context.tr('Use at least 8 characters')
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            obscureText: true,
            decoration: localizedDecoration(
              context,
              labelText: 'Confirm password',
            ),
            validator: (v) => v != _password.text
                ? context.tr('Passwords do not match')
                : null,
          ),
          if (_error != null) Notice(_error!),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _busy ? null : _save,
            child: LocalizedText(_busy ? 'Saving…' : 'Save password'),
          ),
        ],
      ),
    ),
  );
}
