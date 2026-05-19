import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../agents/bharosa_agent.dart';
import '../theme/app_colors.dart';
import 'trust_score_bar.dart';

class ProviderCard extends StatelessWidget {
  final BharosaReport report;
  final bool isTop;
  final VoidCallback? onBook;
  final int index;

  const ProviderCard({
    super.key,
    required this.report,
    this.isTop = false,
    this.onBook,
    this.index = 0,
  });

  Color get _recColor {
    switch (report.recommendation) {
      case BharosaRecommendation.strongYes: return AppColors.primary;
      case BharosaRecommendation.yes: return AppColors.agentBharosa;
      case BharosaRecommendation.caution: return AppColors.warning;
      case BharosaRecommendation.avoid: return AppColors.error;
    }
  }

  String get _recLabel {
    switch (report.recommendation) {
      case BharosaRecommendation.strongYes: return 'STRONG YES';
      case BharosaRecommendation.yes: return 'TRUSTED';
      case BharosaRecommendation.caution: return 'CAUTION';
      case BharosaRecommendation.avoid: return 'AVOID';
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = report.provider;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: isTop
            ? LinearGradient(
                colors: [AppColors.primaryContainer.withValues(alpha: 0.3), AppColors.surfaceCard],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTop ? AppColors.primary.withValues(alpha: 0.4) : AppColors.divider,
          width: isTop ? 1.5 : 1,
        ),
        boxShadow: isTop
            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))]
            : null,
      ),
      child: Column(
        children: [
          // Top bar for "Top Pick"
          if (isTop)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.workspace_premium, color: AppColors.primary, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'KHIDMAT TOP PICK · BHAROSA VERIFIED',
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.agentBharosa.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.agentBharosa.withValues(alpha: 0.3)),
                      ),
                      child: Center(
                        child: Text(
                          p.name.substring(0, 1),
                          style: GoogleFonts.inter(
                            color: AppColors.agentBharosa,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: AppColors.textMuted, size: 12),
                              const SizedBox(width: 3),
                              Text(
                                p.location,
                                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.near_me, color: AppColors.textMuted, size: 11),
                              const SizedBox(width: 2),
                              Text(
                                '${p.distanceKm} km',
                                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Trust badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _recColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _recColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        _recLabel,
                        style: GoogleFonts.inter(
                          color: _recColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                TrustScoreBar(score: report.trustScore),

                const SizedBox(height: 12),

                // Stats row
                Row(
                  children: [
                    _stat(Icons.star, '${p.rating}', 'Rating', AppColors.warning),
                    _stat(Icons.check_circle_outline, '${(p.completionRate * 100).round()}%', 'Complete', AppColors.primary),
                    _stat(Icons.flash_on, '${p.responseTimeMinutes}m', 'Response', AppColors.agentFaham),
                    _stat(Icons.people_alt_outlined, '${p.communityVouches}', 'Vouches', AppColors.agentMolBhaav),
                  ],
                ),

                const SizedBox(height: 12),

                // Price
                Row(
                  children: [
                    Text('Price Range ', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
                    Text(
                      p.priceRange,
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (p.availableSlots.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${p.availableSlots.length} slots today',
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),

                // Strengths
                if (report.strengths.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: report.strengths.take(2).map((s) => _chip(s, AppColors.trustHigh)).toList(),
                  ),
                ],

                // Red flags
                if (report.redFlags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: report.redFlags.take(1).map((f) => _chip(f, AppColors.error)).toList(),
                  ),
                ],

                const SizedBox(height: 12),

                // Book button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onBook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isTop ? AppColors.primary : AppColors.surfaceHighest,
                      foregroundColor: isTop ? AppColors.onPrimary : AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      isTop ? 'Book Top Provider' : 'Book ${p.name}',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (index * 100).ms, duration: 400.ms)
        .slideY(begin: 0.05, end: 0, delay: (index * 100).ms, duration: 400.ms);
  }

  Widget _stat(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 12),
              const SizedBox(width: 3),
              Text(value, style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          Text(label, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
