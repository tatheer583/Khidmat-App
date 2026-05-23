import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/app_state.dart';
import '../../models/provider_job.dart';
import '../../theme/app_colors.dart';
import 'provider_reviews_screen.dart';

class ProviderEarningsScreen extends StatelessWidget {
  const ProviderEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Earnings',
            style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        centerTitle: false,
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.reviews_outlined, color: AppColors.gold, size: 18),
              ),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ProviderReviewsScreen())),
            ),
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (_, state, __) {
          final totalEarnings = state.totalEarnings + 85000;
          final weekEarnings = state.weekEarnings + 12500;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _buildMainCard(totalEarnings, weekEarnings, state),
              const SizedBox(height: 14),
              _buildBreakdownRow(weekEarnings, state),
              const SizedBox(height: 14),
              _buildWeekChart(state),
              const SizedBox(height: 20),
              _buildSection('RECENT TRANSACTIONS'),
              if (state.earnings.isEmpty)
                _buildEmptyTx()
              else
                ...state.earnings.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _TxCard(entry: e.value, index: e.key),
                    )),
              // Static historical entries
              ..._staticTx.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _TxCard(
                      name: e.value.$1,
                      service: e.value.$2,
                      amount: e.value.$3,
                      date: e.value.$4,
                      id: e.value.$5,
                      index: e.key + state.earnings.length,
                    ),
                  )),
              const SizedBox(height: 10),
              _buildSection('PAYOUT STATUS'),
              _buildPayoutCard(),
            ],
          );
        },
      ),
    );
  }

  static final _staticTx = [
    ('Ahmed Raza', 'AC Repair', 2800, DateTime(2024, 5, 14), 'KH-4891'),
    ('Sadia Malik', 'AC Service', 1500, DateTime(2024, 5, 12), 'KH-4870'),
    ('Tariq Brothers', 'AC Installation', 4500, DateTime(2024, 5, 10), 'KH-4856'),
    ('Hamid Shah', 'AC Repair', 3200, DateTime(2024, 5, 8), 'KH-4843'),
  ];

  Widget _buildMainCard(int total, int week, AppState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD4A857), Color(0xFF8A6A30)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL EARNINGS',
                        style: GoogleFonts.robotoMono(
                            color: const Color(0xBB1A1208),
                            fontSize: 10,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Rs ${NumberFormat('#,###').format(total)}',
                        style: GoogleFonts.inter(
                            color: const Color(0xFF1A1208),
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x331A1208),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.trending_up_rounded,
                    color: Color(0xFF1A1208), size: 28),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0x331A1208)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _miniStat('This Week',
                      'Rs ${NumberFormat('#,###').format(week)}')),
              Container(
                  width: 1, height: 28, color: const Color(0x331A1208)),
              Expanded(
                  child: _miniStat(
                      'Jobs Done', '${state.completedJobs.length + 47}')),
              Container(
                  width: 1, height: 28, color: const Color(0x331A1208)),
              Expanded(
                  child: _miniStat(
                      'Avg / Job',
                      'Rs ${NumberFormat('#,###').format(total ~/ (state.completedJobs.length + 47))}')),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _miniStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.inter(
                color: const Color(0xFF1A1208),
                fontSize: 13,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.inter(
                color: const Color(0xBB1A1208), fontSize: 10)),
      ],
    );
  }

  Widget _buildBreakdownRow(int week, AppState state) {
    return Row(
      children: [
        Expanded(child: _breakdownCard('Today', 'Rs 2,800', AppColors.success, Icons.today_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _breakdownCard('Pending', 'Rs 1,500', AppColors.warning, Icons.hourglass_bottom_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _breakdownCard('Withdrawn', 'Rs ${NumberFormat('#,###').format(week - 4300)}', AppColors.accent, Icons.arrow_upward_rounded)),
      ],
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
  }

  Widget _breakdownCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildWeekChart(AppState state) {
    final now = DateTime.now();
    final byDay = List<int>.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      final base = [1800, 2400, 0, 3200, 1500, 2800, 4500];
      final fromState = state.earnings
          .where((e) =>
              e.date.year == d.year && e.date.month == d.month && e.date.day == d.day)
          .fold(0, (a, e) => a + e.amount);
      return fromState > 0 ? fromState : base[i];
    });
    final maxVal = byDay.fold<int>(0, (a, b) => b > a ? b : a).clamp(1, 1 << 30);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('WEEKLY EARNINGS',
                        style: GoogleFonts.robotoMono(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            letterSpacing: 2)),
                    const SizedBox(height: 2),
                    Text('Rs ${NumberFormat('#,###').format(byDay.fold(0, (a, b) => a + b))}',
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_upward_rounded,
                        color: AppColors.success, size: 12),
                    const SizedBox(width: 3),
                    Text('+18%',
                        style: GoogleFonts.inter(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final v = byDay[i];
                final h = ((v / maxVal) * 90).clamp(4.0, 90.0);
                final d = now.subtract(Duration(days: 6 - i));
                final isToday = i == 6;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isToday && v > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('Rs ${(v / 1000).toStringAsFixed(1)}k',
                                style: GoogleFonts.inter(
                                    color: AppColors.accent,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700)),
                          ),
                        Container(
                          height: h,
                          decoration: BoxDecoration(
                            gradient: v > 0
                                ? (isToday
                                    ? AppColors.primaryGradient
                                    : LinearGradient(
                                        colors: [
                                          AppColors.gold.withValues(alpha: 0.8),
                                          AppColors.gold.withValues(alpha: 0.4),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ))
                                : null,
                            color: v > 0 ? null : AppColors.surfaceHighest,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(DateFormat('E').format(d).substring(0, 1),
                            style: GoogleFonts.robotoMono(
                                color: isToday ? AppColors.accent : AppColors.textMuted,
                                fontSize: 10,
                                fontWeight: isToday ? FontWeight.w700 : FontWeight.w400)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 400.ms);
  }

  Widget _buildSection(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Text(label,
          style: GoogleFonts.robotoMono(
              color: AppColors.textMuted, fontSize: 10.5, letterSpacing: 2)),
    );
  }

  Widget _buildEmptyTx() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Center(
        child: Text('Complete a job to see transactions here.',
            style: GoogleFonts.inter(
                color: AppColors.textMuted, fontSize: 13)),
      ),
    );
  }

  Widget _buildPayoutCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.accent.withValues(alpha: 0.12),
          AppColors.surfaceCard,
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_rounded,
                    color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Next Payout',
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700)),
                    Text('Scheduled for Friday, 24 May',
                        style: GoogleFonts.inter(
                            color: AppColors.textMuted, fontSize: 11.5)),
                  ],
                ),
              ),
              Text('Rs 4,300',
                  style: GoogleFonts.inter(
                      color: AppColors.accent,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.72,
              minHeight: 6,
              backgroundColor: AppColors.surfaceHighest,
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
          const SizedBox(height: 6),
          Text('Rs 4,300 of Rs 6,000 threshold reached',
              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10.5)),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }
}

class _TxCard extends StatelessWidget {
  final EarningEntry? entry;
  final String? name;
  final String? service;
  final int? amount;
  final DateTime? date;
  final String? id;
  final int index;

  const _TxCard({
    this.entry,
    this.name,
    this.service,
    this.amount,
    this.date,
    this.id,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final n = entry?.customerName ?? name ?? '—';
    final s = entry?.service ?? service ?? '—';
    final a = entry?.amount ?? amount ?? 0;
    final d = entry?.date ?? date ?? DateTime.now();
    final i = entry?.jobId ?? id ?? '—';

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_downward_rounded,
                color: AppColors.success, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n,
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700)),
                Text('$s · $i',
                    style: GoogleFonts.inter(
                        color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+ Rs ${NumberFormat('#,###').format(a)}',
                  style: GoogleFonts.inter(
                      color: AppColors.success,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
              Text(DateFormat('d MMM').format(d),
                  style: GoogleFonts.inter(
                      color: AppColors.textMuted, fontSize: 10.5)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 60).ms, duration: 300.ms);
  }
}
