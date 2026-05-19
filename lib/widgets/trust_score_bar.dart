import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class TrustScoreBar extends StatelessWidget {
  final int score;
  final bool showLabel;
  final double height;

  const TrustScoreBar({
    super.key,
    required this.score,
    this.showLabel = true,
    this.height = 6,
  });

  Color get _color {
    if (score >= 75) return AppColors.trustHigh;
    if (score >= 50) return AppColors.trustMedium;
    return AppColors.trustLow;
  }

  String get _label {
    if (score >= 80) return 'Highly Trusted';
    if (score >= 65) return 'Trusted';
    if (score >= 45) return 'Caution';
    return 'Low Trust';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trust Score',
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                children: [
                  Text(
                    '$score',
                    style: GoogleFonts.inter(
                      color: _color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '/100',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _label,
                      style: GoogleFonts.inter(
                        color: _color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Stack(
            children: [
              Container(
                height: height,
                color: AppColors.divider,
              ),
              FractionallySizedBox(
                widthFactor: score / 100,
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_color.withValues(alpha: 0.7), _color]),
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
              )
                  .animate()
                  .custom(
                    duration: 1200.ms,
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => FractionallySizedBox(
                      widthFactor: (score / 100) * value,
                      child: child,
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
