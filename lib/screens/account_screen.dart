import '../localization/app_language.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/backend_session.dart';
import '../services/khidmat_repository.dart';
import '../widgets/live_ui.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  String? _avatar;
  bool _busy = false;
  bool _loaded = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profile = context.watch<BackendSession>().profile;
    if (!_loaded && profile != null) {
      _name.text = profile['full_name'] as String? ?? '';
      _city.text = profile['city'] as String? ?? '';
      _address.text = profile['location'] as String? ?? '';
      _avatar = profile['avatar_path'] as String?;
      _loaded = true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save({XFile? image}) async {
    if (!_form.currentState!.validate()) return;
    final session = context.read<BackendSession>();
    final repository = KhidmatRepository(session.client);
    setState(() {
      _busy = true;
      _error = null;
    });
    String? uploaded;
    try {
      if (image != null) uploaded = await repository.uploadImage(image);
      final saved = await session.client
          .from('profiles')
          .update({
            'full_name': _name.text.trim(),
            'city': _city.text.trim(),
            'location': _address.text.trim(),
            'avatar_path': uploaded ?? _avatar,
          })
          .eq('id', session.user!.id)
          .select()
          .single();
      if (uploaded != null) _avatar = uploaded;
      session.acceptProfile(saved);
      if (mounted) showMessage(context, 'Profile saved.');
    } catch (e) {
      if (uploaded != null && e is PostgrestException) {
        try {
          await session.client.storage.from('avatars').remove([uploaded]);
        } catch (_) {}
      }
      if (mounted) setState(() => _error = describeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<BackendSession>();
    return Scaffold(
      appBar: AppBar(
        actions: const [LanguageButton()],
        title: const LocalizedText('My account'),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (_avatar != null)
              Center(
                child: SizedBox(
                  width: 100,
                  child: StoredImage(
                    bucket: 'avatars',
                    path: _avatar!,
                    height: 100,
                  ),
                ),
              ),
            TextButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      try {
                        final image = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1600,
                          maxHeight: 1600,
                          imageQuality: 85,
                        );
                        if (image != null && mounted) await _save(image: image);
                      } catch (e) {
                        if (context.mounted) {
                          showMessage(context, describeError(e));
                        }
                      }
                    },
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const LocalizedText('Upload profile photo'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              errorBuilder: (context, error) => LocalizedText(error),
              controller: _name,
              maxLength: 100,
              decoration: localizedDecoration(context, labelText: 'Your name'),
              validator: (v) =>
                  v == null || v.trim().length < 2 ? 'Enter your name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              errorBuilder: (context, error) => LocalizedText(error),
              controller: _city,
              maxLength: 80,
              decoration: localizedDecoration(context, labelText: 'City'),
              validator: (v) =>
                  v == null || v.trim().length < 2 ? 'Enter your city' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              errorBuilder: (context, error) => LocalizedText(error),
              controller: _address,
              maxLength: 300,
              maxLines: 3,
              decoration: localizedDecoration(
                context,
                labelText: 'Default service address',
              ),
            ),
            if (_error != null) Notice(_error!),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _busy ? null : () => _save(),
              child: LocalizedText(_busy ? 'Saving…' : 'Save profile'),
            ),
            const SizedBox(height: 24),
            LocalizedText(session.user?.email ?? session.user?.phone ?? ''),
            TextButton(
              onPressed: _busy ? null : () => context.push('/profile/edit'),
              child: const LocalizedText('Edit profile and account type'),
            ),
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
