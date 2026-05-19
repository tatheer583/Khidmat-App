import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';

class NegotiationScreen extends StatefulWidget {
  const NegotiationScreen({super.key});

  @override
  State<NegotiationScreen> createState() => _NegotiationScreenState();
}

class _NegotiationScreenState extends State<NegotiationScreen> {
  String? _selectedSlot;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.agentMolBhaav.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.agentMolBhaav.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.handshake, color: AppColors.agentMolBhaav, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MOL-BHAAV', style: GoogleFonts.inter(color: AppColors.agentMolBhaav, fontSize: 14, fontWeight: FontWeight.w700)),
                Text('Price Negotiation', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: Consumer<AppState>(
        builder: (ctx, state, _) {
          if (state.stage == PipelineStage.negotiating) {
            return _buildNegotiating();
          }
          if (state.negotiationResult == null) {
            return const Center(child: CircularProgressIndicator(color: AppColors.agentMolBhaav));
          }
          return _buildResult(context, state);
        },
      ),
    );
  }

  Widget _buildNegotiating() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.agentMolBhaav.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.agentMolBhaav.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.handshake, color: AppColors.agentMolBhaav, size: 40),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 0.9, end: 1.05, duration: 1200.ms),
          const SizedBox(height: 24),
          Text(
            'MOL-BHAAV negotiating...',
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Getting you the best price',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _negotiationStep('Market Analysis', true),
              const SizedBox(width: 8),
              _negotiationStep('Counter Offer', true),
              const SizedBox(width: 8),
              _negotiationStep('Final Deal', false),
            ],
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 2000.ms, color: AppColors.agentMolBhaav.withValues(alpha: 0.3)),
        ],
      ),
    );
  }

  Widget _negotiationStep(String label, bool done) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: done ? AppColors.agentMolBhaav.withValues(alpha: 0.15) : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: done ? AppColors.agentMolBhaav.withValues(alpha: 0.4) : AppColors.divider),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: done ? AppColors.agentMolBhaav : AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildResult(BuildContext context, AppState state) {
    final result = state.negotiationResult!;
    final provider = state.selectedProvider!.provider;
    final slots = provider.availableSlots;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Outcome banner
          _buildOutcomeBanner(result.outcome, result.savings),

          const SizedBox(height: 16),

          // Market rate vs deal
          _buildPriceComparison(result),

          const SizedBox(height: 16),

          // Negotiation timeline
          _buildNegotiationTimeline(result),

          const SizedBox(height: 16),

          // Explanation
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.agentMolBhaav.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.agentMolBhaav.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.agentMolBhaav, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result.explanation,
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Slot selection
          if (slots.isNotEmpty) ...[
            Text('Available Slots', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: slots.map((slot) => GestureDetector(
                onTap: () => setState(() => _selectedSlot = slot),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedSlot == slot ? AppColors.primary : AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedSlot == slot ? AppColors.primary : AppColors.divider,
                    ),
                    boxShadow: _selectedSlot == slot
                        ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 8)]
                        : null,
                  ),
                  child: Text(
                    slot,
                    style: GoogleFonts.inter(
                      color: _selectedSlot == slot ? AppColors.onPrimary : AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),
          ],

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedSlot == null
                  ? null
                  : () async {
                      await state.confirmBooking(_selectedSlot!);
                      if (context.mounted) context.go('/booking');
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: AppColors.surfaceHighest,
              ),
              child: Text(
                _selectedSlot == null ? 'Select a Time Slot' : 'Confirm Booking · Rs. ${_fmt(result.finalPrice > 0 ? result.finalPrice : provider.priceMax)}',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),

          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => context.pop(),
              child: Text('Back to Providers', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutcomeBanner(String outcome, int savings) {
    final color = outcome == 'REJECTED' ? AppColors.error : AppColors.primary;
    final icon = outcome == 'REJECTED' ? Icons.cancel_outlined : Icons.check_circle_outline;
    final label = outcome == 'REJECTED'
        ? 'No deal — try another provider'
        : outcome == 'ACCEPTED'
            ? 'Provider price accepted!'
            : 'Deal negotiated! Rs. ${_fmt(savings)} saved 🎉';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: GoogleFonts.inter(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: -0.1, end: 0, duration: 500.ms);
  }

  Widget _buildPriceComparison(result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: const Border.fromBorderSide(BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Price Analysis', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _priceRow('Market Rate Range', 'Rs. ${_fmt(result.marketMin)} – ${_fmt(result.marketMax)}', AppColors.agentDhoond),
          const SizedBox(height: 8),
          _priceRow('Provider Quote', 'Rs. ${_fmt(result.providerQuote)}', AppColors.warning),
          if (result.finalPrice > 0) ...[
            const SizedBox(height: 8),
            _priceRow('Final Deal', 'Rs. ${_fmt(result.finalPrice)}', AppColors.primary),
            if (result.savings > 0) ...[
              const SizedBox(height: 8),
              _priceRow('You Saved', 'Rs. ${_fmt(result.savings)} (${result.savingsPercent}%)', AppColors.trustHigh),
            ],
          ],
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
        Text(value, style: GoogleFonts.inter(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildNegotiationTimeline(result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Negotiation Log', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...result.rounds.asMap().entries.map((e) {
          final i = e.key;
          final round = e.value;
          final isProvider = round.actor == 'provider';
          final color = isProvider ? AppColors.agentDhoond : AppColors.agentMolBhaav;
          final actionColor = round.action == 'accepted' ? AppColors.primary
              : round.action == 'rejected' ? AppColors.error
              : color;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline dot
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: color.withValues(alpha: 0.4)),
                      ),
                      child: Center(
                        child: Icon(
                          isProvider ? Icons.person : Icons.smart_toy,
                          color: color,
                          size: 14,
                        ),
                      ),
                    ),
                    if (i < result.rounds.length - 1)
                      Container(width: 1, height: 24, color: AppColors.divider),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isProvider ? 'Provider' : 'KHIDMAT AI',
                              style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: actionColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                round.action.toUpperCase(),
                                style: GoogleFonts.inter(color: actionColor, fontSize: 9, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Rs. ${_fmt(round.amount)}',
                              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        if (round.note != null) ...[
                          const SizedBox(height: 4),
                          Text(round.note!, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: (i * 150).ms, duration: 300.ms)
              .slideX(begin: -0.05, end: 0, delay: (i * 150).ms, duration: 300.ms);
        }),
      ],
    );
  }

  String _fmt(int n) =>
      n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}
