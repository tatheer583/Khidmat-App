import '../localization/app_language.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/backend_session.dart';
import '../theme/app_colors.dart';
import '../widgets/khidmat_brand.dart';
import '../widgets/live_ui.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _showPassword = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<BackendSession>().client.auth;
    try {
      if (_register) {
        final response = await auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {'full_name': _name.text.trim()},
          emailRedirectTo: authRedirectUrl,
        );
        if (response.session == null && mounted) {
          showMessage(
            context,
            'Check your email to confirm your account, then sign in.',
          );
          setState(() => _register = false);
        }
      } else {
        await auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = describeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim())) {
      setState(() => _error = 'Enter a valid email');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<BackendSession>().client.auth.resetPasswordForEmail(
        _email.text.trim(),
        redirectTo: authRedirectUrl,
      );
      if (mounted) {
        showMessage(
          context,
          'If an account exists, a password reset link has been sent. Check your email.',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = describeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(actions: const [LanguageButton()]),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: KhidmatBrandMark(size: 88)),
                  const SizedBox(height: 22),
                  LocalizedText(
                    'Khidmat',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 4),
                  const LocalizedText(
                    'خدمت',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const LocalizedText(
                    'Trusted local help, in your language.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 26),
                  ElevatedButton.icon(
                    onPressed:
                        _busy ||
                            context.watch<BackendSession>().phoneEnabled ==
                                false
                        ? null
                        : () => context.push('/otp'),
                    icon: const Icon(Icons.phone_outlined),
                    label: const LocalizedText('Continue with phone'),
                  ),
                  if (context.watch<BackendSession>().phoneEnabled == false)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: LocalizedText(
                        'Phone sign in is not available yet. Please use email.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 20),
                  const LocalizedText(
                    'Or use email',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  LocalizedText(
                    _register ? 'Create your account' : 'Sign in',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  if (_register) ...[
                    TextFormField(
                      errorBuilder: (context, error) => LocalizedText(error),
                      controller: _name,
                      maxLength: 100,
                      decoration: localizedDecoration(
                        context,
                        labelText: 'Your name',
                      ),
                      validator: (v) => v == null || v.trim().length < 2
                          ? 'Enter your name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    errorBuilder: (context, error) => LocalizedText(error),
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.email],
                    decoration: localizedDecoration(
                      context,
                      labelText: 'Email',
                    ),
                    validator: (v) =>
                        v == null ||
                            !RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(v.trim())
                        ? 'Enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    errorBuilder: (context, error) => LocalizedText(error),
                    controller: _password,
                    obscureText: !_showPassword,
                    autofillHints: [
                      _register
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    decoration: localizedDecoration(
                      context,
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        tooltip: context.tr(
                          _showPassword ? 'Hide password' : 'Show password',
                        ),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? 'Enter your password'
                        : _register && v.length < 8
                        ? 'Use at least 8 characters'
                        : null,
                  ),
                  if (!_register)
                    TextButton(
                      onPressed: _busy ? null : _resetPassword,
                      child: const LocalizedText('Forgot password?'),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: LocalizedText(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _busy ? null : _submit,
                    child: LocalizedText(
                      _busy
                          ? 'Please wait…'
                          : _register
                          ? 'Create account'
                          : 'Sign in',
                    ),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _register = !_register;
                            _error = null;
                          }),
                    child: LocalizedText(
                      _register
                          ? 'Already registered? Sign in'
                          : 'New here? Create an account',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
