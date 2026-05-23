import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';

enum _Phase { animating, form }

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  _Phase _phase = _Phase.animating;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String? _nameError;
  String? _emailError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final onboarded = prefs.getBool('onboarded') ?? false;
    if (onboarded) {
      final name = prefs.getString('user_name') ?? '';
      final email = prefs.getString('user_email') ?? '';
      final phone = prefs.getString('user_phone') ?? '';
      if (name.isNotEmpty && mounted) {
        context.read<AppState>().setUserProfile(name: name, email: email, phone: phone);
      }
      if (mounted) context.go('/welcome');
    } else {
      if (mounted) setState(() => _phase = _Phase.form);
    }
  }

  Future<void> _save() async {
    setState(() {
      _nameError = _nameCtrl.text.trim().isEmpty ? 'Please enter your name' : null;
      _emailError = !_emailCtrl.text.trim().contains('@') ? 'Please enter a valid email' : null;
    });
    if (_nameError != null || _emailError != null) return;

    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameCtrl.text.trim());
    await prefs.setString('user_email', _emailCtrl.text.trim());
    await prefs.setBool('onboarded', true);

    if (!mounted) return;
    context.read<AppState>().setUserProfile(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
        );
    context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF14100E), Color(0xFF0D0F12)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.22),
                  radius: 0.7,
                  colors: [Color(0x33E06A4A), Colors.transparent],
                ),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
            child: _phase == _Phase.animating ? _buildLogoView() : _buildFormView(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoView() {
    return Center(
      key: const ValueKey('logo'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 124,
            height: 124,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(32),
              boxShadow: const [
                BoxShadow(color: Color(0x66E06A4A), blurRadius: 60),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              'K',
              style: GoogleFonts.inter(
                color: const Color(0xFF1A0A05),
                fontSize: 76,
                fontWeight: FontWeight.w800,
                letterSpacing: -3,
                height: 1,
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 0.97, end: 1.0, duration: 2000.ms, curve: Curves.easeInOut),
          const SizedBox(height: 36),
          Text(
            'Khidmat',
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 44,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.88,
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
          const SizedBox(height: 14),
          Text(
            'خدمت',
            style: GoogleFonts.notoNaskhArabic(
              color: AppColors.accent,
              fontSize: 38,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
          const SizedBox(height: 30),
          Text(
            'Aap ki khidmat mein',
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 16,
              letterSpacing: 0.6,
            ),
          ).animate().fadeIn(delay: 600.ms, duration: 500.ms),
          const SizedBox(height: 70),
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accent,
              backgroundColor: AppColors.accent.withValues(alpha: 0.18),
            ),
          ).animate().fadeIn(delay: 900.ms, duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildFormView() {
    return SafeArea(
      key: const ValueKey('form'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mini logo header
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 12),
                    ],
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
                        style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ],
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 44),

            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              alignment: Alignment.center,
              child: const Text('👋', style: TextStyle(fontSize: 30)),
            ).animate().scaleXY(begin: 0.8, end: 1, duration: 400.ms, curve: Curves.easeOutBack),

            const SizedBox(height: 20),

            Text('Welcome!\nTell us your name',
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    letterSpacing: -0.5))
                .animate()
                .fadeIn(delay: 100.ms, duration: 400.ms),

            const SizedBox(height: 8),

            Text(
              'Your info personalises your experience and helps providers contact you.',
              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13, height: 1.5),
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

            const SizedBox(height: 32),

            _fieldLabel('Full Name *'),
            _inputField(
              controller: _nameCtrl,
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

            const SizedBox(height: 36),

            _saving
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
                : GestureDetector(
                    onTap: _save,
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
                              offset: const Offset(0, 6)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text('Get Started →',
                          style: GoogleFonts.inter(
                              color: const Color(0xFF1A0A05),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2)),
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(label,
            style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2)),
      );

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
              color: error != null ? AppColors.error : AppColors.line2,
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
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14.5),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13.5),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
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
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 13),
                const SizedBox(width: 4),
                Text(error, style: GoogleFonts.inter(color: AppColors.error, fontSize: 11)),
              ],
            ),
          ),
      ],
    );
  }
}
