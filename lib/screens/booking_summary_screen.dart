import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';

class BookingSummaryScreen extends StatelessWidget {
  const BookingSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (ctx, state, _) {
        final booking = state.currentBooking;
        if (booking == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF0E0A09),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('No booking found',
                      style: GoogleFonts.inter(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => ctx.go('/home'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Go Home',
                        style: GoogleFonts.inter(
                            color: const Color(0xFF1A0A05), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: Stack(
            children: [
              // Background with radial glow
              Container(color: const Color(0xFF0E0A09)),
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.7),
                      radius: 0.65,
                      colors: [Color(0x33E06A4A), Colors.transparent],
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 22),

                      // Check + title
                      Column(
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1FE06A4A),
                                  blurRadius: 0,
                                  spreadRadius: 12,
                                ),
                                BoxShadow(
                                  color: Color(0x4DE06A4A),
                                  blurRadius: 60,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '✓',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF1A0A05),
                                fontSize: 38,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                          )
                              .animate()
                              .scaleXY(
                                begin: 0.6,
                                end: 1.0,
                                duration: 500.ms,
                                curve: Curves.elasticOut,
                              )
                              .fadeIn(duration: 300.ms),

                          const SizedBox(height: 18),

                          Text(
                            'Booking confirmed',
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

                          const SizedBox(height: 4),

                          Text(
                            '${booking.provider.name.split(' ').first} is on the way',
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Receipt card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Column(
                            children: [
                              // Booking ID row (dashed separator)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'BOOKING ID',
                                      style: GoogleFonts.jetBrainsMono(
                                        color: AppColors.textMuted,
                                        fontSize: 10,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => Clipboard.setData(
                                          ClipboardData(text: booking.bookingId)),
                                      child: Text(
                                        booking.bookingId,
                                        style: GoogleFonts.jetBrainsMono(
                                          color: AppColors.accent,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _dashedDivider(),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                                child: Column(
                                  children: [
                                    _receiptRow('Service', booking.service),
                                    const SizedBox(height: 5),
                                    _receiptRow(
                                        'Provider',
                                        '${booking.provider.name} · ★ ${booking.provider.rating}'),
                                    const SizedBox(height: 5),
                                    _receiptRow('When', '${booking.date} · ${booking.time}'),
                                    const SizedBox(height: 5),
                                    _receiptRow('Where', booking.location),
                                    const SizedBox(height: 5),
                                    _receiptRow(
                                      'Estimate',
                                      'Rs. ${_fmt(booking.finalPrice > 0 ? booking.finalPrice : booking.originalPrice)} — ${_fmt(booking.originalPrice)}',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 350.ms, duration: 400.ms).slideY(begin: 0.06, end: 0),
                      ),

                      const SizedBox(height: 12),

                      // Reminder card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.20),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: const Text('⏰', style: TextStyle(fontSize: 16)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Reminder set',
                                      style: GoogleFonts.inter(
                                        color: AppColors.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "We'll ping you 30 min before — and again if ${booking.provider.name.split(' ').first} is more than 10 min late.",
                                      style: GoogleFonts.inter(
                                        color: AppColors.textMuted,
                                        fontSize: 11,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
                      ),

                      const SizedBox(height: 24),

                      // Actions
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => ctx.push('/tracking'),
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: const [
                                    BoxShadow(color: Color(0x40E06A4A), blurRadius: 16),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Track provider',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF1A0A05),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: 600.ms),

                            const SizedBox(height: 10),

                            GestureDetector(
                              onTap: () => ctx.go('/home'),
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.line2),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Back to home',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: 700.ms),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _receiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _dashedDivider() {
    return LayoutBuilder(
      builder: (_, constraints) {
        final dashWidth = 6.0;
        final dashSpace = 4.0;
        final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          children: List.generate(
            count,
            (_) => Container(
              width: dashWidth,
              height: 1,
              margin: EdgeInsets.only(right: dashSpace),
              color: AppColors.line2,
            ),
          ),
        );
      },
    );
  }

  String _fmt(int n) => n
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}
