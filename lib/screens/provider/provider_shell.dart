import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import 'provider_dashboard_screen.dart';
import 'provider_jobs_screen.dart';
import 'provider_schedule_screen.dart';
import 'provider_earnings_screen.dart';
import 'provider_profile_screen.dart';

class ProviderShell extends StatefulWidget {
  const ProviderShell({super.key});

  @override
  State<ProviderShell> createState() => _ProviderShellState();
}

class _ProviderShellState extends State<ProviderShell> {
  int _index = 0;

  static const _pages = <Widget>[
    ProviderDashboardScreen(),
    ProviderJobsScreen(),
    ProviderScheduleScreen(),
    ProviderEarningsScreen(),
    ProviderProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: _ProviderNavBar(
        index: _index,
        onChange: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _ProviderNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChange;
  const _ProviderNavBar({required this.index, required this.onChange});

  static const _items = [
    (Icons.dashboard_rounded, Icons.dashboard_outlined, 'Home'),
    (Icons.work_history_rounded, Icons.work_outline_rounded, 'Jobs'),
    (Icons.event_rounded, Icons.event_outlined, 'Schedule'),
    (Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined, 'Earnings'),
    (Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(top: BorderSide(color: AppColors.line)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: List.generate(_items.length, (i) {
              final active = i == index;
              final (activeIcon, inactiveIcon, label) = _items[i];
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChange(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.gold.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            active ? activeIcon : inactiveIcon,
                            key: ValueKey(active),
                            color: active ? AppColors.gold : AppColors.textMuted,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: GoogleFonts.inter(
                            color: active ? AppColors.gold : AppColors.textMuted,
                            fontSize: 9.5,
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w500,
                          ),
                          child: Text(label),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
