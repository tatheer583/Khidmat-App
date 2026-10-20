import 'dart:convert';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../localization/app_language.dart';
import '../services/local_store.dart';
import '../services/contact_actions.dart';
import '../widgets/app_ui.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});
  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _busy = false;
  Future<void> _import() async {
    setState(() => _busy = true);
    try {
      final file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'Khidmat backup',
            extensions: ['json'],
            mimeTypes: ['application/json', 'text/plain'],
            uniformTypeIdentifiers: ['public.json', 'public.text'],
          ),
        ],
      );
      if (file == null || !mounted) return;
      if (await file.length() > 20 * 1024 * 1024) {
        throw const FormatException('This backup is too large');
      }
      final raw = utf8.decode(await file.readAsBytes());
      if (!mounted) return;
      final store = context.read<LocalStore>();
      final data = store.inspectBackup(raw);
      final confirmed = await confirmAction(
        context,
        'Restore backup?',
        'Replace this phone’s profile, workers and jobs with ${data.workers.length} workers and ${data.jobs.length} jobs from this backup?',
        confirm: 'Restore',
      );
      if (!confirmed || !mounted) return;
      await store.restoreBackup(raw);
      if (mounted) {
        showMessage(context, 'Backup restored.');
        context.go('/home');
      }
    } catch (e) {
      if (mounted) showMessage(context, localError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    await ContactActions.exportBackup(
      context,
      context.read<LocalStore>().exportBackup(),
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Backup and restore',
    navigation: false,
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const InfoCard(
          'Save a backup to keep your profile, worker contacts and job records when changing phones.',
        ),
        const InfoCard(
          'This backup contains names, phone numbers, addresses and notes in an unencrypted file. Save it somewhere private. Online accounts and sessions are not included.',
          icon: Icons.lock_outline,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _busy || !context.watch<LocalStore>().initialized
              ? null
              : _export,
          icon: const Icon(Icons.ios_share),
          label: const LocalizedText('Save backup'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _busy ? null : _import,
          icon: const Icon(Icons.file_open_outlined),
          label: const LocalizedText('Restore backup'),
        ),
        const SizedBox(height: 24),
        const LocalizedText(
          'Choose a place to save khidmat-backup.json. You can restore that file on another phone.',
        ),
        const SizedBox(height: 16),
        const LocalizedText(
          'Uninstalling Khidmat or clearing app storage removes your phone records. Save a backup first.',
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    ),
  );
}
