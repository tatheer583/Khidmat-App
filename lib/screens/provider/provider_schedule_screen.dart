import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/app_state.dart';
import '../../theme/app_colors.dart';

class ProviderScheduleScreen extends StatefulWidget {
  const ProviderScheduleScreen({super.key});

  @override
  State<ProviderScheduleScreen> createState() => _ProviderScheduleScreenState();
}

class _ProviderScheduleScreenState extends State<ProviderScheduleScreen> {
  int _selectedDay = 0;

  static const _slots = [
    '08:00', '09:00', '10:00', '11:00', '12:00',
    '13:00', '14:00', '15:00', '16:00', '17:00', '18:00', '19:00',
  ];

  static final _seedSlots = {
    0: {'09:00': 'AC Service — Raza Khan · G-11', '11:00': 'AC Repair — Farrukh Ali · F-10', '15:00': 'AC Installation — Bilal Co. · G-9'},
    1: {'10:00': 'AC Service — Sadia M. · G-13', '14:00': 'AC Repair — Hamid Shah · G-10'},
    2: {'09:00': 'AC Repair — Ahmed · F-8', '13:00': 'AC Service — Tariq · G-6', '16:00': 'AC Service — Rehana · G-7'},
  };

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (i) => DateTime.now().add(Duration(days: i)));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Schedule',
            style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        centerTitle: false,
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _showAddBlockDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_rounded,
                        color: Color(0xFF1A0A05), size: 16),
                    const SizedBox(width: 4),
                    Text('Block',
                        style: GoogleFonts.inter(
                            color: const Color(0xFF1A0A05),
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildWeekSummary(),
          _buildDayPicker(days),
          const Divider(height: 1, color: Color(0x14F1EDE4)),
          Expanded(child: _buildTimeline(days[_selectedDay])),
        ],
      ),
    );
  }

  Widget _buildWeekSummary() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.accent.withValues(alpha: 0.12),
          AppColors.surfaceCard,
        ]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(child: _summaryItem('8', 'This week', AppColors.accent)),
          Container(width: 1, height: 32, color: AppColors.line),
          Expanded(child: _summaryItem('3', 'Today', AppColors.gold)),
          Container(width: 1, height: 32, color: AppColors.line),
          Expanded(child: _summaryItem('2', 'Available slots', AppColors.success)),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }

  Widget _summaryItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.inter(
                color: color, fontSize: 18, fontWeight: FontWeight.w800)),
        Text(label,
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10)),
      ],
    );
  }

  Widget _buildDayPicker(List<DateTime> days) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final active = i == _selectedDay;
          final d = days[i];
          final hasJobs = _seedSlots.containsKey(i);
          return GestureDetector(
            onTap: () => setState(() => _selectedDay = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 62,
              decoration: BoxDecoration(
                gradient: active ? AppColors.primaryGradient : null,
                color: active ? null : AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: active
                      ? Colors.transparent
                      : hasJobs
                          ? AppColors.accent.withValues(alpha: 0.25)
                          : AppColors.line,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('E').format(d).toUpperCase(),
                      style: GoogleFonts.robotoMono(
                          color: active ? const Color(0xFF1A0A05) : AppColors.textMuted,
                          fontSize: 10,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text('${d.day}',
                      style: GoogleFonts.inter(
                          color: active ? const Color(0xFF1A0A05) : AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  if (hasJobs && !active)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          (_seedSlots[i]?.length ?? 0).clamp(0, 3),
                          (_) => Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: const BoxDecoration(
                                color: AppColors.accent, shape: BoxShape.circle),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeline(DateTime day) {
    final jobs = _seedSlots[_selectedDay] ?? {};
    return Consumer<AppState>(
      builder: (_, state, __) {
        final liveJobs = state.acceptedJobs;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          itemCount: _slots.length,
          itemBuilder: (_, i) {
            final slot = _slots[i];
            final seedJob = jobs[slot];
            final liveJob = _selectedDay == 0
                ? liveJobs.where(
                    (j) => j.requestedTime.contains(slot.substring(0, 2))).firstOrNull
                : null;
            final hasJob = seedJob != null || liveJob != null;
            final jobLabel = liveJob != null
                ? '${liveJob.service} — ${liveJob.customerName} · ${liveJob.location}'
                : (seedJob ?? '');

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 52,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 11),
                      child: Text(slot,
                          style: GoogleFonts.robotoMono(
                              color: hasJob ? AppColors.accent : AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: hasJob ? FontWeight.w700 : FontWeight.w400)),
                    ),
                  ),
                  Column(
                    children: [
                      const SizedBox(height: 11),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: hasJob ? AppColors.accent : AppColors.surfaceHighest,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: hasJob ? AppColors.accent : AppColors.line2,
                            width: 2,
                          ),
                        ),
                      ),
                      Container(
                        width: 2,
                        height: hasJob ? 68 : 40,
                        color: i < _slots.length - 1
                            ? AppColors.line2
                            : Colors.transparent,
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: hasJob
                            ? AppColors.accent.withValues(alpha: 0.08)
                            : AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasJob
                              ? AppColors.accent.withValues(alpha: 0.35)
                              : AppColors.line,
                        ),
                      ),
                      child: hasJob
                          ? Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(jobLabel.split(' — ').first,
                                          style: GoogleFonts.inter(
                                              color: AppColors.textPrimary,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700)),
                                      if (jobLabel.contains(' — '))
                                        Text(jobLabel.split(' — ').last,
                                            style: GoogleFonts.inter(
                                                color: AppColors.textMuted,
                                                fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Text('BOOKED',
                                      style: GoogleFonts.robotoMono(
                                          color: AppColors.accent,
                                          fontSize: 8.5,
                                          letterSpacing: 0.8,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ],
                            )
                          : Text('Available',
                              style: GoogleFonts.inter(
                                  color: AppColors.textMuted, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddBlockDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Block Time Slot',
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Mark a time as unavailable for new bookings',
                style: GoogleFonts.inter(
                    color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.line2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: const Color(0xFF1A0A05),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Block Slot',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
