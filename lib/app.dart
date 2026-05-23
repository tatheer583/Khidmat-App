import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/app_state.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/service_request_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/processing_screen.dart';
import 'screens/provider_list_screen.dart';
import 'screens/negotiation_screen.dart';
import 'screens/booking_summary_screen.dart';
import 'screens/tracking_screen.dart';
import 'screens/agent_logs_screen.dart';
import 'screens/help_screen.dart';
import 'screens/customer/customer_shell.dart';
import 'screens/provider/provider_shell.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (ctx, state) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (ctx, state) => const OnboardingScreen()),
    GoRoute(path: '/welcome', builder: (ctx, state) => const WelcomeScreen()),
    GoRoute(path: '/otp', builder: (ctx, state) => const OtpScreen()),

    // Service request flow
    GoRoute(
      path: '/request',
      builder: (ctx, state) => ServiceRequestScreen(
        prefilledService: state.extra as String?,
      ),
    ),

    // Customer flow (shell with bottom nav)
    GoRoute(path: '/customer', builder: (ctx, state) => const CustomerShell()),
    GoRoute(path: '/home', builder: (ctx, state) => const CustomerShell()),

    // Provider flow (shell with bottom nav)
    GoRoute(path: '/provider', builder: (ctx, state) => const ProviderShell()),

    // Booking pipeline screens
    GoRoute(path: '/processing', builder: (ctx, state) => const ProcessingScreen()),
    GoRoute(path: '/providers', builder: (ctx, state) => const ProviderListScreen()),
    GoRoute(path: '/negotiation', builder: (ctx, state) => const NegotiationScreen()),
    GoRoute(path: '/booking', builder: (ctx, state) => const BookingSummaryScreen()),
    GoRoute(path: '/tracking', builder: (ctx, state) => const TrackingScreen()),
    GoRoute(path: '/logs', builder: (ctx, state) => const AgentLogsScreen()),
    GoRoute(path: '/help', builder: (ctx, state) => const HelpScreen()),
  ],
);

class KhidmatApp extends StatelessWidget {
  const KhidmatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp.router(
        title: 'KHIDMAT',
        theme: AppTheme.darkTheme,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
