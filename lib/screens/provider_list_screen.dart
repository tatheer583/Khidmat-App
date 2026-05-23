import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../agents/bharosa_agent.dart';
import '../theme/app_colors.dart';

class ProviderListScreen extends StatelessWidget {
  const ProviderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AppState>(
        builder: (ctx, state, _) {
          final providers = state.rankedProviders;
          final req = state.serviceRequest;
          final count = providers?.length ?? 0;

          return SafeArea(
            child: Column(
              children: [
                _buildTopBar(ctx, count, providers != null),
                if (req != null) _buildRequestSummary(ctx, req),
                if (providers == null)
                  const Expanded(child: _LoadingBody())
                else
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      children: [
                        _buildAIReasoningCard(state),
                        const SizedBox(height: 12),
                        ...providers.take(5).toList().asMap().entries.map((e) =>
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ProviderCard(
                              report: e.value,
                              isTop: e.key == 0,
                              index: e.key,
                              req: req,
                              onBook: () async {
                                await state.startNegotiation(e.value);
                                if (ctx.mounted) ctx.push('/negotiation');
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext ctx, int count, bool hasResults) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => ctx.go('/customer'),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.line2),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textSecondary, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasResults ? '$count Providers Found' : 'Searching…',
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  hasResults ? 'Ranked by AI trust score' : 'AI is analyzing providers',
                  style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => ctx.push('/logs'),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.terminal_rounded, color: AppColors.accent, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestSummary(BuildContext ctx, ServiceRequest req) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.accent.withValues(alpha: 0.14),
          AppColors.surfaceCard,
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(req.service,
                    style: GoogleFonts.inter(
                        color: const Color(0xFF1A0A05),
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _urgencyColor(req.urgency).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(req.urgency.toUpperCase(),
                    style: GoogleFonts.robotoMono(
                        color: _urgencyColor(req.urgency),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => ctx.go('/request'),
                child: Text('Edit',
                    style: GoogleFonts.inter(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _chip(Icons.calendar_today_rounded, req.date != null
                  ? DateFormat('d MMM').format(req.date!)
                  : 'Flexible'),
              const SizedBox(width: 8),
              _chip(Icons.access_time_rounded, req.time != null
                  ? req.time!.format(ctx)
                  : 'Flexible'),
              const SizedBox(width: 8),
              _chip(Icons.account_balance_wallet_rounded,
                  'Rs ${NumberFormat('#,###').format(req.budgetMin)}–${NumberFormat('#,###').format(req.budgetMax)}'),
            ],
          ),
          if (req.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(req.notes,
                style: GoogleFonts.inter(
                    color: AppColors.textMuted, fontSize: 11.5, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Color _urgencyColor(String u) {
    switch (u) {
      case 'Urgent': return AppColors.error;
      case 'Today': return AppColors.warning;
      default: return AppColors.success;
    }
  }

  Widget _buildAIReasoningCard(AppState state) {
    final top = state.rankedProviders?.first;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.info.withValues(alpha: 0.08),
          AppColors.surfaceCard,
        ]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.psychology_rounded, color: AppColors.info, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI REASONING',
                    style: GoogleFonts.robotoMono(
                        color: AppColors.info, fontSize: 9.5, letterSpacing: 1.5)),
                const SizedBox(height: 3),
                Text(
                  top != null
                      ? '${top.provider.name} ranked #1 — closest, highest trust score (${top.trustScore}/100), available in your time slot.'
                      : 'Analyzing providers by distance, rating, and trust score…',
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary, fontSize: 12.5, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }
}

// ─── Provider Card ─────────────────────────────────
class _ProviderCard extends StatelessWidget {
  final BharosaReport report;
  final bool isTop;
  final int index;
  final ServiceRequest? req;
  final VoidCallback onBook;

  const _ProviderCard({
    required this.report,
    required this.isTop,
    required this.index,
    this.req,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final p = report.provider;
    final initials = p.name.split(' ').take(2).map((w) => w[0]).join();
    final distances = ['1.2 km', '2.8 km', '3.4 km', '4.1 km', '5.3 km'];
    final etas = ['~30 min', '~45 min', '~1 hr', '~1.5 hr', '~2 hr'];
    final dist = index < distances.length ? distances[index] : '${index + 1}.0 km';
    final eta = index < etas.length ? etas[index] : '~2 hr';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isTop ? AppColors.accent.withValues(alpha: 0.5) : AppColors.line,
          width: isTop ? 1.5 : 1,
        ),
        boxShadow: isTop
            ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.12), blurRadius: 20)]
            : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (isTop)
            Positioned(
              top: -10,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 8)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: Color(0xFF1A0A05), size: 11),
                    const SizedBox(width: 4),
                    Text('AI Top Pick',
                        style: GoogleFonts.inter(
                            color: const Color(0xFF1A0A05),
                            fontSize: 10,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(14, isTop ? 20 : 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: isTop ? AppColors.primaryGradient : AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isTop
                            ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 10)]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(initials,
                          style: GoogleFonts.inter(
                              color: const Color(0xFF1A0A05),
                              fontSize: 18,
                              fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(p.name,
                                  style: GoogleFonts.inter(
                                      color: AppColors.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(width: 6),
                              const Icon(Icons.verified_rounded,
                                  color: AppColors.info, size: 15),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(p.category,
                              style: GoogleFonts.inter(
                                  color: AppColors.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _trustBadge(report.trustScore),
                        const SizedBox(height: 4),
                        Text('Rs ${p.priceMin}–${p.priceMax}',
                            style: GoogleFonts.inter(
                                color: AppColors.textMuted, fontSize: 10.5)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Stats chips
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _statChip('⭐', '${p.rating} (${p.reviewCount})', AppColors.gold),
                    _statChip('📍', dist, AppColors.info),
                    _statChip('⏱', eta, AppColors.success),
                    _statChip('✅', '${p.completionRate}% done', AppColors.success),
                  ],
                ),
                // Budget match indicator
                if (req != null) ...[
                  const SizedBox(height: 10),
                  _buildBudgetMatch(req!, p.priceMin, p.priceMax),
                ],
                const SizedBox(height: 12),
                // Available slots
                Text('Available slots:',
                    style: GoogleFonts.inter(
                        color: AppColors.textMuted, fontSize: 11)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: p.availableSlots.take(3).map((s) {
                    final isPreferred = req?.time != null &&
                        s.contains(req!.time!.format(context).substring(0, 2));
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isPreferred
                            ? AppColors.accent.withValues(alpha: 0.15)
                            : AppColors.surfaceHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isPreferred
                              ? AppColors.accent.withValues(alpha: 0.5)
                              : AppColors.line2,
                        ),
                      ),
                      child: Text(s,
                          style: GoogleFonts.robotoMono(
                            color: isPreferred ? AppColors.accent : AppColors.textSecondary,
                            fontSize: 10.5,
                            fontWeight: isPreferred ? FontWeight.w700 : FontWeight.w400,
                          )),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                // Book button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onBook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isTop ? AppColors.accent : AppColors.surfaceHighest,
                      foregroundColor: isTop ? const Color(0xFF1A0A05) : AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      isTop
                          ? 'Book ${p.name.split(' ').first} — Rs ${p.priceMin}'
                          : 'Book for Rs ${p.priceMin}',
                      style: GoogleFonts.inter(
                          fontSize: 13.5, fontWeight: FontWeight.w800),
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
        .fadeIn(delay: (index * 100).ms, duration: 350.ms)
        .slideY(begin: 0.06, end: 0, delay: (index * 100).ms, duration: 350.ms);
  }

  Widget _trustBadge(int score) {
    final color = score >= 80
        ? AppColors.success
        : score >= 60
            ? AppColors.warning
            : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_rounded, color: color, size: 11),
          const SizedBox(width: 3),
          Text('$score',
              style: GoogleFonts.inter(
                  color: color, fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _statChip(String emoji, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBudgetMatch(ServiceRequest req, int priceMin, int priceMax) {
    final withinBudget = priceMin <= req.budgetMax;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: withinBudget
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: withinBudget
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            withinBudget ? Icons.check_circle_rounded : Icons.info_rounded,
            color: withinBudget ? AppColors.success : AppColors.warning,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            withinBudget
                ? 'Within your budget of Rs ${NumberFormat('#,###').format(req.budgetMax)}'
                : 'Slightly above budget — AI will negotiate',
            style: GoogleFonts.inter(
              color: withinBudget ? AppColors.success : AppColors.warning,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Loading Body ──────────────────────────────────
class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
            ),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 20),
          Text('BHAROSA ranking providers…',
              style: GoogleFonts.robotoMono(
                  color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 8),
          Text('Checking trust scores & availability',
              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}
