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

class KhidmatApp extends StatefulWidget {
  const KhidmatApp({super.key, this.store});
  final LocalStore? store;
  @override
  State<KhidmatApp> createState() => _KhidmatAppState();
}

class _KhidmatAppState extends State<KhidmatApp> {
  late final LocalStore _store;
  late final GoRouter _router;
  final AppLanguage _language = AppLanguage();
  @override
  void initState() {
    super.initState();
    _store = widget.store ?? LocalStore();
    _router = GoRouter(
      initialLocation: '/home',
      refreshListenable: _store,
      redirect: (context, state) {
        final path = state.uri.path;
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
  }

  @override
  void dispose() {
    _router.dispose();
    _language.dispose();
    if (widget.store == null) _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider<LocalStore>.value(value: _store),
      ChangeNotifierProvider<AppLanguage>.value(value: _language),
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
