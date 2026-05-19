import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) context.go('/welcome');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Radial glow behind logo
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF14100E), Color(0xFF0D0F12)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.22),
                  radius: 0.7,
                  colors: [Color(0x33E06A4A), Colors.transparent],
                ),
              ),
            ),
          ),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo mark
                Container(
                  width: 124,
                  height: 124,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66E06A4A),
                        blurRadius: 60,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'K',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF1A0A05),
                      fontSize: 76,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -3,
                      height: 1,
                    ),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 0.97, end: 1.0, duration: 2000.ms, curve: Curves.easeInOut),

                const SizedBox(height: 36),

                Text(
                  'Khidmat',
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.88,
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

                const SizedBox(height: 14),

                Text(
                  'خدمت',
                  style: GoogleFonts.notoNaskhArabic(
                    color: AppColors.accent,
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

                const SizedBox(height: 30),

                Text(
                  'Aap ki khidmat mein',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 16,
                    letterSpacing: 0.6,
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 500.ms),
              ],
            ),
          ),

          // Spinner at bottom
          Positioned(
            bottom: 70,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.18),
                ),
              ),
            ).animate().fadeIn(delay: 900.ms, duration: 400.ms),
          ),
        ],
      ),
    );
  }
}
