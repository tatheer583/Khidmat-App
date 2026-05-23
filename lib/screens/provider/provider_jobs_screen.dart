import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../theme/app_colors.dart';
import '../../models/provider_job.dart';

class ProviderJobsScreen extends StatefulWidget {
  const ProviderJobsScreen({super.key});

  @override
  State<ProviderJobsScreen> createState() => _ProviderJobsScreenState();
}

class _ProviderJobsScreenState extends State<ProviderJobsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Jobs',
            style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        centerTitle: false,
        backgroundColor: AppColors.background,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Consumer<AppState>(
            builder: (_, state, __) => Container(
              decoration:
                  BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
              child: TabBar(
                controller: _tab,
                indicatorColor: AppColors.gold,
                indicatorWeight: 2.5,
                labelColor: AppColors.gold,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle:
                    GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Incoming'),
                        if (state.incomingJobs.isNotEmpty) ...[
                          const SizedBox(width: 5),
                          Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                                color: AppColors.error, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Text('${state.incomingJobs.length}',
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Tab(text: 'Active'),
                  const Tab(text: 'Completed'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Consumer<AppState>(
        builder: (_, state, __) {
          return TabBarView(
            controller: _tab,
            children: [
              _buildIncomingList(state),
              _buildActiveList(state),
              _buildCompletedList(state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIncomingList(AppState state) {
    if (state.incomingJobs.isEmpty) {
      return _emptyState(
        icon: Icons.inbox_rounded,
        title: 'No Incoming Requests',
        subtitle: 'New job requests will appear here.\nMake sure you\'re marked as available.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: state.incomingJobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) =>
          _IncomingCard(job: state.incomingJobs[i], index: i),
    );
  }

  Widget _buildActiveList(AppState state) {
    if (state.acceptedJobs.isEmpty) {
      return _emptyState(
        icon: Icons.work_outline_rounded,
        title: 'No Active Jobs',
        subtitle: 'Accept incoming requests to see\nyour active jobs here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: state.acceptedJobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _ActiveCard(job: state.acceptedJobs[i], index: i),
    );
  }

  Widget _buildCompletedList(AppState state) {
    if (state.completedJobs.isEmpty) {
      return _emptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'No Completed Jobs',
        subtitle: 'Completed jobs will appear here\nwith earnings summary.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: state.completedJobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) =>
          _CompletedCard(job: state.completedJobs[i], index: i),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.line2),
              ),
              child: Icon(icon, color: AppColors.textMuted, size: 34),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: AppColors.textMuted, fontSize: 13, height: 1.5)),
          ],
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
      ),
    );
  }
}

class _IncomingCard extends StatelessWidget {
  final ProviderJob job;
  final int index;
  const _IncomingCard({required this.job, required this.index});

  Color get _urgencyColor {
    switch (job.urgency) {
      case 'HIGH': return AppColors.error;
      case 'MEDIUM': return AppColors.warning;
      default: return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _urgencyColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: _urgencyColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                    gradient: AppColors.goldGradient, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(job.customerInitial,
                    style: GoogleFonts.inter(
                        color: const Color(0xFF1A1208),
                        fontSize: 18,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _urgencyColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(job.urgency,
                        style: GoogleFonts.robotoMono(
                            color: _urgencyColor,
                            fontSize: 9,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 4),
                  Text('Rs ${job.quotedPrice}',
                      style: GoogleFonts.inter(
                          color: AppColors.accent,
                          fontSize: 16,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.handyman_rounded, color: AppColors.accent, size: 15),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.service,
                          style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700)),
                      Text(job.notes,
                          style: GoogleFonts.inter(
                              color: AppColors.textMuted, fontSize: 11, height: 1.35)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, color: AppColors.textMuted, size: 13),
              const SizedBox(width: 5),
              Text(job.requestedTime,
                  style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11.5)),
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
    ).animate().fadeIn(delay: (index * 80).ms, duration: 350.ms).slideY(begin: 0.06, end: 0);
  }
}

class _ActiveCard extends StatelessWidget {
  final ProviderJob job;
  final int index;
  const _ActiveCard({required this.job, required this.index});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final inProgress = job.status == JobStatus.inProgress;
    final statusColor = inProgress ? AppColors.warning : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: statusColor, shape: BoxShape.circle),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .scaleXY(begin: 0.6, end: 1.3, duration: 700.ms)
                        .then()
                        .scaleXY(begin: 1.3, end: 0.6, duration: 700.ms),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(job.customerName,
                          style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(inProgress ? 'IN PROGRESS' : 'ACCEPTED',
                    style: GoogleFonts.robotoMono(
                        color: statusColor,
                        fontSize: 9,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(job.service,
              style: GoogleFonts.inter(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('${job.location} · ${job.requestedTime}',
              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11.5)),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('Rs ${job.quotedPrice}',
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.call_rounded, size: 15),
                label: const Text('Call'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(color: AppColors.line2),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => state.updateJobStatus(
                    job.id,
                    inProgress ? JobStatus.completed : JobStatus.inProgress),
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  foregroundColor: inProgress
                      ? const Color(0xFF1A0A05)
                      : const Color(0xFF1A0A05),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(inProgress ? 'Mark Done' : 'Start Job',
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 80).ms, duration: 350.ms);
  }
}

class _CompletedCard extends StatelessWidget {
  final ProviderJob job;
  final int index;
  const _CompletedCard({required this.job, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 22),
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
                Text('${job.service} · ${job.location}',
                    style: GoogleFonts.inter(
                        color: AppColors.textMuted, fontSize: 11.5)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('COMPLETED',
                      style: GoogleFonts.robotoMono(
                          color: AppColors.success,
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
                      color: AppColors.success,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < 5 ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppColors.gold,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 80).ms, duration: 350.ms);
  }
}
