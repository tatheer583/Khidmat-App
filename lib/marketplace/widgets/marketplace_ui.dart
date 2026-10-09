import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../localization/app_language.dart';

class MarketplacePalette {
  static const teal = Color(0xFF126B5E);
  static const deepTeal = Color(0xFF0C443C);
  static const ink = Color(0xFF173D35);
  static const muted = Color(0xFF667B73);
  static const cream = Color(0xFFF5F7F1);
  static const mint = Color(0xFFE4F0E9);
  static const border = Color(0xFFDDE6DE);
  static const gold = Color(0xFFE7BE67);
}

final ThemeData marketplaceTheme = (() {
  final base = ThemeData.light(useMaterial3: true);
  final text = base.textTheme.apply(
    bodyColor: MarketplacePalette.ink,
    displayColor: MarketplacePalette.ink,
  );
  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(seedColor: MarketplacePalette.teal)
        .copyWith(
          primary: MarketplacePalette.teal,
          onPrimary: Colors.white,
          secondary: MarketplacePalette.deepTeal,
          surface: Colors.white,
          onSurface: MarketplacePalette.ink,
          outline: MarketplacePalette.border,
          surfaceContainerHighest: MarketplacePalette.mint,
        ),
    scaffoldBackgroundColor: MarketplacePalette.cream,
    textTheme: text.copyWith(
      headlineMedium: text.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -.8,
      ),
      titleLarge: text.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -.4,
      ),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      bodyMedium: text.bodyMedium?.copyWith(height: 1.5),
      bodySmall: text.bodySmall?.copyWith(
        color: MarketplacePalette.muted,
        height: 1.5,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: MarketplacePalette.cream,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      foregroundColor: MarketplacePalette.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: MarketplacePalette.ink,
        fontSize: 21,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: MarketplacePalette.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: MarketplacePalette.muted),
      hintStyle: const TextStyle(color: MarketplacePalette.muted, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: MarketplacePalette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: MarketplacePalette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: MarketplacePalette.teal,
          width: 1.5,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: MarketplacePalette.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: MarketplacePalette.teal,
        minimumSize: const Size(0, 46),
        side: const BorderSide(color: MarketplacePalette.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: MarketplacePalette.teal,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: Colors.white,
      selectedColor: MarketplacePalette.mint,
      side: const BorderSide(color: MarketplacePalette.border),
      labelStyle: const TextStyle(
        fontSize: 12,
        color: MarketplacePalette.ink,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    iconTheme: const IconThemeData(color: MarketplacePalette.teal),
    dividerColor: MarketplacePalette.border,
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: MarketplacePalette.cream,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: MarketplacePalette.mint,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 76,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: MarketplacePalette.ink,
        ),
      ),
    ),
  );
})();

class MarketplaceTheme extends StatelessWidget {
  const MarketplaceTheme({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      Theme(data: marketplaceTheme, child: child);
}

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
  Widget build(BuildContext context) => MarketplaceTheme(
    child: Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !navigation,
          title: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: MarketplacePalette.teal,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.cottage_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
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
              constraints: const BoxConstraints(maxWidth: 1080),
              child: child,
            ),
          ),
        ),
        bottomNavigationBar: navigation
            ? NavigationBar(
                selectedIndex: [0, 2, 3, 4, 1][section.clamp(0, 4)],
                onDestinationSelected: (index) => context.go(
                  [
                    '/marketplace',
                    '/marketplace/services',
                    '/marketplace/jobs',
                    '/marketplace/worker/edit',
                    '/marketplace/account',
                  ][index],
                ),
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home_rounded),
                    label: context.tr('Discover'),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.grid_view_outlined),
                    selectedIcon: const Icon(Icons.grid_view_rounded),
                    label: context.tr('Services'),
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
      ),
    ),
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
      color: error ? const Color(0xFFFFEFEC) : MarketplacePalette.mint,
      border: Border.all(
        color: error ? const Color(0xFFE9C5BE) : MarketplacePalette.border,
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              error ? Icons.error_outline : Icons.info_outline,
              size: 20,
              color: error ? const Color(0xFFA73B32) : MarketplacePalette.teal,
            ),
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
            color: MarketplacePalette.teal,
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
        color: MarketplacePalette.mint,
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
  if (lower.contains('paint')) return Icons.format_paint_outlined;
  if (lower.contains('carpen')) return Icons.carpenter_outlined;
  if (lower.contains('learn') || lower.contains('tutor')) {
    return Icons.school_outlined;
  }
  if (lower.contains('personal') || lower.contains('beaut')) {
    return Icons.spa_outlined;
  }
  if (lower.contains('outdoor')) return Icons.yard_outlined;
  return Icons.handyman_outlined;
}

String? serviceImageAsset(String profession) {
  final name = profession.toLowerCase();
  if (name.contains('electric') || name.contains('solar')) {
    return 'assets/images/service-electrician.png';
  }
  if (name.contains('plumb')) return 'assets/images/service-plumber.png';
  if (name.contains('paint')) return 'assets/images/service-painter.png';
  if (name.contains('ac ') || name.contains('appliance')) {
    return 'assets/images/service-ac.png';
  }
  if (name.contains('mazdoor') ||
      name.contains('mason') ||
      name.contains('weld') ||
      name.contains('tile')) {
    return 'assets/images/khidmat-team-hero.png';
  }
  return null;
}

class MarketplaceAsset extends StatelessWidget {
  const MarketplaceAsset({
    super.key,
    required this.asset,
    this.icon = Icons.handyman_outlined,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.label,
  });
  final String? asset;
  final IconData icon;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [MarketplacePalette.mint, Color(0xFFD1E5D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(icon, size: 50, color: MarketplacePalette.teal),
      ),
    );
    return asset == null
        ? fallback
        : Image.asset(
            asset!,
            fit: fit,
            alignment: alignment,
            semanticLabel: label,
            cacheWidth: asset!.contains('hero') ? 1200 : 400,
            errorBuilder: (_, _, _) => fallback,
          );
  }
}

class MarketplaceServiceCard extends StatelessWidget {
  const MarketplaceServiceCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.onTap,
    this.asset,
    this.icon = Icons.handyman_outlined,
    this.compact = false,
  });
  final String name, subtitle;
  final String? asset;
  final IconData icon;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: compact
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 76,
                      height: 78,
                      child: MarketplaceAsset(asset: asset, icon: icon),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LocalizedText(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: MarketplacePalette.ink,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: MarketplacePalette.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: MarketplaceAsset(
                      asset: asset,
                      icon: icon,
                      label: name,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(13, 12, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: LocalizedText(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: MarketplacePalette.ink,
                              ),
                            ),
                          ),
                          const Icon(Icons.north_east_rounded, size: 17),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.4,
                          color: MarketplacePalette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    ),
  );
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
