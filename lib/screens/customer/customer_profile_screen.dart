import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildStatsRow(),
                  const SizedBox(height: 20),
                  _buildMembershipCard(),
                  const SizedBox(height: 20),
                  _buildSection('ACCOUNT'),
                  _buildTile(Icons.person_outline_rounded, 'Edit Profile',
                      subtitle: 'Ayesha Khan · +92 300 1234567'),
                  _buildTile(Icons.location_on_outlined, 'Saved Addresses',
                      subtitle: 'F-10, Islamabad (Home)  · DHA (Office)',
                      badge: '2'),
                  _buildTile(Icons.credit_card_outlined, 'Payment Methods',
                      subtitle: 'Easypaisa, JazzCash, Cash'),
                  _buildTile(Icons.notifications_outlined, 'Notifications',
                      subtitle: 'Booking updates · Promotions'),
                  _buildTile(Icons.language_rounded, 'Language',
                      subtitle: 'Urdu / Roman Urdu / English'),
                  const SizedBox(height: 20),
                  _buildSection('SUPPORT'),
                  _buildTile(Icons.help_outline_rounded, 'Help & FAQs',
                      onTap: () => context.push('/help')),
                  _buildTile(Icons.history_rounded, 'Agent Activity Logs',
                      onTap: () => context.push('/logs')),
                  _buildTile(Icons.security_rounded, 'Privacy & Security'),
                  _buildTile(Icons.info_outline_rounded, 'About KHIDMAT'),
                  const SizedBox(height: 20),
                  _buildSection('SESSION'),
                  _buildTile(
                    Icons.swap_horiz_rounded,
                    'Switch to Provider Mode',
                    accent: AppColors.gold,
                    onTap: () => context.go('/welcome'),
                  ),
                  _buildTile(
                    Icons.logout_rounded,
                    'Log Out',
                    accent: AppColors.error,
                    onTap: () => context.go('/welcome'),
                  ),
                  const SizedBox(height: 28),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      expandedHeight: 200,
      floating: false,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accent.withValues(alpha: 0.2),
                AppColors.background,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text('A',
                                style: GoogleFonts.inter(
                                    color: const Color(0xFF1A0A05),
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800)),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.background, width: 2),
                              ),
                              child: const Icon(Icons.check_rounded,
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
                            Text('Ayesha Khan',
                                style: GoogleFonts.inter(
                                    color: AppColors.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3)),
                            const SizedBox(height: 3),
                            Text('+92 300 1234567',
                                style: GoogleFonts.inter(
                                    color: AppColors.textMuted, fontSize: 12.5)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: AppColors.gold.withValues(alpha: 0.4)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.workspace_premium_rounded,
                                          color: AppColors.gold, size: 11),
                                      const SizedBox(width: 4),
                                      Text('PREMIUM',
                                          style: GoogleFonts.robotoMono(
                                              color: AppColors.gold,
                                              fontSize: 9,
                                              letterSpacing: 1,
                                              fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.line2),
                          ),
                          child: const Icon(Icons.edit_outlined,
                              color: AppColors.textMuted, size: 17),
                        ),
                      ),
                    ],
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

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _statCard('12', 'Bookings', Icons.receipt_long_rounded, AppColors.accent)),
        const SizedBox(width: 10),
        Expanded(child: _statCard('4.9', 'Avg Rating', Icons.star_rounded, AppColors.gold)),
        const SizedBox(width: 10),
        Expanded(child: _statCard('Rs 8.4k', 'AI Saved', Icons.savings_rounded, AppColors.success)),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0);
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
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
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildMembershipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD4A857), Color(0xFF8A6A30)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded,
              color: Color(0xFF1A1208), size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('KHIDMAT PREMIUM',
                    style: GoogleFonts.robotoMono(
                        color: const Color(0xFF1A1208),
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text('Priority matching · 0% booking fee · Exclusive deals',
                    style: GoogleFonts.inter(
                        color: const Color(0xCC1A1208), fontSize: 11, height: 1.4)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0x331A1208),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('Active',
                style: GoogleFonts.inter(
                    color: const Color(0xFF1A1208),
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
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
    String? badge,
    VoidCallback? onTap,
    Color? accent,
  }) {
    final color = accent ?? AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap ?? () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: accent != null
                    ? accent.withValues(alpha: 0.25)
                    : AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: GoogleFonts.inter(
                            color: accent ?? AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(subtitle,
                            style: GoogleFonts.inter(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                height: 1.4),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                  ],
                ),
              ),
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(badge,
                      style: GoogleFonts.inter(
                          color: AppColors.accent,
                          fontSize: 10,
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
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text('K',
                  style: GoogleFonts.inter(
                      color: const Color(0xFF1A0A05),
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 8),
            Text('KHIDMAT',
                style: GoogleFonts.robotoMono(
                    color: AppColors.textMuted,
                    fontSize: 12,
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
