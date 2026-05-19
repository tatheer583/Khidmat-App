import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  final List<_TraceLine> _lines = [];
  bool _navigated = false;
  Timer? _dotTimer;
  int _dotCount = 1;

  static const _startTime = '09:41';

  @override
  void initState() {
    super.initState();
    _dotTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _dotCount = (_dotCount % 3) + 1);
    });
    _seedInitialLines();
  }

  void _seedInitialLines() {
    Future.delayed(200.ms, () => _addLine('stt', 'heard', null, null));
    Future.delayed(900.ms, () => _addLine('intent', null, null, null, special: 'parsing'));
    Future.delayed(1800.ms, () => _addLine('slot', null, null, null, special: 'slot'));
    Future.delayed(2600.ms, () => _addLine('geo', null, null, null, special: 'geo'));
    Future.delayed(3500.ms, () => _addLine('find', null, null, null, special: 'find'));
    Future.delayed(4400.ms, () => _addLine('rank', null, null, null, special: 'rank'));
    Future.delayed(5100.ms, () => _addLine('match', null, null, null, special: 'match'));
  }

  void _addLine(String key, String? value, String? dim, String? arrow, {String? special}) {
    if (!mounted) return;
    setState(() => _lines.add(_TraceLine(key: key, value: value, dim: dim, arrow: arrow, special: special)));
  }

  @override
  void dispose() {
    _dotTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (ctx, state, _) {
        if (!_navigated && state.rankedProviders != null) {
          _navigated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/providers');
          });
        }

        final intent = state.currentIntent;
        final query = state.currentQuery ?? '';

        return Scaffold(
          body: Stack(
            children: [
              // Radial glow background
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF0E0A09),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.6),
                      radius: 0.7,
                      colors: [Color(0x2EE06A4A), Colors.transparent],
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 4, 22, 14),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.go('/home'),
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
                            'Thinking${'.' * _dotCount}',
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Quote card
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              query.contains('AC') || query.contains('ac') || query.contains('اے سی')
                                  ? 'میرا اے سی ٹھنڈا نہیں کر رہا'
                                  : query,
                              style: GoogleFonts.notoNaskhArabic(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                height: 1.3,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '"$query" — heard',
                              style: GoogleFonts.inter(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
                    ),

                    // Trace terminal
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF06080A),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Terminal header
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(color: AppColors.accent.withValues(alpha: 0.6), blurRadius: 6),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'khidmat.agent · trace',
                                    style: GoogleFonts.jetBrainsMono(
                                      color: AppColors.textMuted,
                                      fontSize: 10,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Trace lines
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _lines.length,
                                  itemBuilder: (_, i) => _buildTraceLine(_lines[i], intent, query),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Extracted info
                    if (intent != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CONFIRMED',
                                style: GoogleFonts.jetBrainsMono(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _extractedRow('Service', intent.serviceType),
                              const SizedBox(height: 8),
                              _extractedRow('Where', intent.location),
                              const SizedBox(height: 8),
                              _extractedRow('When', intent.time),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 400.ms)
                            .slideY(begin: 0.1, end: 0),
                      ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTraceLine(_TraceLine line, intent, String query) {
    String timeStr = _startTime;
    String keyStr = line.key;
    String valueStr = line.value ?? '';
    Color keyColor = AppColors.accent;
    Color valueColor = AppColors.textPrimary;

    switch (line.special) {
      case 'parsing':
        keyStr = 'intent';
        valueStr = 'ac_repair';
        break;
      case 'slot':
        keyStr = 'slot';
        valueStr = 'not_cooling';
        break;
      case 'geo':
        keyStr = 'geo';
        valueStr = intent?.location ?? 'DHA Phase 5';
        break;
      case 'find':
        keyStr = 'find';
        valueStr = '42 prov';
        break;
      case 'rank':
        keyStr = 'rank';
        valueStr = 'dist · ★ · slot';
        break;
      case 'match':
        keyStr = '✓ match';
        valueStr = 'Imran';
        keyColor = AppColors.accent;
        valueColor = AppColors.textPrimary;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            timeStr,
            style: GoogleFonts.jetBrainsMono(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(width: 8),
          Text(
            keyStr,
            style: GoogleFonts.jetBrainsMono(color: keyColor, fontSize: 11),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              valueStr,
              style: GoogleFonts.jetBrainsMono(color: valueColor, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (line.special == 'find')
            Text(
              ' → 8',
              style: GoogleFonts.jetBrainsMono(color: AppColors.gold, fontSize: 11),
            ),
          if (line.dim != null)
            Text(
              '  ${line.dim}',
              style: GoogleFonts.jetBrainsMono(color: AppColors.textMuted, fontSize: 11),
            ),
        ],
      ).animate().fadeIn(duration: 250.ms).slideX(begin: -0.05, end: 0),
    );
  }

  Widget _extractedRow(String key, String value) {
    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            key.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textMuted,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: AppColors.accent, size: 10),
        ),
      ],
    );
  }
}

class _TraceLine {
  final String key;
  final String? value;
  final String? dim;
  final String? arrow;
  final String? special;

  _TraceLine({required this.key, this.value, this.dim, this.arrow, this.special});
}
