import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'localization/app_language.dart';
import 'services/local_store.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/home_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/worker_form_screen.dart';
import 'screens/worker_profile_screen.dart';
import 'screens/jobs_screen.dart';
import 'screens/job_form_screen.dart';
import 'screens/job_detail_screen.dart';
import 'screens/account_screen.dart';
import 'screens/backup_screen.dart';
import 'screens/help_screen.dart';
import 'widgets/app_ui.dart';
import 'marketplace/services/marketplace_controller.dart';
import 'marketplace/push_notifications.dart';
import 'marketplace/screens/marketplace_home_screen.dart';
import 'marketplace/screens/marketplace_auth_screen.dart';
import 'marketplace/screens/marketplace_account_screen.dart';
import 'marketplace/screens/marketplace_worker_form_screen.dart';
import 'marketplace/screens/marketplace_worker_profile_screen.dart';
import 'marketplace/screens/marketplace_jobs_screen.dart';
import 'marketplace/screens/marketplace_notifications_screen.dart';
import 'marketplace/screens/marketplace_admin_screen.dart';
import 'marketplace/screens/marketplace_privacy_screen.dart';
import 'marketplace/screens/marketplace_help_screen.dart';

class KhidmatApp extends StatefulWidget {
  const KhidmatApp({
    super.key,
    this.store,
    this.marketplace,
    this.push,
    this.initialLocation,
  });
  final LocalStore? store;
  final MarketplaceController? marketplace;
  final OptionalPushService? push;
  final String? initialLocation;
  @override
  State<KhidmatApp> createState() => _KhidmatAppState();
}

