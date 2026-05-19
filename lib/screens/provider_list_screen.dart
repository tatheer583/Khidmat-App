import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../agents/bharosa_agent.dart';
import '../theme/app_colors.dart';

class ProviderListScreen extends StatelessWidget {
  const ProviderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F12),
      body: Consumer<AppState>(
        builder: (ctx, state, _) {
          final providers = state.rankedProviders;
          final count = providers?.length ?? 0;

          return SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => ctx.go('/home'),
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
                        providers == null
                            ? 'Searching…'
                            : '$count match${count == 1 ? '' : 'es'} near you',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => ctx.push('/logs'),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.terminal_rounded, color: AppColors.accent, size: 13),
                        ),
                      ),
                    ],
                  ),
                ),

                if (providers == null)
                  const Expanded(child: _LoadingBody())
                else
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        children: [
                          // Agent reasoning card
                          Padding(
                            padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.accent.withValues(alpha: 0.10),
                                    AppColors.accent.withValues(alpha: 0.02),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.accent.withValues(alpha: 0.20)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AGENT REASONING',
                                    style: GoogleFonts.jetBrainsMono(
                                      color: AppColors.accent,
                                      fontSize: 10,
                                      letterSpacing: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.inter(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                      children: [
                                        const TextSpan(text: 'Ranked '),
                                        TextSpan(
                                          text: '#1 — closest (1.2 km)',
                                          style: GoogleFonts.inter(
                                            color: AppColors.accent,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const TextSpan(
                                          text:
                                              ', highest rating, available in the next slot.',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0),
                          ),

                          // Provider cards
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            child: Column(
                              children: providers.take(3).toList().asMap().entries.map((e) {
                                final i = e.key;
                                final p = e.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _ProviderCard(
                                    report: p,
                                    isTop: i == 0,
                                    index: i,
                                    onBook: () async {
                                      await state.startNegotiation(p);
                                      if (ctx.mounted) ctx.push('/negotiation');
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final BharosaReport report;
  final bool isTop;
  final int index;
  final VoidCallback onBook;

  const _ProviderCard({
    required this.report,
    required this.isTop,
    required this.index,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final p = report.provider;
    final initials = p.name.split(' ').take(2).map((w) => w[0]).join();
    final eta = index == 0 ? '~30 min' : index == 1 ? '~1 hr' : '~2 hr';
    final dist = index == 0 ? '1.2 km' : index == 1 ? '2.8 km' : '3.4 km';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTop
              ? AppColors.accent.withValues(alpha: 0.45)
              : AppColors.line,
          width: isTop ? 1.5 : 1,
        ),
        boxShadow: isTop
            ? [
                BoxShadow(color: AppColors.accent.withValues(alpha: 0.08), blurRadius: 24),
              ]
            : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (isTop)
            Positioned(
              top: -9,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '★ Top pick',
                  style: GoogleFonts.jetBrainsMono(
                    color: const Color(0xFF1A0A05),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Head: avatar + name + role
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: isTop
                            ? AppColors.primaryGradient
                            : AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF1A0A05),
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
                            p.name,
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${p.category} · ${p.reviewCount} reviews',
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Stats row
                Row(
                  children: [
                    _stat('★', '${p.rating}', '·${p.reviewCount}'),
                    const SizedBox(width: 14),
                    _stat('📍', dist, null),
                    const SizedBox(width: 14),
                    _stat('⏱', eta, null),
                  ],
                ),

                // CTA for top pick only
                if (isTop) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: onBook,
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Book ${p.name.split(' ').first} — Rs. ${p.priceMin}',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF1A0A05),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
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
        .fadeIn(delay: (index * 120).ms, duration: 350.ms)
        .slideY(begin: 0.1, end: 0, delay: (index * 120).ms, duration: 350.ms);
  }

  Widget _stat(String icon, String value, String? dim) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 3),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (dim != null)
          Text(
            dim,
            style: GoogleFonts.jetBrainsMono(color: AppColors.textMuted, fontSize: 11),
          ),
      ],
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.accent,
            strokeWidth: 2,
          ),
          const SizedBox(height: 16),
          Text(
            'BHAROSA ranking providers…',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
