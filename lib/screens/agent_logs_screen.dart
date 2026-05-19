import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/agent_log.dart';
import '../theme/app_colors.dart';

class AgentLogsScreen extends StatelessWidget {
  const AgentLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Icon(Icons.terminal, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text('Agent Logs', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
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
          if (state.agentLogs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.terminal, color: AppColors.textMuted, size: 48),
                  const SizedBox(height: 16),
                  Text('No agent logs yet', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 15)),
                  const SizedBox(height: 8),
                  Text('Start a service request to see agent trace', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => ctx.go('/home'),
                    child: const Text('Go to Home'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(state),
              const SizedBox(height: 16),
              ...state.agentLogs.asMap().entries.map((e) {
                final i = e.key;
                final log = e.value;
                return _buildLogEntry(log, i);
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(AppState state) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_tree_outlined, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                'KHIDMAT Agent Pipeline Trace',
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${state.agentLogs.length} agents executed · '
            '${state.agentLogs.where((l) => l.status == AgentStatus.complete).length} completed · '
            'Full reasoning trace below',
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 12),
          _buildPipelineVisualization(state),
        ],
      ),
    );
  }

  Widget _buildPipelineVisualization(AppState state) {
    final executedIds = state.agentLogs.map((l) => l.agent).toSet();
    final allAgents = [AgentId.faham, AgentId.dhoond, AgentId.bharosa, AgentId.molBhaav, AgentId.book, AgentId.yaadDahani];

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: allAgents.length,
        itemBuilder: (ctx, i) {
          final agentId = allAgents[i];
          final info = agentRegistry[agentId]!;
          final color = Color(info.colorValue);
          final isExecuted = executedIds.contains(agentId);
          final isActive = state.activeAgent == agentId;

          return Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isExecuted ? color.withValues(alpha: 0.2) : AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isExecuted ? color.withValues(alpha: 0.6) : AppColors.divider,
                        width: isActive ? 2 : 1,
                      ),
                      boxShadow: isActive
                          ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        info.name.substring(0, 1),
                        style: GoogleFonts.inter(
                          color: isExecuted ? color : AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (i < allAgents.length - 1)
                Container(
                  width: 20,
                  height: 1,
                  color: isExecuted ? color.withValues(alpha: 0.4) : AppColors.divider,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogEntry(AgentLogEntry log, int index) {
    final info = agentRegistry[log.agent]!;
    final color = Color(info.colorValue);
    final bgColor = Color(info.bgColorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(13),
                topRight: Radius.circular(13),
              ),
            ),
            child: Row(
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
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.inter(color: color, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(info.name, style: GoogleFonts.inter(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 6),
                        Text(info.urduName, style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 12)),
                      ],
                    ),
                    Text(info.description, style: GoogleFonts.inter(color: color.withValues(alpha: 0.6), fontSize: 10)),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.trustHigh.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.trustHigh, size: 10),
                          const SizedBox(width: 4),
                          Text('COMPLETE', style: GoogleFonts.inter(color: AppColors.trustHigh, fontSize: 9, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(log.duration, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),

          // Log lines
          Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: log.lines.asMap().entries.map((e) {
                  final i = e.key;
                  final line = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${String.fromCharCode(0x25BA)} ',
                          style: TextStyle(color: color.withValues(alpha: 0.5), fontSize: 9),
                        ),
                        Expanded(
                          child: Text(
                            line,
                            style: GoogleFonts.jetBrainsMono(
                              color: color.withValues(alpha: 0.85),
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(delay: (i * 80).ms, duration: 300.ms),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (index * 100).ms, duration: 400.ms)
        .slideX(begin: -0.03, end: 0, delay: (index * 100).ms, duration: 400.ms);
  }
}
