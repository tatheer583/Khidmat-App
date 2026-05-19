import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../models/agent_log.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Help & Support', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAgentGuide(),
          const SizedBox(height: 16),
          _buildSampleQueries(),
          const SizedBox(height: 16),
          _buildFaq(),
          const SizedBox(height: 16),
          _buildTechStack(),
        ],
      ),
    );
  }

  Widget _buildAgentGuide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Agent Pipeline', Icons.account_tree_outlined, AppColors.primary),
        const SizedBox(height: 12),
        ...agentRegistry.entries.toList().asMap().entries.map((e) {
          final i = e.key;
          final entry = e.value;
          final info = entry.value;
          final color = Color(info.colorValue);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(info.bgColorValue),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: GoogleFonts.inter(color: color, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(info.name, style: GoogleFonts.inter(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 6),
                          Text(info.urduName, style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 12)),
                        ],
                      ),
                      Text(info.description, style: GoogleFonts.inter(color: color.withValues(alpha: 0.7), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: (i * 80).ms, duration: 300.ms)
              .slideX(begin: 0.05, end: 0, delay: (i * 80).ms, duration: 300.ms);
        }),
      ],
    );
  }

  Widget _buildSampleQueries() {
    final queries = [
      ('Roman Urdu', 'Mujhe G-13 mein AC technician chahiye kal subah', AppColors.agentFaham),
      ('Urdu', 'آج شام کو پلمبر چاہیے، نلکے لیک ہو رہے ہیں', AppColors.agentBharosa),
      ('English', 'I need an electrician urgently in F-10', AppColors.agentDhoond),
      ('Code-Switched', 'Urgent! Bijli ki wiring fix karni hai aaj', AppColors.agentMolBhaav),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Sample Queries', Icons.chat_bubble_outline, AppColors.agentFaham),
        const SizedBox(height: 12),
        ...queries.map((q) {
          final (lang, text, color) = q;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(lang, style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 6),
                Text(text, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontStyle: FontStyle.italic)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFaq() {
    final faqs = [
      ('How does KHIDMAT find providers?', 'DHOOND Agent scans our database by service category and location, then BHAROSA ranks them by trust score — not just star ratings.'),
      ('What is the BHAROSA trust score?', 'BHAROSA uses: Completion Rate (40%) + Response Speed (30%) + Community Vouches (20%) + Star Rating (10%) to compute a 0–100 trust score.'),
      ('How does price negotiation work?', 'MOL-BHAAV Agent checks market rates and negotiates with providers in up to 2 rounds to get you the fairest price.'),
      ('Is my data safe?', 'KHIDMAT uses simulated/mock data for the demo. No real personal data is collected or stored.'),
      ('Which languages are supported?', 'Urdu, Roman Urdu, English, and code-switched (mix of all three) are all supported by FAHAM Agent.'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('FAQ', Icons.quiz_outlined, AppColors.agentMolBhaav),
        const SizedBox(height: 12),
        ...faqs.map((faq) {
          final (q, a) = faq;
          return Theme(
            data: ThemeData(dividerColor: Colors.transparent),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: ExpansionTile(
                title: Text(q, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                collapsedIconColor: AppColors.textMuted,
                iconColor: AppColors.primary,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Text(a, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, height: 1.5)),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTechStack() {
    final stack = [
      ('Flutter', 'UI Framework', Icons.phone_android, AppColors.agentFaham),
      ('Dart', 'Programming Language', Icons.code, AppColors.agentBharosa),
      ('Google Gemini', 'LLM / NLP Engine', Icons.auto_awesome, AppColors.agentMolBhaav),
      ('FAHAM Agent', 'Intent Extraction', Icons.psychology, AppColors.agentFaham),
      ('BHAROSA Agent', 'Trust Intelligence', Icons.verified_user, AppColors.agentBharosa),
      ('MOL-BHAAV Agent', 'Price Negotiation', Icons.handshake, AppColors.agentMolBhaav),
      ('DHOOND Agent', 'Provider Discovery', Icons.radar, AppColors.agentDhoond),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Tech Stack', Icons.layers_outlined, AppColors.agentBook),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: stack.map((item) {
            final (name, desc, icon, color) = item;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 14),
                  const SizedBox(width: 6),
                  Text(name, style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
