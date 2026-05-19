import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _moveCtrl;
  int _etaMinutes = 18;
  Timer? _etaTimer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
    _moveCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);

    _etaTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted && _etaMinutes > 1) {
        setState(() => _etaMinutes--);
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _moveCtrl.dispose();
    _etaTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (ctx, state, _) {
        final booking = state.currentBooking;
        final providerName = booking?.provider.name ?? 'Imran Khan';
        final firstName = providerName.split(' ').first;
        final initials = providerName.split(' ').take(2).map((w) => w[0]).join();
        final rating = booking?.provider.rating.toString() ?? '4.9';

        return Scaffold(
          backgroundColor: const Color(0xFF0D0F12),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => ctx.pop(),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.arrow_back_ios_rounded,
                                color: AppColors.textSecondary, size: 13),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '$firstName is on the way',
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Map
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
                    child: _MapWidget(
                      moveCtrl: _moveCtrl,
                    ).animate().fadeIn(duration: 400.ms),
                  ),

                  // ETA card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ARRIVING IN',
                                style: GoogleFonts.jetBrainsMono(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '~ $_etaMinutes min',
                                style: GoogleFonts.inter(
                                  color: AppColors.accent,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          // Pulse dot
                          AnimatedBuilder(
                            animation: _pulseCtrl,
                            builder: (_, __) => Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 36 + _pulseCtrl.value * 16,
                                  height: 36 + _pulseCtrl.value * 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.accent
                                          .withValues(alpha: (1 - _pulseCtrl.value) * 0.5),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 350.ms),
                  ),

                  // Provider card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: AppColors.goldGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initials,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF1A1208),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  providerName,
                                  style: GoogleFonts.inter(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '★ $rating · AC technician',
                                  style: GoogleFonts.jetBrainsMono(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Action buttons
                          Row(
                            children: [
                              _actionBtn('📞'),
                              const SizedBox(width: 8),
                              _actionBtn('💬'),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms, duration: 350.ms),
                  ),

                  // Steps timeline
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 32),
                    child: Column(
                      children: [
                        _Step(
                          label: 'Booking confirmed',
                          time: '09:41 AM',
                          state: _StepState.done,
                          isLast: false,
                        ),
                        _Step(
                          label: 'Provider en route',
                          time: '09:58 AM',
                          state: _StepState.active,
                          isLast: false,
                        ),
                        _Step(
                          label: 'Arrived at your location',
                          time: '10:30 AM (est.)',
                          state: _StepState.todo,
                          isLast: false,
                        ),
                        _Step(
                          label: 'Service complete',
                          time: '—',
                          state: _StepState.todo,
                          isLast: true,
                        ),
                      ],
                    ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _actionBtn(String emoji) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line2),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 16)),
    );
  }
}

class _MapWidget extends StatelessWidget {
  final AnimationController moveCtrl;

  const _MapWidget({required this.moveCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        gradient: const LinearGradient(
          colors: [Color(0xFF1C1612), Color(0xFF0D0F12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Grid lines
          CustomPaint(
            painter: _GridPainter(),
            child: const SizedBox.expand(),
          ),

          // Route line
          Positioned.fill(
            child: CustomPaint(painter: _RoutePainter()),
          ),

          // Home pin (🏠 at ~65%, 30%)
          Positioned(
            left: null,
            right: 80,
            top: 40,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.accent.withValues(alpha: 0.25), blurRadius: 0, spreadRadius: 4),
                ],
              ),
              alignment: Alignment.center,
              child: const Text('🏠', style: TextStyle(fontSize: 13)),
            ),
          ),

          // Provider pin (animated)
          AnimatedBuilder(
            animation: moveCtrl,
            builder: (_, __) {
              final offset = moveCtrl.value * 40;
              return Positioned(
                left: 40 + offset,
                top: 90 + offset * 0.3,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppColors.gold.withValues(alpha: 0.25), blurRadius: 0, spreadRadius: 4),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text('🛵', style: TextStyle(fontSize: 13)),
                ),
              );
            },
          ),

          // Label overlay
          Positioned(
            bottom: 10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Live tracking',
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.accent,
                  fontSize: 9,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.22, size.height * 0.65)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.35,
        size.width * 0.70,
        size.height * 0.30,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum _StepState { done, active, todo }

class _Step extends StatelessWidget {
  final String label;
  final String time;
  final _StepState state;
  final bool isLast;

  const _Step({
    required this.label,
    required this.time,
    required this.state,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = state == _StepState.done;
    final isActive = state == _StepState.active;
    final dotColor = isDone
        ? AppColors.accent
        : isActive
            ? AppColors.accent
            : AppColors.surfaceHighest;
    final dotBorder = isActive ? AppColors.accent : AppColors.line2;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline column
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(top: 3),
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: dotBorder, width: 2),
                boxShadow: isActive
                    ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 8)]
                    : null,
              ),
              child: isDone
                  ? const Icon(Icons.check, color: Color(0xFF1A0A05), size: 7)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 1,
                height: 36,
                color: isDone ? AppColors.accent.withValues(alpha: 0.4) : AppColors.line,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: isDone || isActive ? AppColors.textPrimary : AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
