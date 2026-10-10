import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../localization/app_language.dart';
import '../models/local_data.dart';
import '../widgets/app_ui.dart';

class ContactActions {
  static Future<void> call(BuildContext context, String phone) =>
      _open(context, Uri(scheme: 'tel', path: cleanPhone(phone)));
  static Future<void> sms(BuildContext context, String phone, String text) =>
      _open(
        context,
        Uri(
          scheme: 'sms',
          path: cleanPhone(phone),
          query: Platform.isIOS ? null : 'body=${Uri.encodeComponent(text)}',
        ),
      );
  static Future<void> _open(BuildContext context, Uri uri) async {
    if (!validPhone(uri.path)) {
      showMessage(context, 'Enter a valid phone number');
      return;
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        showMessage(
          context,
          'No phone or messaging app is available on this device.',
        );
      }
    } catch (_) {
      if (context.mounted) {
        showMessage(
          context,
          'No phone or messaging app is available on this device.',
        );
      }
    }
  }

  static Rect? _origin(BuildContext context) {
    final box = context.findRenderObject();
    return box is RenderBox && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
  }

  static Future<void> shareText(BuildContext context, String text) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          title: context.tr('Khidmat'),
          sharePositionOrigin: _origin(context),
        ),
      );
    } catch (_) {
      if (context.mounted) {
        showMessage(context, 'Sharing is unavailable. Please try again.');
      }
    }
  }

  static Future<void> exportBackup(BuildContext context, String json) async {
    Directory? exportDirectory;
    try {
      final temporary = await getTemporaryDirectory();
      exportDirectory = await temporary.createTemp('khidmat-backup-');
      final file = File(
        '${exportDirectory.path}${Platform.pathSeparator}khidmat-backup.json',
      );
      await file.writeAsString(json, flush: true);
      if (!context.mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          title: context.tr('Save backup'),
          sharePositionOrigin: _origin(context),
        ),
      );
    } catch (_) {
      if (context.mounted) {
        showMessage(
          context,
          'The backup could not be shared. Please try again.',
        );
      }
    } finally {
      // Remove only the temporary directory created for this export. The
      // destination chosen in the system share sheet belongs to the user.
      try {
        if (exportDirectory != null && await exportDirectory.exists()) {
          final exportedFile = File(
            '${exportDirectory.path}${Platform.pathSeparator}khidmat-backup.json',
          );
          if (await exportedFile.exists()) await exportedFile.delete();
          await exportDirectory.delete();
        }
      } on FileSystemException {
        // OS cache cleanup can finish if a share recipient still holds a file.
      }
    }
  }

  static String workerText(BuildContext context, WorkerContact worker) => [
    'Khidmat · ${worker.name}',
    context.tr(worker.category),
    worker.city,
    worker.phone,
    if (worker.rate > 0) '${context.tr('Starting rate')}: Rs. ${worker.rate}',
    if (worker.details.isNotEmpty) worker.details,
  ].join('\n');
  static String profileText(BuildContext context, KhidmatProfile profile) => [
    'Khidmat · ${profile.name}',
    context.tr(profile.role.label),
    if (profile.role == AccountRole.worker) context.tr(profile.profession),
    profile.city,
    if (profile.phone.isNotEmpty) profile.phone,
    if (profile.role == AccountRole.worker)
      context.tr('${profile.experienceYears} years of experience'),
    if (profile.details.isNotEmpty) profile.details,
  ].join('\n');
  static String jobText(BuildContext context, JobRecord job) => [
    context.tr('Khidmat appointment request'),
    '${context.tr('Service')}: ${context.tr(job.service)}',
    '${context.tr('Date')}: ${jobDate(context, job.scheduledAt)} · ${jobTime(context, job.scheduledAt)}',
    '${context.tr('Address')}: ${job.address}',
    if (job.amount > 0) '${context.tr('Amount')}: Rs. ${job.amount}',
    if (job.notes.isNotEmpty) job.notes,
    context.tr('Please confirm the time and price with me.'),
  ].join('\n');
}
