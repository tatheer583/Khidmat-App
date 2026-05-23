import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../theme/app_colors.dart';
import 'provider_reviews_screen.dart';

class ProviderProfileScreen extends StatelessWidget {
  const ProviderProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AppState>(
        builder: (_, state, __) {
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, state),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    children: [
                      _buildBadgeRow(),
                      const SizedBox(height: 16),
                      _buildStatsRow(state),
                      const SizedBox(height: 20),
                      _buildAvailabilityCard(),
                      const SizedBox(height: 20),
                      _buildSection('BUSINESS'),
                      _buildTile(Icons.handyman_rounded, 'Services & Pricing',
                          subtitle: 'AC Repair · Service · Installation', color: AppColors.accent),
                      _buildTile(Icons.location_on_outlined, 'Service Area & Radius',
                          subtitle: 'G-13, G-11, G-9 · 5 km radius', color: AppColors.info),
                      _buildTile(Icons.schedule_outlined, 'Working Hours',
                          subtitle: '08:00 AM – 07:00 PM · Mon–Sat', color: AppColors.success),
                      _buildTile(Icons.verified_user_outlined, 'Verification & ID',
                          subtitle: 'CNIC verified · Background checked', color: AppColors.gold,
                          trailingBadge: '✓ VERIFIED'),
                      const SizedBox(height: 16),
                      _buildSection('FEEDBACK'),
                      _buildTile(Icons.star_rounded, 'My Reviews (${state.reviews.length})',
                          subtitle: '${state.providerAvgRating.toStringAsFixed(1)} avg · ${state.reviews.length} reviews',
                          color: AppColors.gold,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ProviderReviewsScreen()))),
                      _buildTile(Icons.bar_chart_rounded, 'Performance Insights',
                          subtitle: '92% acceptance · 97% completion rate', color: AppColors.success),
                      _buildTile(Icons.workspace_premium_rounded, 'KHIDMAT Pro Badge',
                          subtitle: 'Top 5% provider in your area', color: AppColors.accent,
                          trailingBadge: 'TOP 5%'),
                      const SizedBox(height: 16),
                      _buildSection('ACCOUNT'),
                      _buildTile(Icons.person_outline_rounded, 'Edit Profile',
                          subtitle: 'Ali Hassan · +92 321 5678901'),
                      _buildTile(Icons.credit_card_outlined, 'Payment & Bank Details',
                          subtitle: 'Easypaisa, JazzCash'),
                      _buildTile(Icons.notifications_outlined, 'Notifications',
                          subtitle: 'New jobs · Payments · Updates'),
                      const SizedBox(height: 16),
                      _buildSection('SESSION'),
                      _buildTile(Icons.swap_horiz_rounded, 'Switch to Customer Mode',
                          color: AppColors.accent,
                          onTap: () => context.go('/welcome')),
                      _buildTile(Icons.logout_rounded, 'Log Out',
                          color: AppColors.error,
                          onTap: () => context.go('/welcome')),
                      const SizedBox(height: 24),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, AppState state) {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      expandedHeight: 210,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.gold.withValues(alpha: 0.25),
                AppColors.background,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: const BoxDecoration(
                          gradient: AppColors.goldGradient,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text('A',
                            style: GoogleFonts.inter(
                                color: const Color(0xFF1A1208),
                                fontSize: 32,
                                fontWeight: FontWeight.w900)),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.info,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.background, width: 2),
                          ),
                          child: const Icon(Icons.verified_rounded,
                              color: Colors.white, size: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Ali Hassan',
                                style: GoogleFonts.inter(
                                    color: AppColors.textPrimary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4)),
                            const SizedBox(width: 6),
                            const Icon(Icons.verified_rounded,
                                color: AppColors.info, size: 18),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('AC Technician · G-13, Islamabad',
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary, fontSize: 12.5)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: AppColors.gold, size: 15),
                                const SizedBox(width: 3),
                                Text(
                                    state.providerAvgRating > 0
                                        ? state.providerAvgRating.toStringAsFixed(1)
                                        : '4.9',
                                    style: GoogleFonts.inter(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Text('${state.completedJobs.length + 47} jobs done',
                                style: GoogleFonts.inter(
                                    color: AppColors.textMuted, fontSize: 11.5)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _editBtn('Edit Profile', Icons.edit_outlined),
                            const SizedBox(width: 8),
                            _editBtn('Share', Icons.share_rounded),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      title: Text('Profile',
          style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700)),
    );
  }

  Widget _editBtn(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.line2),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBadgeRow() {
    final badges = [
      ('Verified', Icons.verified_user_rounded, AppColors.info),
      ('Top-rated', Icons.workspace_premium_rounded, AppColors.gold),
      ('5+ years', Icons.history_rounded, AppColors.success),
      ('Fast reply', Icons.bolt_rounded, AppColors.warning),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: badges.asMap().entries.map((e) {
          final i = e.key;
          final (label, icon, color) = e.value;
          return Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(label,
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ],
          ).animate().fadeIn(delay: (i * 80).ms, duration: 300.ms);
        }).toList(),
      ),
    );
  }

  Widget _buildStatsRow(AppState state) {
    return Row(
      children: [
        Expanded(
            child: _statCard('${state.completedJobs.length + 47}', 'Jobs Done',
                Icons.check_circle_rounded, AppColors.success)),
        const SizedBox(width: 10),
        Expanded(
            child: _statCard(
                'Rs ${((state.totalEarnings + 85000) / 1000).toStringAsFixed(0)}k',
                'Earned',
                Icons.account_balance_wallet_rounded,
                AppColors.gold)),
        const SizedBox(width: 10),
        Expanded(
            child: _statCard(
                state.providerAvgRating > 0
                    ? state.providerAvgRating.toStringAsFixed(1)
                    : '4.9',
                'Avg Rating',
                Icons.star_rounded,
                AppColors.accent)),
      ],
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 9.5)),
        ],
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.success.withValues(alpha: 0.15),
          AppColors.surfaceCard,
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                  color: AppColors.success, shape: BoxShape.circle),
            )
                .animate(onPlay: (c) => c.repeat())
                .scaleXY(begin: 0.7, end: 1.2, duration: 800.ms)
                .then()
                .scaleXY(begin: 1.2, end: 0.7, duration: 800.ms),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Available for Jobs',
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                Text('Accepting requests · 5 km radius',
                    style: GoogleFonts.inter(
                        color: AppColors.textMuted, fontSize: 11.5)),
              ],
            ),
          ),
          Switch(
            value: true,
            activeColor: AppColors.success,
            onChanged: (_) {},
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Text(label,
          style: GoogleFonts.robotoMono(
              color: AppColors.textMuted, fontSize: 10.5, letterSpacing: 2)),
    );
  }

  Widget _buildTile(
    IconData icon,
    String label, {
    String? subtitle,
    Color? color,
    VoidCallback? onTap,
    String? trailingBadge,
  }) {
    final c = color ?? AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap ?? () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: c, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: GoogleFonts.inter(
                            color: color != null && color == AppColors.error
                                ? AppColors.error
                                : AppColors.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600)),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(subtitle,
                            style: GoogleFonts.inter(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                height: 1.3),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                  ],
                ),
              ),
              if (trailingBadge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: c.withValues(alpha: 0.3)),
                  ),
                  child: Text(trailingBadge,
                      style: GoogleFonts.robotoMono(
                          color: c,
                          fontSize: 8.5,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 6),
              ],
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text('K',
                  style: GoogleFonts.inter(
                      color: const Color(0xFF1A1208),
                      fontSize: 12,
                      fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 8),
            Text('KHIDMAT PROVIDER',
                style: GoogleFonts.robotoMono(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        Text('v1.0.0 · Powered by Gemini AI',
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10.5)),
      ],
    );
  }
}
