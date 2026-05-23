import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/app_state.dart';
import '../../theme/app_colors.dart';

class ProviderReviewsScreen extends StatelessWidget {
  const ProviderReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Reviews'), centerTitle: false),
      body: Consumer<AppState>(
        builder: (_, state, __) {
          final reviews = state.reviews;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _summary(state),
              const SizedBox(height: 18),
              ...reviews.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _reviewCard(r.customerName, r.customerInitial, r.rating,
                        r.comment, r.service, r.date),
                  )),
            ],
          );
        },
      ),
    );
  }

  Widget _summary(AppState state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.gold.withValues(alpha: 0.15),
          AppColors.surfaceCard,
        ]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(state.providerAvgRating.toStringAsFixed(1),
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      height: 1)),
              const SizedBox(height: 4),
              Row(
                  children: List.generate(
                      5,
                      (i) => Icon(
                            i < state.providerAvgRating.round()
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: AppColors.gold,
                            size: 18,
                          ))),
              const SizedBox(height: 4),
              Text('${state.reviews.length} reviews',
                  style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((s) {
                final count =
                    state.reviews.where((r) => r.rating.round() == s).length;
                final pct = state.reviews.isEmpty ? 0.0 : count / state.reviews.length;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text('$s',
                          style: GoogleFonts.robotoMono(
                              color: AppColors.textMuted, fontSize: 11)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 4,
                            backgroundColor: AppColors.surfaceHighest,
                            valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(String name, String initial, double rating, String comment,
          String service, DateTime date) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(initial,
                      style: GoogleFonts.inter(
                          color: const Color(0xFF1A1208),
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      Text('$service · ${DateFormat('d MMM').format(date)}',
                          style: GoogleFonts.inter(
                              color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
                Row(
                    children: List.generate(
                        5,
                        (i) => Icon(
                              i < rating.round()
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: AppColors.gold,
                              size: 14,
                            ))),
              ],
            ),
            const SizedBox(height: 10),
            Text(comment,
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 12.5, height: 1.45)),
          ],
        ),
      );
}
