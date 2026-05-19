import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0E0B0A), Color(0xFF0D0F12)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.6],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Hero
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(color: Color(0x40E06A4A), blurRadius: 24),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'K',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF1A0A05),
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      )
                          .animate()
                          .scaleXY(begin: 0.8, end: 1.0, duration: 400.ms, curve: Curves.easeOut),

                      const SizedBox(height: 28),

                      Text(
                        'Welcome to Khidmat',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                        ),
                      ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.15, end: 0),

                      const SizedBox(height: 10),

                      Text(
                        'خوش آمدید',
                        style: GoogleFonts.notoNaskhArabic(
                          color: AppColors.textSecondary,
                          fontSize: 26,
                          height: 1,
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                      const SizedBox(height: 14),

                      Text(
                        'Find trusted help nearby —\nby voice, in your language.',
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 15,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
                    ],
                  ),
                ),

                // Buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: Column(
                    children: [
                      _Btn(
                        label: 'Sign up with phone',
                        primary: true,
                        onTap: () => context.push('/otp'),
                      ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.15, end: 0),

                      const SizedBox(height: 12),

                      _Btn(
                        label: 'Continue with Google',
                        googleIcon: true,
                        onTap: () => context.go('/home'),
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.15, end: 0),

                      const SizedBox(height: 12),

                      _Btn(
                        label: 'I already have an account',
                        onTap: () => context.go('/home'),
                      ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.15, end: 0),

                      const SizedBox(height: 10),

                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
                          children: [
                            const TextSpan(text: 'By continuing you agree to our '),
                            TextSpan(
                              text: 'Terms',
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.textSecondary,
                              ),
                            ),
                            const TextSpan(text: ' & '),
                            TextSpan(
                              text: 'Privacy',
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.textSecondary,
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ).animate().fadeIn(delay: 500.ms),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final bool primary;
  final bool googleIcon;
  final VoidCallback onTap;

  const _Btn({
    required this.label,
    this.primary = false,
    this.googleIcon = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: primary ? AppColors.accent : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: primary ? null : Border.all(color: AppColors.line2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (googleIcon) ...[
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Text(
                  'G',
                  style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                color: primary ? const Color(0xFF1A0A05) : AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
