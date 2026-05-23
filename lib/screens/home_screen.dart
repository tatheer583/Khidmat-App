import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _ctrl = TextEditingController();
  bool _listening = false;
  late final AnimationController _pulseCtrl;
  int _bannerIndex = 0;

  static const _categories = [
    (Icons.ac_unit_rounded, '❄️', 'AC Repair', 'AC theek karwana hai, thanda nahi ho raha', Color(0xFF3B82F6)),
    (Icons.plumbing_rounded, '🔧', 'Plumber', 'Plumber chahiye, nalkay leak ho rahe hain', Color(0xFF06B6D4)),
    (Icons.electrical_services_rounded, '⚡', 'Electrician', 'Electrician chahiye bijli ka masla hai', Color(0xFFF59E0B)),
    (Icons.content_cut_rounded, '✂️', 'Beautician', 'Beautician chahiye ghar par, bridal makeup', Color(0xFFEC4899)),
    (Icons.menu_book_rounded, '📚', 'Tutor', 'Home tutor chahiye bachon ke liye math science', Color(0xFF10B981)),
    (Icons.cleaning_services_rounded, '🧹', 'Cleaner', 'Ghar ki safai karwani hai deep cleaning', Color(0xFF8B5CF6)),
    (Icons.carpenter_rounded, '🪚', 'Carpenter', 'Carpenter chahiye furniture repair ya banana', Color(0xFFD97706)),
    (Icons.format_paint_rounded, '🎨', 'Painter', 'Ghar paint karwana hai interior exterior', Color(0xFF6366F1)),
    (Icons.drive_eta_rounded, '🚗', 'Driver', 'Reliable driver chahiye daily ya monthly', Color(0xFF14B8A6)),
    (Icons.soup_kitchen_rounded, '👨‍🍳', 'Cook', 'Home cook chahiye, khana banana', Color(0xFFEF4444)),
    (Icons.grass_rounded, '🌿', 'Gardener', 'Garden ka kaam, mali chahiye', Color(0xFF22C55E)),
    (Icons.build_rounded, '🔨', 'Handyman', 'General repair aur maintenance ka kaam', Color(0xFF94A3B8)),
  ];

  static const _banners = [
    _BannerData(
      title: 'Book Any Service\nIn Under 2 Minutes',
      subtitle: 'AI-powered matching · Verified providers',
      icon: Icons.bolt_rounded,
      gradient: [Color(0xFFE06A4A), Color(0xFFA04A2E)],
    ),
    _BannerData(
      title: 'All Providers\nVerified & Rated',
      subtitle: 'ID-checked · Background-verified · Insured',
      icon: Icons.verified_user_rounded,
      gradient: [Color(0xFF10B981), Color(0xFF065F46)],
    ),
    _BannerData(
      title: 'AI Negotiates\nBest Price For You',
      subtitle: 'Save up to 30% with our smart bargaining',
      icon: Icons.savings_rounded,
      gradient: [Color(0xFFD4A857), Color(0xFF8A6A30)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
            vsync: this, duration: const Duration(milliseconds: 1600))
        ..repeat();
    _startBannerRotation();
  }

  void _startBannerRotation() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _bannerIndex = (_bannerIndex + 1) % _banners.length);
      _startBannerRotation();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _submit(String text) {
    if (text.trim().isEmpty) return;
    _ctrl.clear();
    FocusScope.of(context).unfocus();
    // Route through service request screen for better UX
    context.push('/request', extra: text.trim());
  }

  void _toggleMic() {
    setState(() => _listening = !_listening);
    if (_listening) {
      _ctrl.text = 'میرا اے سی ٹھنڈا نہیں کر رہا';
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _listening) {
          setState(() => _listening = false);
          context.push('/request', extra: _ctrl.text.trim());
          _ctrl.clear();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildTopBar()),
            SliverToBoxAdapter(child: const SizedBox(height: 16)),
            SliverToBoxAdapter(child: _buildSearchBlock()),
            SliverToBoxAdapter(child: const SizedBox(height: 18)),
            SliverToBoxAdapter(child: _buildPromoBanner()),
            SliverToBoxAdapter(child: _buildSectionHeader('QUICK SERVICES')),
            SliverToBoxAdapter(child: _buildCategoryGrid()),
            SliverToBoxAdapter(child: _buildSectionHeader('ACTIVE & RECENT')),
            SliverToBoxAdapter(child: _buildRecentList()),
            SliverToBoxAdapter(child: _buildSectionHeader('WHY KHIDMAT')),
            SliverToBoxAdapter(child: _buildTrustFeatures()),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Consumer<AppState>(
        builder: (_, state, __) => Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Asalam-o-alaikum,',
                      style: GoogleFonts.inter(
                          color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(height: 1),
                  Text(state.userName,
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3)),
                  Text(state.userCity,
                      style: GoogleFonts.inter(
                          color: AppColors.textMuted, fontSize: 11.5)),
                ],
              ),
            ),
            Row(
              children: [
                if (state.agentLogs.isNotEmpty)
                  _iconBtn(Icons.timeline_rounded, AppColors.accent,
                      () => context.push('/logs')),
                const SizedBox(width: 8),
                _iconBtn(Icons.notifications_outlined, AppColors.textMuted, () {}),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    gradient: AppColors.goldGradient,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(state.userInitial,
                      style: GoogleFonts.inter(
                          color: const Color(0xFF1A1208),
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildSearchBlock() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.line2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 6))
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration.collapsed(
                        hintText: 'Koi bhi service maangein…',
                        hintStyle: GoogleFonts.inter(
                            color: AppColors.textMuted, fontSize: 14),
                      ),
                      onSubmitted: _submit,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _micButton(),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _langChip('اردو'),
                const SizedBox(width: 6),
                _langChip('Roman'),
                const SizedBox(width: 6),
                _langChip('EN'),
                const Spacer(),
                if (_listening)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      children: [
                        Container(width: 6, height: 6,
                            decoration: const BoxDecoration(
                                color: AppColors.error, shape: BoxShape.circle))
                            .animate(onPlay: (c) => c.repeat())
                            .fadeIn(duration: 400.ms)
                            .then()
                            .fadeOut(duration: 400.ms),
                        const SizedBox(width: 5),
                        Text('Listening…',
                            style: GoogleFonts.inter(
                                color: AppColors.error,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () => _submit(_ctrl.text),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.35),
                              blurRadius: 8)
                        ],
                      ),
                      child: Text('Search',
                          style: GoogleFonts.inter(
                              color: const Color(0xFF1A0A05),
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
    );
  }

  Widget _micButton() {
    return GestureDetector(
      onTap: _toggleMic,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_listening)
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                width: 42 + _pulseCtrl.value * 18,
                height: 42 + _pulseCtrl.value * 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.error
                        .withValues(alpha: (1 - _pulseCtrl.value) * 0.5),
                    width: 2,
                  ),
                ),
              ),
            ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: _listening
                  ? const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)])
                  : AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: (_listening ? AppColors.error : AppColors.accent)
                        .withValues(alpha: 0.35),
                    blurRadius: 10)
              ],
            ),
            child: Icon(
              _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
              color: const Color(0xFF1A0A05),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _langChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              color: AppColors.accent,
              fontSize: 10.5,
              fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildPromoBanner() {
    final banner = _banners[_bannerIndex];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: Container(
          key: ValueKey(_bannerIndex),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: banner.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: banner.gradient.first.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6))
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(banner.title,
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1.25)),
                    const SizedBox(height: 6),
                    Text(banner.subtitle,
                        style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11.5,
                            height: 1.4)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Book Now →',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(banner.icon, color: Colors.white, size: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
      child: Text(title,
          style: GoogleFonts.robotoMono(
              color: AppColors.textMuted, fontSize: 11, letterSpacing: 2.5)),
    );
  }

  Widget _buildCategoryGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.82,
        ),
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final (icon, emoji, label, query, color) = _categories[i];
          return GestureDetector(
            onTap: () => context.push('/request', extra: label),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 19)),
                  ),
                  const SizedBox(height: 7),
                  Text(label,
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                      maxLines: 2),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: (i * 50).ms, duration: 300.ms)
                .slideY(begin: 0.08, end: 0),
          );
        },
      ),
    );
  }

  Widget _buildRecentList() {
    return Consumer<AppState>(
      builder: (_, state, __) {
        final booking = state.currentBooking;
        final staticItems = [
          _RecentItem('⚡', 'Imran Hussain', 'Electrician', 'DHA Phase 5 · 14 May', '★ 4.9', false),
          _RecentItem('🔧', 'Bilal Khan', 'Plumber', 'Gulberg · 02 May', '★ 4.7', false),
          _RecentItem('✂️', 'Zara Beauty', 'Beautician', 'F-11 · 28 Apr', '★ 5.0', false),
        ];

        final items = booking != null
            ? [
                _RecentItem(
                  '🔧',
                  booking.provider.name,
                  booking.service,
                  '${booking.location} · Today',
                  '★ 4.9',
                  true,
                ),
                ...staticItems,
              ]
            : staticItems;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: item.isActive ? () => context.push('/tracking') : null,
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: item.isActive
                            ? AppColors.success.withValues(alpha: 0.4)
                            : AppColors.line,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              AppColors.gold.withValues(alpha: 0.2),
                              AppColors.gold.withValues(alpha: 0.08),
                            ]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(item.emoji,
                              style: const TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name,
                                  style: GoogleFonts.inter(
                                      color: AppColors.textPrimary,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text('${item.service} · ${item.date}',
                                  style: GoogleFonts.inter(
                                      color: AppColors.textMuted,
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(item.badge,
                                style: GoogleFonts.inter(
                                    color: AppColors.gold,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            if (item.isActive)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('ACTIVE',
                                    style: GoogleFonts.robotoMono(
                                        color: AppColors.success,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: (i * 80).ms, duration: 300.ms),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildTrustFeatures() {
    final features = [
      (Icons.verified_user_rounded, 'Verified Providers', 'ID & background checked', AppColors.info),
      (Icons.psychology_rounded, 'AI Matching', 'Best fit for your need', AppColors.accent),
      (Icons.price_check_rounded, 'Best Price', 'AI negotiates for you', AppColors.success),
      (Icons.timer_rounded, 'Fast Booking', 'Confirmed in under 2 min', AppColors.warning),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: features.asMap().entries.map((e) {
              final i = e.key;
              final (icon, title, subtitle, color) = e.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 17),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(title,
                              style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700)),
                          Text(subtitle,
                              style: GoogleFonts.inter(
                                  color: AppColors.textMuted,
                                  fontSize: 9.5),
                              maxLines: 1),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (i * 80).ms, duration: 300.ms);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RecentItem {
  final String emoji;
  final String name;
  final String service;
  final String date;
  final String badge;
  final bool isActive;
  _RecentItem(this.emoji, this.name, this.service, this.date, this.badge, this.isActive);
}

class _BannerData {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  const _BannerData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });
}
