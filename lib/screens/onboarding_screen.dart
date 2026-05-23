import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  final _namCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  int _page = 0;
  bool _saving = false;
  String? _nameError;
  String? _emailError;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _namCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    setState(() {
      _nameError = _namCtrl.text.trim().isEmpty ? 'Please enter your name' : null;
      _emailError = !_emailCtrl.text.trim().contains('@')
          ? 'Please enter a valid email'
          : null;
    });
    if (_nameError != null || _emailError != null) return;

    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _namCtrl.text.trim());
    await prefs.setString('user_email', _emailCtrl.text.trim());
    await prefs.setString('user_phone', _phoneCtrl.text.trim());
    await prefs.setBool('onboarded', true);

    if (!mounted) return;
    context.read<AppState>().setUserProfile(
          name: _namCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
        );
    setState(() => _saving = false);
    context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ambient glow
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.accent.withValues(alpha: 0.18),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.gold.withValues(alpha: 0.12),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildHeader(),
                const SizedBox(height: 32),
                Expanded(
                  child: PageView(
                    controller: _pageCtrl,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _page = i),
                    children: [
                      _buildWelcomePage(),
                      _buildProfilePage(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 12)],
            ),
            alignment: Alignment.center,
            child: Text('K',
                style: GoogleFonts.inter(
                    color: const Color(0xFF1A0A05),
                    fontSize: 24,
                    fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('KHIDMAT',
                  style: GoogleFonts.robotoMono(
                      color: AppColors.accent,
                      fontSize: 13,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w700)),
              Text('Aap ki khidmat mein',
                  style: GoogleFonts.inter(
                      color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
          const Spacer(),
          // Step indicators
          Row(
            children: List.generate(2, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: i == _page ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: i == _page ? AppColors.accent : AppColors.surfaceHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            alignment: Alignment.center,
            child: const Text('👋', style: TextStyle(fontSize: 36)),
          ).animate().scaleXY(begin: 0.8, end: 1, duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          Text('Welcome to\nKHIDMAT!',
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                  letterSpacing: -0.6))
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms)
              .slideY(begin: 0.1, end: 0),
          const SizedBox(height: 14),
          Text('Pakistan ki best home services — verified, affordable, and at your doorstep.',
              style: GoogleFonts.inter(
                  color: AppColors.textMuted, fontSize: 15, height: 1.55))
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 32),
          ..._features.asMap().entries.map((e) {
            final i = e.key;
            final (icon, title, sub, color) = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                        Text(sub,
                            style: GoogleFonts.inter(
                                color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: (300 + i * 80).ms, duration: 350.ms),
            );
          }),
          const Spacer(),
          _primaryBtn('Get Started →', () {
            _pageCtrl.animateToPage(1,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut);
          }).animate().fadeIn(delay: 600.ms, duration: 400.ms),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  static const _features = [
    (Icons.verified_user_rounded, 'Verified Providers', 'ID-checked & background-verified workers', AppColors.success),
    (Icons.psychology_rounded, 'AI-Powered Matching', 'Gemini AI finds the best match for you', AppColors.accent),
    (Icons.price_check_rounded, 'Smart Negotiation', 'AI negotiates best price on your behalf', AppColors.gold),
  ];

  Widget _buildProfilePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            ),
            alignment: Alignment.center,
            child: const Text('✍️', style: TextStyle(fontSize: 36)),
          ).animate().scaleXY(begin: 0.8, end: 1, duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          Text('Tell us about\nyourself',
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                  letterSpacing: -0.5))
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms),
          const SizedBox(height: 8),
          Text('Your info is only used to personalise your experience and contact you about bookings.',
              style: GoogleFonts.inter(
                  color: AppColors.textMuted, fontSize: 13, height: 1.5))
              .animate()
              .fadeIn(delay: 150.ms, duration: 400.ms),
          const SizedBox(height: 28),
          _fieldLabel('Full Name *'),
          _inputField(
            controller: _namCtrl,
            hint: 'e.g. Ayesha Khan',
            icon: Icons.person_outline_rounded,
            error: _nameError,
            type: TextInputType.name,
          ),
          const SizedBox(height: 16),
          _fieldLabel('Email Address *'),
          _inputField(
            controller: _emailCtrl,
            hint: 'e.g. ayesha@email.com',
            icon: Icons.email_outlined,
            error: _emailError,
            type: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _fieldLabel('Phone Number (optional)'),
          _inputField(
            controller: _phoneCtrl,
            hint: 'e.g. +92 300 1234567',
            icon: Icons.phone_outlined,
            type: TextInputType.phone,
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              GestureDetector(
                onTap: () => _pageCtrl.animateToPage(0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut),
                child: Container(
                  width: 48,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line2),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.textSecondary, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _saving
                    ? Container(
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Color(0xFF1A0A05), strokeWidth: 2.5),
                        ),
                      )
                    : _primaryBtn('Continue →', _saveAndContinue),
              ),
            ],
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(label,
          style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2)),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? error,
    TextInputType type = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: error != null
                  ? AppColors.error
                  : AppColors.line2,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Icon(icon, color: AppColors.textMuted, size: 20),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: type,
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary, fontSize: 14.5),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.inter(
                        color: AppColors.textMuted, fontSize: 13.5),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 15),
                  ),
                  onChanged: (_) {
                    if (error != null) setState(() {});
                  },
                ),
              ),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 4),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 13),
                const SizedBox(width: 4),
                Text(error,
                    style: GoogleFonts.inter(
                        color: AppColors.error, fontSize: 11)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _primaryBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6))
          ],
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: GoogleFonts.inter(
                color: const Color(0xFF1A0A05),
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2)),
      ),
    );
  }
}
