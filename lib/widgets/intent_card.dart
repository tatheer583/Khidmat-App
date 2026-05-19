import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chat_message.dart';
import '../theme/app_colors.dart';

class IntentCard extends StatelessWidget {
  final ParsedIntent intent;
  final VoidCallback? onViewProviders;

  const IntentCard({super.key, required this.intent, this.onViewProviders});

  Color get _urgencyColor {
    switch (intent.urgency) {
      case UrgencyLevel.high: return AppColors.error;
      case UrgencyLevel.medium: return AppColors.warning;
      case UrgencyLevel.low: return AppColors.trustHigh;
    }
  }

  String get _urgencyLabel {
    switch (intent.urgency) {
      case UrgencyLevel.high: return 'HIGH';
      case UrgencyLevel.medium: return 'MEDIUM';
      case UrgencyLevel.low: return 'LOW';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        margin: const EdgeInsets.only(left: 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.agentFaham.withValues(alpha: 0.12), AppColors.agentFaham.withValues(alpha: 0.04)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.agentFaham.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.agentFaham.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.agentFaham, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'FAHAM Agent · Intent Extracted',
                    style: GoogleFonts.inter(
                      color: AppColors.agentFaham,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.agentFaham.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      intent.detectedLanguage,
                      style: GoogleFonts.inter(
                        color: AppColors.agentFaham,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _row(Icons.build_circle_outlined, 'Service', intent.serviceType, AppColors.primary),
                  const SizedBox(height: 8),
                  _row(Icons.location_on_outlined, 'Location', intent.location, AppColors.agentDhoond),
                  const SizedBox(height: 8),
                  _row(Icons.access_time, 'Time', intent.time, AppColors.agentBook),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(width: 22),
                      const SizedBox(width: 8),
                      Text('Urgency', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _urgencyColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _urgencyColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          _urgencyLabel,
                          style: GoogleFonts.inter(
                            color: _urgencyColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (intent.budget != null) ...[
                    const SizedBox(height: 8),
                    _row(Icons.account_balance_wallet_outlined, 'Budget', 'Rs. ${intent.budget}', AppColors.agentMolBhaav),
                  ],
                  if (intent.specialNotes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _row(Icons.notes, 'Notes', intent.specialNotes, AppColors.textSecondary),
                  ],
                  if (onViewProviders != null) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onViewProviders,
                        icon: const Icon(Icons.people_alt_outlined, size: 16),
                        label: const Text('View Matched Providers'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOut),
    );
  }

  Widget _row(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
