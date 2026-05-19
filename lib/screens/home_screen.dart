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

  static const _categories = [
    ('❄', 'AC Repair', 'AC repair chahiye, thanda nahi ho raha'),
    ('🔧', 'Plumber', 'Plumber chahiye, nalkay leak ho rahe hain'),
    ('⚡', 'Electrician', 'Electrician chahiye'),
    ('✂', 'Beautician', 'Beautician chahiye ghar par'),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
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
    context.read<AppState>().startPipeline(text.trim());
    context.push('/processing');
  }

  void _toggleMic() {
    setState(() => _listening = !_listening);
    if (_listening) {
      _ctrl.text = 'میرا اے سی ٹھنڈا نہیں کر رہا';
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _listening) {
          setState(() => _listening = false);
          _submit(_ctrl.text);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F12),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topBar(),
              const SizedBox(height: 16),
              _searchBlock(),
              _sectionHeader('Quick services'),
              _categoryGrid(),
              _sectionHeader('Recent'),
              _recentList(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Asalam-o-alaikum,',
                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 15),
              ),
              Text(
                'Ayesha',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Consumer<AppState>(
            builder: (_, state, __) => Row(
              children: [
                if (state.agentLogs.isNotEmpty)
                  GestureDetector(
                    onTap: () => context.push('/logs'),
                    child: Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.timeline, color: AppColors.accent, size: 16),
                    ),
                  ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    gradient: AppColors.goldGradient,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'A',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF1A1208),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBlock() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            // Input row
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration.collapsed(
                        hintText: 'Koi bhi service maangein...',
                        hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
                      ),
                      onSubmitted: _submit,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _micButton(),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Lang chips row
            Row(
              children: [
                _langChip('اردو', active: true),
                const SizedBox(width: 6),
                _langChip('Roman', active: true),
                const SizedBox(width: 6),
                _langChip('EN', active: false),
                const Spacer(),
                if (_listening)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat())
                            .fadeIn(duration: 400.ms)
                            .then()
                            .fadeOut(duration: 400.ms),
                        const SizedBox(width: 5),
                        Text(
                          'Listening',
                          style: GoogleFonts.inter(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04, end: 0);
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
                width: 44 + _pulseCtrl.value * 22,
                height: 44 + _pulseCtrl.value * 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: (1 - _pulseCtrl.value) * 0.4),
                    width: 2,
                  ),
                ),
              ),
            ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _listening ? AppColors.accent : AppColors.accent,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 12)],
            ),
            child: Icon(
              _listening ? Icons.mic : Icons.mic_none_rounded,
              color: const Color(0xFF1A0A05),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _langChip(String label, {required bool active}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? AppColors.accent.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: active ? AppColors.accent.withValues(alpha: 0.5) : AppColors.line2,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: active ? AppColors.accent : AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.robotoMono(
          color: AppColors.textMuted,
          fontSize: 11,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _categoryGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.88,
        children: _categories.asMap().entries.map((e) {
          final i = e.key;
          final (emoji, label, query) = e.value;
          return GestureDetector(
            onTap: () => _submit(query),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: (i * 80).ms, duration: 300.ms)
                .slideY(begin: 0.1, end: 0),
          );
        }).toList(),
      ),
    );
  }

  Widget _recentList() {
    return Consumer<AppState>(
      builder: (_, state, __) {
        final booking = state.currentBooking;
        final staticItems = [
          ('⚡', 'Imran — Electrician', 'DHA Phase 5 · Tue, 14 May', '★ 4.9'),
          ('🔧', 'Bilal — Plumber', 'Gulberg · 02 May', '★ 4.7'),
        ];

        final items = booking != null
            ? [
                (
                  '🔧',
                  '${booking.provider.name} — ${booking.service}',
                  '${booking.location} · Today',
                  '★ 4.9',
                ),
                ...staticItems,
              ]
            : staticItems;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final (icon, title, subtitle, badge) = e.value;
              final isActive = booking != null && i == 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: isActive ? () => context.push('/tracking') : null,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isActive ? AppColors.accent.withValues(alpha: 0.3) : AppColors.line,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(icon, style: const TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          badge,
                          style: GoogleFonts.inter(
                            color: AppColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: (i * 100).ms, duration: 300.ms),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
