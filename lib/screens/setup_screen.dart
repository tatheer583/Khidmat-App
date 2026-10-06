import '../localization/app_language.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/backend_session.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _url = TextEditingController();
  final _key = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _url.dispose();
    _key.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<BackendSession>().configure(
        _url.text.trim(),
        _key.text.trim(),
      );
    } catch (e) {
      if (mounted) setState(() => _error = describeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      actions: const [LanguageButton()],
      title: const LocalizedText('Connect Khidmat'),
    ),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.handshake_outlined, size: 60),
              const SizedBox(height: 24),
              LocalizedText(
                'Welcome to Khidmat',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              const LocalizedText(
                'This build needs its Supabase project connection. '
                'Enter the project URL and public app key supplied by the app owner.',
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _url,
                keyboardType: TextInputType.url,
                decoration: localizedDecoration(
                  context,
                  labelText: 'Supabase project URL',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _key,
                autocorrect: false,
                enableSuggestions: false,
                decoration: localizedDecoration(
                  context,
                  labelText: 'Publishable or anon key',
                ),
              ),
              const SizedBox(height: 12),
              const LocalizedText(
                'Never enter a service-role key, secret key or database password.',
              ),
              if (_error != null ||
                  context.watch<BackendSession>().error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: LocalizedText(
                    _error ?? context.watch<BackendSession>().error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _busy ? null : _connect,
                child: LocalizedText(_busy ? 'Connecting…' : 'Connect'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