class _KhidmatAppState extends State<KhidmatApp> {
  late final LocalStore _store;
  late final GoRouter _router;
  late final MarketplaceController _marketplace;
  late final OptionalPushService _push;
  final AppLanguage _language = AppLanguage();
  @override
  void initState() {
    super.initState();
    _store = widget.store ?? LocalStore();
    _marketplace = widget.marketplace ?? MarketplaceController();
    _push =
        widget.push ??
        OptionalPushService(
          client: _marketplace.client,
          onNotification: () async {
            await _marketplace.refresh();
          },
        );
    _marketplace.beforeSignOut = () async {
      await _push.disable();
    };
    _router = GoRouter(
      initialLocation:
          widget.initialLocation ??
          (widget.marketplace != null ? '/marketplace' : '/home'),
      refreshListenable: Listenable.merge([_store, _marketplace]),
      redirect: (context, state) {
        final path = state.uri.path;
        // Online accounts and phone-owned records are independent. Backend
        // authorization is enforced in PostgreSQL for every marketplace action.
        if (path == '/marketplace' || path.startsWith('/marketplace/')) {
          return null;
        }
        if (!_store.initialized) {
          return path == '/storage' ||
                  (path == '/backup' && _store.error != null)
              ? null
              : '/storage';
        }
        if (_store.profile == null) {
          return [
                '/welcome',
                '/profile/create',
                '/backup',
                '/help',
              ].contains(path)
              ? null
              : '/welcome';
        }
        if (['/', '/welcome', '/storage', '/profile/create'].contains(path)) {
          return '/home';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/marketplace',
          builder: (_, _) => const MarketplaceHomeScreen(),
        ),
        GoRoute(
          path: '/marketplace/auth',
          builder: (_, _) => const MarketplaceAuthScreen(),
        ),
        GoRoute(
          path: '/marketplace/account',
          builder: (_, _) => const MarketplaceAccountScreen(),
        ),
        GoRoute(
          path: '/marketplace/worker/edit',
          builder: (_, _) => const MarketplaceWorkerFormScreen(),
        ),
        GoRoute(
          path: '/marketplace/workers/:id',
          builder: (_, s) =>
              MarketplaceWorkerProfileScreen(id: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/marketplace/jobs',
          builder: (_, _) => const MarketplaceJobsScreen(),
        ),
        GoRoute(
          path: '/marketplace/notifications',
          builder: (_, _) => const MarketplaceNotificationsScreen(),
        ),
        GoRoute(
          path: '/marketplace/admin',
          builder: (_, _) => const MarketplaceAdminScreen(),
        ),
        GoRoute(
          path: '/marketplace/privacy',
          builder: (_, _) => const MarketplacePrivacyScreen(),
        ),
        GoRoute(
          path: '/marketplace/help',
          builder: (_, _) => const MarketplaceHelpScreen(),
        ),
        GoRoute(path: '/', redirect: (_, _) => '/home'),
        GoRoute(path: '/storage', builder: (_, _) => const _StorageScreen()),
        GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
        GoRoute(
          path: '/profile/create',
          builder: (_, _) => const ProfileScreen(creating: true),
        ),
        GoRoute(
          path: '/profile/edit',
          builder: (_, _) => const ProfileScreen(),
        ),
        GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        GoRoute(path: '/contacts', builder: (_, _) => const ContactsScreen()),
        GoRoute(
          path: '/contacts/new',
          builder: (_, _) => const WorkerFormScreen(),
        ),
        GoRoute(
          path: '/contacts/:id',
          builder: (_, s) => WorkerProfileScreen(id: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/contacts/:id/edit',
          builder: (_, s) => WorkerFormScreen(id: s.pathParameters['id']!),
        ),
        GoRoute(path: '/jobs', builder: (_, _) => const JobsScreen()),
        GoRoute(
          path: '/jobs/new',
          builder: (_, s) =>
              JobFormScreen(workerId: s.uri.queryParameters['worker']),
        ),
        GoRoute(
          path: '/jobs/:id',
          builder: (_, s) => JobDetailScreen(id: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/jobs/:id/edit',
          builder: (_, s) => JobFormScreen(id: s.pathParameters['id']!),
        ),
        GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
        GoRoute(path: '/backup', builder: (_, _) => const BackupScreen()),
        GoRoute(path: '/help', builder: (_, _) => const HelpScreen()),
      ],
      errorBuilder: (context, _) => AppPage(
        title: 'Khidmat',
        navigation: false,
        child: EmptyState(
          title: 'This page is unavailable',
          message: 'Return to your dashboard to continue.',
          action: 'Return home',
          onAction: () => context.go('/home'),
        ),
      ),
    );
    unawaited(_language.load());
    if (!_store.initialized) unawaited(_store.initialize());
    if (!_marketplace.initialized) unawaited(_marketplace.initialize());
  }

  @override
  void dispose() {
    _router.dispose();
    _language.dispose();
    if (widget.store == null) _store.dispose();
    if (widget.marketplace == null) _marketplace.dispose();
    if (widget.push == null) _push.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider<LocalStore>.value(value: _store),
      ChangeNotifierProvider<AppLanguage>.value(value: _language),
      ChangeNotifierProvider<MarketplaceController>.value(value: _marketplace),
      ChangeNotifierProvider<OptionalPushService>.value(value: _push),
    ],
    child: Consumer<AppLanguage>(
      builder: (_, language, _) => MaterialApp.router(
        title: 'Khidmat',
        locale: language.locale,
        supportedLocales: const [Locale('en'), Locale('ur')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: AppTheme.darkTheme,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    ),
  );
}

class _StorageScreen extends StatelessWidget {
  const _StorageScreen();
  @override
  Widget build(BuildContext context) {
    final store = context.watch<LocalStore>();
    return AppPage(
      title: 'Khidmat',
      navigation: false,
      child: Center(
        child: store.error == null
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EmptyState(
                      title: 'Phone storage needs attention',
                      message: store.error!,
                      action: 'Try again',
                      icon: Icons.folder_outlined,
                      onAction: store.initialize,
                    ),
                    TextButton(
                      onPressed: () => context.push('/backup'),
                      child: const LocalizedText('Restore backup'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
