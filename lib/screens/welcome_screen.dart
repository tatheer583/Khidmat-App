import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Multi-layer premium gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A0E08), Color(0xFF0D0F12), Color(0xFF080A0D)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Top glow orb
          Positioned(
            top: -100,
            right: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.accent.withValues(alpha: 0.22),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Bottom glow orb
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.gold.withValues(alpha: 0.12),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildLogo(),
                  const SizedBox(height: 28),
                  _buildTitle(),
                  const SizedBox(height: 36),
                  _buildFeatureRow(),
                  const SizedBox(height: 36),
                  _buildDivider(),
                  const SizedBox(height: 24),
                  _buildRoleCard(
                    context,
                    icon: Icons.person_search_rounded,
                    emoji: '👤',
                    title: 'I need a service',
                    subtitle:
                        'Book plumbers, electricians, AC technicians, tutors & more in minutes.',
                    accent: AppColors.accent,
                    delay: 350,
                    onTap: () {
                      context.read<AppState>().setRole(UserRole.customer);
                      context.go('/customer');
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildRoleCard(
                    context,
                    icon: Icons.handyman_rounded,
                    emoji: '🔧',
                    title: 'I provide services',
                    subtitle:
                        'Get matched with customers, manage jobs, and grow your earnings.',
                    accent: AppColors.gold,
                    delay: 450,
                    onTap: () {
                      context.read<AppState>().setRole(UserRole.provider);
                      context.go('/provider');
                    },
                  ),
                  const Spacer(),
                  _buildFooter(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x55E06A4A), blurRadius: 40, spreadRadius: 4),
            ],
          ),
          alignment: Alignment.center,
          child: Text('K',
              style: GoogleFonts.inter(
                  color: const Color(0xFF1A0A05),
                  fontSize: 50,
                  fontWeight: FontWeight.w900,
                  height: 1)),
        )
            .animate()
            .scaleXY(begin: 0.7, end: 1, duration: 500.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 16),
        Text('KHIDMAT',
            style: GoogleFonts.robotoMono(
                color: AppColors.accent,
                fontSize: 13,
                letterSpacing: 5,
                fontWeight: FontWeight.w700))
            .animate()
            .fadeIn(delay: 200.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text('Pakistan ki\nbehterein services',
            style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1.2,
                letterSpacing: -0.5),
            textAlign: TextAlign.center)
            .animate()
            .fadeIn(delay: 150.ms, duration: 400.ms)
            .slideY(begin: 0.1, end: 0),
        const SizedBox(height: 8),
        Text('AI-powered · Verified · Trusted',
            style: GoogleFonts.inter(
                color: AppColors.textMuted,
                fontSize: 14,
                height: 1.4,
                letterSpacing: 0.5))
            .animate()
            .fadeIn(delay: 250.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildFeatureRow() {
    final features = [
      (Icons.verified_user_rounded, 'Verified', AppColors.success),
      (Icons.psychology_rounded, 'AI-Powered', AppColors.accent),
      (Icons.price_check_rounded, 'Best Price', AppColors.gold),
    ];
    return Row(
      children: features.asMap().entries.map((e) {
        final i = e.key;
        final (icon, label, color) = e.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
                right: i < features.length - 1 ? 8 : 0),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 5),
                Text(label,
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (i * 80 + 200).ms, duration: 350.ms);
      }).toList(),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AppColors.line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('CHOOSE YOUR ROLE',
              style: GoogleFonts.robotoMono(
                  color: AppColors.textMuted, fontSize: 10, letterSpacing: 2)),
        ),
        Expanded(child: Container(height: 1, color: AppColors.line)),
      ],
    ).animate().fadeIn(delay: 300.ms, duration: 350.ms);
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required IconData icon,
    required String emoji,
    required String title,
    required String subtitle,
    required Color accent,
    required int delay,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.12),
              AppColors.surfaceCard,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
                color: accent.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 6))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: accent.withValues(alpha: 0.25)),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_forward_rounded, color: accent, size: 16),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms, duration: 400.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.inter(
                color: AppColors.textMuted, fontSize: 11.5, height: 1.5),
            children: [
              const TextSpan(text: 'By continuing you agree to our '),
              TextSpan(
                text: 'Terms of Service',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.underline),
              ),
              const TextSpan(text: ' and '),
              TextSpan(
                text: 'Privacy Policy',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.underline),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                  color: AppColors.success, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text('Powered by Google Gemini AI',
                style: GoogleFonts.inter(
                    color: AppColors.textMuted, fontSize: 10.5)),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 600.ms, duration: 400.ms);
  }
}
