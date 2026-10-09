import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../localization/app_language.dart';
import '../../theme/app_colors.dart';
import '../../widgets/khidmat_brand.dart';

class MarketplacePage extends StatelessWidget {
  const MarketplacePage({
    super.key,
    required this.title,
    required this.child,
    this.section = 0,
    this.navigation = true,
    this.actions = const [],
  });

  final String title;
  final Widget child;
  final int section;
  final bool navigation;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Row(
        children: [
          const KhidmatBrandMark(size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: LocalizedText(title, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      actions: [...actions, const LanguageButton()],
    ),
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: child,
        ),
      ),
    ),
    bottomNavigationBar: navigation
        ? NavigationBar(
            selectedIndex: section,
            onDestinationSelected: (index) => context.go(
              [
                '/marketplace',
                '/marketplace/jobs',
                '/marketplace/worker/edit',
                '/marketplace/account',
              ][index],
            ),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.search),
                label: context.tr('Discover'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.work_outline),
                label: context.tr('Jobs'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.handyman_outlined),
                label: context.tr('My services'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                label: context.tr('Account'),
              ),
            ],
          )
        : null,
  );
}

class MarketplaceNotice extends StatelessWidget {
  const MarketplaceNotice({
    super.key,
    required this.message,
    this.error = false,
    this.action,
    this.onAction,
  });

  final String message;
  final bool error;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: (error ? AppColors.error : AppColors.info).withValues(alpha: .10),
      border: Border.all(
        color: (error ? AppColors.error : AppColors.info).withValues(
          alpha: .35,
        ),
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(error ? Icons.error_outline : Icons.info_outline, size: 20),
            const SizedBox(width: 10),
            Expanded(child: LocalizedText(message)),
          ],
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: LocalizedText(action!)),
      ],
    ),
  );
}

class MarketplaceHeading extends StatelessWidget {
  const MarketplaceHeading(
    this.title, {
    super.key,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocalizedText(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                LocalizedText(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

class MarketplaceSignIn extends StatelessWidget {
  const MarketplaceSignIn({super.key, this.message = 'Sign in to continue.'});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_outline,
            size: 48,
            color: AppColors.primaryLight,
          ),
          const SizedBox(height: 16),
          LocalizedText(message, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => context.push('/marketplace/auth'),
            child: const LocalizedText('Sign in with phone'),
          ),
        ],
      ),
    ),
  );
}

class MarketplacePhoto extends StatelessWidget {
  const MarketplacePhoto({
    super.key,
    required this.name,
    this.url,
    this.radius = 28,
  });

  final String name;
  final String? url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Text(
        name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase(),
        style: TextStyle(fontSize: radius * .8, fontWeight: FontWeight.w700),
      ),
    );
    return ClipOval(
      child: Container(
        width: radius * 2,
        height: radius * 2,
        color: AppColors.primaryContainer,
        child: !isSafeMarketplaceImage(url)
            ? fallback
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

IconData professionIcon(String category) {
  final lower = category.toLowerCase();
  if (lower.contains('construct')) return Icons.construction;
  if (lower.contains('electr')) return Icons.electrical_services;
  if (lower.contains('cool') || lower.contains('appliance')) {
    return Icons.ac_unit;
  }
  if (lower.contains('plumb')) return Icons.plumbing;
  if (lower.contains('garden')) return Icons.yard_outlined;
  if (lower.contains('clean')) return Icons.cleaning_services_outlined;
  return Icons.handyman_outlined;
}

String? marketplaceRequired(String? text) =>
    text == null || text.trim().length < 2
    ? 'Enter at least 2 characters.'
    : null;

String? pakistanPhone(String? text, {bool optional = false}) {
  final value = (text ?? '').replaceAll(RegExp(r'[\s()\-]'), '');
  if (optional && value.isEmpty) return null;
  return RegExp(r'^(?:\+92|0092|92|0)3\d{9}$').hasMatch(value)
      ? null
      : 'Enter a Pakistani mobile number, e.g. 0300 1234567.';
}

String? nonNegativeNumber(String? value, {double max = 1000000}) {
  final parsed = double.tryParse(value?.trim() ?? '');
  return parsed == null || !parsed.isFinite || parsed < 0 || parsed > max
      ? 'Enter a number from 0 to ${max.toStringAsFixed(0)}.'
      : null;
}

Widget marketplaceField(
  TextEditingController controller,
  String label, {
  String? Function(String?)? validator,
  TextInputType? keyboard,
  int lines = 1,
  int maxLength = 100,
  String? hint,
}) => Builder(
  builder: (context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      validator: validator,
      errorBuilder: (_, error) => LocalizedText(error),
      decoration: localizedDecoration(
        context,
        labelText: label,
        hintText: hint,
      ),
      keyboardType: keyboard,
      maxLines: lines,
      maxLength: maxLength,
      textInputAction: lines == 1
          ? TextInputAction.next
          : TextInputAction.newline,
    ),
  ),
);

bool isSafeMarketplaceImage(String? url) {
  final uri = url == null ? null : Uri.tryParse(url);
  return uri != null &&
      uri.scheme == 'https' &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty;
}
