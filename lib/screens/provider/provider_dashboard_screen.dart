import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/app_state.dart';
import '../../theme/app_colors.dart';
import '../../models/provider_job.dart';

class ProviderDashboardScreen extends StatelessWidget {
  const ProviderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<AppState>(
          builder: (_, state, __) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context, state)),
                SliverToBoxAdapter(child: const SizedBox(height: 16)),
                SliverToBoxAdapter(child: _buildEarningsCard(context, state)),
                SliverToBoxAdapter(child: const SizedBox(height: 14)),
                SliverToBoxAdapter(child: _buildStatsRow(state)),
                SliverToBoxAdapter(child: _buildSection('INCOMING REQUESTS', count: state.incomingJobs.length)),
                if (state.incomingJobs.isEmpty)
                  SliverToBoxAdapter(child: _buildEmpty('No new requests right now. Stay available!'))
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: _IncomingJobCard(job: state.incomingJobs[i]),
                      ),
                      childCount: state.incomingJobs.take(2).length,
                    ),
                  ),
                SliverToBoxAdapter(
                  child: _buildSection(
                      'TODAY · ${DateFormat('EEE, d MMM').format(DateTime.now())}'),
                ),
                if (state.acceptedJobs.isEmpty)
                  SliverToBoxAdapter(
                      child: _buildEmpty('No jobs scheduled for today.'))
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: _TodayJobCard(job: state.acceptedJobs[i]),
                      ),
                      childCount: state.acceptedJobs.length,
                    ),
                  ),
                SliverToBoxAdapter(child: _buildSection('PERFORMANCE')),
                SliverToBoxAdapter(child: _buildPerformanceCard(state)),
                SliverToBoxAdapter(child: _buildSection('QUICK ACTIONS')),
                SliverToBoxAdapter(child: _buildQuickActions(context)),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Asalam-o-alaikum,',
                    style: GoogleFonts.inter(
                        color: AppColors.textMuted, fontSize: 13)),
                const SizedBox(height: 2),
                Text('Ali Hassan',
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.handyman_rounded,
                        color: AppColors.gold, size: 12),
                    const SizedBox(width: 4),
                    Text('AC Technician · G-13, Islamabad',
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary, fontSize: 11.5)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                    gradient: AppColors.goldGradient, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text('A',
                    style: GoogleFonts.inter(
                        color: const Color(0xFF1A1208),
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: AppColors.success, shape: BoxShape.circle),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .scaleXY(begin: 0.6, end: 1.3, duration: 800.ms)
                      .then()
                      .scaleXY(begin: 1.3, end: 0.6, duration: 800.ms),
                  const SizedBox(width: 4),
                  Text('Online',
                      style: GoogleFonts.inter(
                          color: AppColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildEarningsCard(BuildContext context, AppState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
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
                blurRadius: 20,
                offset: const Offset(0, 8))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL EARNINGS',
                        style: GoogleFonts.robotoMono(
                            color: const Color(0xCC1A1208),
                            fontSize: 10,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                        'Rs ${NumberFormat('#,###').format(state.totalEarnings)}',
                        style: GoogleFonts.inter(
                            color: const Color(0xFF1A1208),
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x331A1208),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: Color(0xFF1A1208), size: 26),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              height: 1,
              color: const Color(0x331A1208),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _earningsStat(
                      'This Week',
                      'Rs ${NumberFormat('#,###').format(state.weekEarnings)}'),
                ),
                Container(
                    width: 1, height: 30, color: const Color(0x331A1208)),
                Expanded(child: _earningsStat('Jobs Done', '${state.completedJobs.length}')),
                Container(
                    width: 1, height: 30, color: const Color(0x331A1208)),
                Expanded(
                  child: _earningsStat(
                      'Avg Rating',
                      state.providerAvgRating > 0
                          ? '${state.providerAvgRating.toStringAsFixed(1)} ★'
                          : '— ★'),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.06, end: 0),
    );
  }

  Widget _earningsStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.inter(
                color: const Color(0xFF1A1208),
                fontSize: 13.5,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.inter(
                color: const Color(0xCC1A1208), fontSize: 10)),
      ],
    );
  }

  Widget _buildStatsRow(AppState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
              child: _stat('Active', '${state.acceptedJobs.length}', 'jobs today',
                  AppColors.accent, Icons.work_outline_rounded)),
          const SizedBox(width: 10),
          Expanded(
              child: _stat('Incoming', '${state.incomingJobs.length}', 'new requests',
                  AppColors.warning, Icons.notifications_active_rounded)),
          const SizedBox(width: 10),
          Expanded(
              child: _stat('Rating', state.reviews.isEmpty ? '—' : state.providerAvgRating.toStringAsFixed(1),
                  'avg score', AppColors.gold, Icons.star_rounded)),
        ],
      ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
    );
  }

  Widget _stat(String tag, String value, String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const Spacer(),
              Text(tag,
                  style: GoogleFonts.robotoMono(
                      color: color,
                      fontSize: 8.5,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3)),
          Text(label,
              style:
                  GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildSection(String label, {int? count}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          Text(label,
              style: GoogleFonts.robotoMono(
                  color: AppColors.textMuted, fontSize: 10.5, letterSpacing: 2)),
          if (count != null && count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$count',
                  style: GoogleFonts.inter(
                      color: const Color(0xFF1A0A05),
                      fontSize: 9,
                      fontWeight: FontWeight.w800)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty(String msg) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: AppColors.textMuted, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(msg,
                  style: GoogleFonts.inter(
                      color: AppColors.textMuted, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(AppState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            _perfBar('Acceptance rate', 0.92, '92%', AppColors.success),
            const SizedBox(height: 14),
            _perfBar('Completion rate', 0.97, '97%', AppColors.accent),
            const SizedBox(height: 14),
            _perfBar('Response speed', 0.85, '< 15 min', AppColors.gold),
            const SizedBox(height: 14),
            _perfBar('Customer satisfaction', 0.94, '94%', AppColors.info),
          ],
        ),
      ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
    );
  }

  Widget _perfBar(String label, double val, String text, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: Text(label,
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondary, fontSize: 12.5))),
            Text(text,
                style: GoogleFonts.inter(
                    color: color, fontSize: 12.5, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: val,
            minHeight: 6,
            backgroundColor: AppColors.surfaceHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      (Icons.event_available_rounded, 'Set Schedule', AppColors.info),
      (Icons.rate_review_rounded, 'View Reviews', AppColors.gold),
      (Icons.bar_chart_rounded, 'Insights', AppColors.success),
      (Icons.share_rounded, 'Share Profile', AppColors.accent),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: actions.asMap().entries.map((e) {
          final i = e.key;
          final (icon, label, color) = e.value;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < actions.length - 1 ? 8 : 0),
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: color, size: 18),
                      ),
                      const SizedBox(height: 6),
                      Text(label,
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
    );
  }
}

// ─── Incoming Job Card ────────────────────────────────
class _IncomingJobCard extends StatelessWidget {
  final ProviderJob job;
  const _IncomingJobCard({required this.job});

  Color get _urgencyColor {
    switch (job.urgency) {
      case 'HIGH':
        return AppColors.error;
      case 'MEDIUM':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          _urgencyColor.withValues(alpha: 0.1),
          AppColors.surfaceCard,
        ]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _urgencyColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
              color: _urgencyColor.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                    gradient: AppColors.goldGradient, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(job.customerInitial,
                    style: GoogleFonts.inter(
                        color: const Color(0xFF1A1208),
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.customerName,
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    Text('${job.location} · ${job.distanceKm}',
                        style: GoogleFonts.inter(
                            color: AppColors.textMuted, fontSize: 11.5)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _urgencyColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(job.urgency,
                    style: GoogleFonts.robotoMono(
                        color: _urgencyColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.service,
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(job.notes,
                    style: GoogleFonts.inter(
                        color: AppColors.textMuted, fontSize: 11.5, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  color: AppColors.textMuted, size: 13),
              const SizedBox(width: 4),
              Text(job.requestedTime,
                  style: GoogleFonts.inter(
                      color: AppColors.textMuted, fontSize: 11)),
              const Spacer(),
              Text('Rs ${job.quotedPrice}',
                  style: GoogleFonts.inter(
                      color: AppColors.accent,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      state.updateJobStatus(job.id, JobStatus.declined),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.line2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    foregroundColor: AppColors.textSecondary,
                  ),
                  child: Text('Decline',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () =>
                      state.updateJobStatus(job.id, JobStatus.accepted),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: const Color(0xFF1A0A05),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    shadowColor: AppColors.accent.withValues(alpha: 0.4),
                  ),
                  child: Text('Accept Job',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0);
  }
}

// ─── Today Job Card ───────────────────────────────────
class _TodayJobCard extends StatelessWidget {
  final ProviderJob job;
  const _TodayJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final inProgress = job.status == JobStatus.inProgress;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: inProgress
              ? AppColors.warning.withValues(alpha: 0.4)
              : AppColors.accent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 52,
            decoration: BoxDecoration(
              color: inProgress ? AppColors.warning : AppColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${job.customerName} · ${job.requestedTime}',
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(job.service,
                    style: GoogleFonts.inter(
                        color: AppColors.textMuted, fontSize: 11.5)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: (inProgress ? AppColors.warning : AppColors.success)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(inProgress ? 'IN PROGRESS' : 'ACCEPTED',
                      style: GoogleFonts.robotoMono(
                          color: inProgress ? AppColors.warning : AppColors.success,
                          fontSize: 8.5,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Rs ${job.quotedPrice}',
                  style: GoogleFonts.inter(
                      color: AppColors.accent,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => state.updateJobStatus(
                    job.id,
                    inProgress ? JobStatus.completed : JobStatus.inProgress),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(inProgress ? 'Complete' : 'Start',
                      style: GoogleFonts.inter(
                          color: const Color(0xFF1A0A05),
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
