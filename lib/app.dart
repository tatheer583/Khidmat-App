import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'localization/app_language.dart';
import 'screens/onboarding_screen.dart';
import 'screens/worker_home_screen.dart';
import 'screens/worker_profile_screen.dart';
import 'theme/app_theme.dart';
import 'services/app_state.dart';
import 'services/backend_session.dart';
import 'screens/setup_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/home_screen.dart';
import 'screens/provider_list_screen.dart';
import 'screens/negotiation_screen.dart';
import 'screens/booking_summary_screen.dart';
import 'screens/bookings_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/account_screen.dart';
import 'screens/provider_dashboard_screen.dart';
import 'screens/agent_logs_screen.dart';
import 'screens/help_screen.dart';

class KhidmatApp extends StatefulWidget {
  final BackendSession? session;
  const KhidmatApp({super.key, this.session});
  @override
  State<KhidmatApp> createState() => _KhidmatAppState();
}

class _KhidmatAppState extends State<KhidmatApp> {
  late final BackendSession _session;
  late final AppState _state;
  late final GoRouter _router;
  final AppLanguage _language = AppLanguage();
  void _languageChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _language.addListener(_languageChanged);
    unawaited(_language.load());
    _session = widget.session ?? BackendSession();
    _state = AppState(_session);
    _router = GoRouter(
      initialLocation: '/home',
      refreshListenable: _session,
      redirect: (context, state) {
        final path = state.uri.path;
        if (!_session.ready) return path == '/setup' ? null : '/setup';
        if (!_session.signedIn) {
          return path == '/welcome' || path == '/otp' ? null : '/welcome';
        }
        if (!_session.profileComplete) {
          return path == '/onboarding' ? null : '/onboarding';
        }
        if (path == '/onboarding') return '/home';
        if (!_session.isWorker && path == '/provider') return '/home';
        if (['/', '/setup', '/welcome', '/otp'].contains(path)) return '/home';
        return null;
      },
      routes: [
        GoRoute(path: '/', redirect: (_, state) => '/home'),
        GoRoute(path: '/setup', builder: (_, state) => const SetupScreen()),
        GoRoute(path: '/welcome', builder: (_, state) => const WelcomeScreen()),
        GoRoute(path: '/otp', builder: (_, state) => const OtpScreen()),
        GoRoute(
          path: '/onboarding',
          builder: (_, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/profile/edit',
          builder: (_, state) => const OnboardingScreen(editing: true),
        ),
        GoRoute(
          path: '/worker/:id',
          builder: (_, state) =>
              WorkerProfileScreen(providerId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/home',
          builder: (_, state) =>
              _session.isWorker ? const WorkerHomeScreen() : const HomeScreen(),
        ),
        GoRoute(
          path: '/providers',
          builder: (_, state) => const ProviderListScreen(),
        ),
        GoRoute(
          path: '/negotiation',
          builder: (_, state) => const NegotiationScreen(),
        ),
        GoRoute(
          path: '/bookings',
          builder: (_, state) => const BookingsScreen(),
        ),
        GoRoute(
          path: '/booking/:id',
          builder: (_, state) =>
              BookingSummaryScreen(bookingId: state.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'chat',
              builder: (_, state) =>
                  ChatScreen(bookingId: state.pathParameters['id']!),
            ),
          ],
        ),
        GoRoute(path: '/account', builder: (_, state) => const AccountScreen()),
        GoRoute(
          path: '/provider',
          builder: (_, state) => const ProviderDashboardScreen(),
        ),
        GoRoute(path: '/logs', builder: (_, state) => const AgentLogsScreen()),
        GoRoute(path: '/help', builder: (_, state) => const HelpScreen()),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Khidmat')),
        body: Center(
          child: TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('Return home'),
          ),
        ),
      ),
    );
    if (widget.session == null) unawaited(_session.initialize());
  }

  @override
  void dispose() {
    _router.dispose();
    _language.removeListener(_languageChanged);
    _language.dispose();
    _state.dispose();
    if (widget.session == null) _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider<BackendSession>.value(value: _session),
      ChangeNotifierProvider<AppState>.value(value: _state),
      ChangeNotifierProvider<AppLanguage>.value(value: _language),
    ],
    child: MaterialApp.router(
      title: 'KHIDMAT',
      locale: _language.locale,
      supportedLocales: const [Locale('en'), Locale('ur')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    ),
  );
}
