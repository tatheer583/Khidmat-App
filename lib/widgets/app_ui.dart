import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../localization/app_language.dart';
import '../models/local_data.dart';
import '../theme/app_colors.dart';

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.child,
    this.section = 0,
    this.navigation = true,
    this.actions = const [],
    this.floatingActionButton,
  });
  final String title;
  final Widget child;
  final int section;
  final bool navigation;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: LocalizedText(title),
      actions: [...actions, const LanguageButton()],
    ),
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: child,
        ),
      ),
    ),
    floatingActionButton: floatingActionButton,
    bottomNavigationBar: navigation
        ? NavigationBar(
            selectedIndex: section,
            onDestinationSelected: (index) =>
                context.go(['/home', '/contacts', '/jobs', '/account'][index]),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                label: context.tr('Home'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.people_outline),
                label: context.tr('Workers'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.work_outline),
                label: context.tr('Jobs'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                label: context.tr('Profile'),
              ),
            ],
          )
        : null,
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.work_outline,
    this.action,
    this.onAction,
  });
  final String title, message;
  final IconData icon;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: AppColors.primaryLight),
        const SizedBox(height: 18),
        LocalizedText(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        LocalizedText(message, textAlign: TextAlign.center),
        if (action != null) ...[
          const SizedBox(height: 20),
          ElevatedButton(onPressed: onAction, child: LocalizedText(action!)),
        ],
      ],
    ),
  );
}

class InfoCard extends StatelessWidget {
  const InfoCard(this.text, {super.key, this.icon = Icons.info_outline});
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryLight),
          const SizedBox(width: 12),
          Expanded(child: LocalizedText(text)),
        ],
      ),
    ),
  );
}

class PersonAvatar extends StatelessWidget {
  const PersonAvatar(this.name, {super.key, this.radius = 24});
  final String name;
  final double radius;
  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    backgroundColor: AppColors.primaryContainer,
    foregroundColor: AppColors.primaryLight,
    child: Text(
      name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase(),
      style: TextStyle(fontSize: radius * .8, fontWeight: FontWeight.w700),
    ),
  );
}

String jobDate(BuildContext context, DateTime date) =>
    DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(date);
String jobTime(BuildContext context, DateTime date) =>
    TimeOfDay.fromDateTime(date).format(context);

class JobCard extends StatelessWidget {
  const JobCard(this.job, {super.key});
  final JobRecord job;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Icon(
        job.status == JobStatus.completed ? Icons.task_alt : Icons.work_outline,
        color: job.status == JobStatus.completed
            ? AppColors.success
            : AppColors.primaryLight,
      ),
      title: LocalizedText(
        job.service,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(job.personName, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(
            '${jobDate(context, job.scheduledAt)} · ${jobTime(context, job.scheduledAt)}',
          ),
          LocalizedText(
            job.status.label,
            style: TextStyle(color: statusColor(job.status)),
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/jobs/${job.id}'),
    ),
  );
}

Color statusColor(JobStatus status) => switch (status) {
  JobStatus.completed => AppColors.success,
  JobStatus.cancelled => AppColors.textMuted,
  JobStatus.inProgress => AppColors.info,
  JobStatus.confirmed => AppColors.primaryLight,
  JobStatus.planned => AppColors.warning,
};
void showMessage(BuildContext context, String message) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: LocalizedText(message)));
Future<bool> confirmAction(
  BuildContext context,
  String title,
  String message, {
  String confirm = 'Delete',
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: LocalizedText(title),
        content: LocalizedText(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const LocalizedText('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: LocalizedText(confirm),
          ),
        ],
      ),
    ) ??
    false;

String? requiredText(String? value) =>
    value == null || value.trim().length < 2 ? 'Fill this field' : null;
String? phoneValidator(String? value, {bool optional = false}) =>
    validPhone(value ?? '', optional: optional)
    ? null
    : 'Enter a valid phone number';
String? amountValidator(String? value) {
  final amount = int.tryParse(value?.trim() ?? '');
  return amount == null || amount < 0 || amount > 1000000
      ? 'Enter a valid rupee amount'
      : null;
}

String? yearsValidator(String? value) {
  final years = int.tryParse(value?.trim() ?? '');
  return years == null || years < 0 || years > 60
      ? 'Enter experience from 0 to 60 years'
      : null;
}

Widget formField(
  BuildContext context,
  TextEditingController controller,
  String label, {
  String? Function(String?)? validator,
  TextInputType? keyboard,
  int lines = 1,
  int maxLength = 100,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 16),
  child: Semantics(
    identifier:
        'khidmat.input.${label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}',
    label: context.tr(label),
    textField: true,
    child: TextFormField(
      controller: controller,
      validator: validator,
      errorBuilder: (_, error) => LocalizedText(error),
      decoration: localizedDecoration(context, labelText: label),
      keyboardType: keyboard,
      maxLines: lines,
      maxLength: maxLength,
      textInputAction: lines == 1
          ? TextInputAction.next
          : TextInputAction.newline,
    ),
  ),
);
