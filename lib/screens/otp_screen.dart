import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<String> _digits = ['4', '7', '2', '9', '', ''];
  int _activeIndex = 4;
  int _resendSeconds = 24;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F12),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 16),
                ),
              ),

              const SizedBox(height: 36),

              Text(
                'Verify your number',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.15, end: 0),

              const SizedBox(height: 10),

              RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14, height: 1.4),
                  children: [
                    const TextSpan(text: 'We sent a 6-digit code to\n'),
                    TextSpan(
                      text: '+92 312 4567 890',
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

              const SizedBox(height: 28),

              // PIN boxes
              Row(
                children: List.generate(6, (i) {
                  final filled = _digits[i].isNotEmpty;
                  final active = i == _activeIndex;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < 5 ? 10 : 0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: active ? AppColors.accent : AppColors.line2,
                            width: active ? 1.5 : 1,
                          ),
                          boxShadow: active
                              ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.18), blurRadius: 8)]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          filled ? _digits[i] : '·',
                          style: GoogleFonts.robotoMono(
                            color: filled ? AppColors.textPrimary : AppColors.textMuted,
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Didn't get a code?",
                    style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
                  ),
                  Text(
                    _resendSeconds > 0 ? 'Resend in ${_resendSeconds}s' : 'Resend now',
                    style: GoogleFonts.inter(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              GestureDetector(
                onTap: () => context.go('/home'),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Color(0x40E06A4A), blurRadius: 16)],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Verify & continue',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF1A0A05),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 18),

              Center(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
                    children: [
                      const TextSpan(text: 'Trouble signing in? '),
                      TextSpan(
                        text: 'Use another method',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
