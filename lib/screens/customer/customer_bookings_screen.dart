import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/app_state.dart';
import '../../models/provider_model.dart';
import '../../theme/app_colors.dart';

class CustomerBookingsScreen extends StatefulWidget {
  const CustomerBookingsScreen({super.key});

  @override
  State<CustomerBookingsScreen> createState() => _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends State<CustomerBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  static final _staticPast = [
    _PastBooking('Imran Hussain', 'Electrician', 'DHA Phase 5', '14 May, 4:00 PM', 1800, 4.9, '⚡'),
    _PastBooking('Bilal Khan', 'Plumber', 'Gulberg', '02 May, 11:00 AM', 1200, 4.7, '🔧'),
    _PastBooking('Zara Beauty Studio', 'Beautician', 'F-11', '28 Apr, 5:00 PM', 2400, 5.0, '✂️'),
    _PastBooking('Tariq Carpentry', 'Carpenter', 'G-9', '15 Apr, 10:00 AM', 3500, 4.8, '🪚'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Bookings',
            style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        centerTitle: false,
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Text('4 total',
                  style: GoogleFonts.inter(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.line)),
            ),
            child: TabBar(
              controller: _tab,
              indicatorColor: AppColors.accent,
              indicatorWeight: 2.5,
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: const [Tab(text: 'Active'), Tab(text: 'History')],
            ),
          ),
        ),
      ),
      body: Consumer<AppState>(
        builder: (_, state, __) {
          return TabBarView(
            controller: _tab,
            children: [
              _buildActiveTab(context, state),
              _buildHistoryTab(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActiveTab(BuildContext context, AppState state) {
    final active = state.currentBooking;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (active == null) ...[
          const SizedBox(height: 40),
          _emptyState(
            context,
            icon: Icons.receipt_long_outlined,
            title: 'No Active Bookings',
            subtitle: 'Book a service from Home and it will appear here.',
            actionLabel: 'Book a Service',
            onAction: () {
              // Switch to home tab (index 0)
              DefaultTabController.maybeOf(context)?.animateTo(0);
            },
          ),
        ] else ...[
          _activeBookingCard(context, active),
          const SizedBox(height: 16),
          _trackingCard(context),
        ],
      ],
    );
  }

  Widget _activeBookingCard(BuildContext context, BookingReceipt booking) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.success.withValues(alpha: 0.15),
          AppColors.surfaceCard,
        ]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                      color: AppColors.success, shape: BoxShape.circle),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .scaleXY(begin: 0.6, end: 1.2, duration: 700.ms)
                    .then()
                    .scaleXY(begin: 1.2, end: 0.6, duration: 700.ms),
                const SizedBox(width: 8),
                Text('ACTIVE BOOKING',
                    style: GoogleFonts.robotoMono(
                        color: AppColors.success,
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('# ${booking.bookingId}',
                    style: GoogleFonts.robotoMono(
                        color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                          gradient: AppColors.goldGradient, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(
                        booking.provider.name.isNotEmpty
                            ? booking.provider.name[0]
                            : 'P',
                        style: GoogleFonts.inter(
                            color: const Color(0xFF1A1208),
                            fontSize: 20,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(booking.provider.name,
                              style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          Text(booking.service,
                              style: GoogleFonts.inter(
                                  color: AppColors.accent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.star_rounded,
                                color: AppColors.gold, size: 13),
                            const SizedBox(width: 3),
                            Text('4.9',
                                style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Rs ${booking.finalPrice}',
                            style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800)),
                        if (booking.savedAmount > 0)
                          Text('Saved Rs ${booking.savedAmount}',
                              style: GoogleFonts.inter(
                                  color: AppColors.success,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0x14F1EDE4)),
                const SizedBox(height: 14),
                _infoRow(Icons.calendar_today_rounded, booking.date),
                const SizedBox(height: 8),
                _infoRow(Icons.access_time_rounded, booking.time),
                const SizedBox(height: 8),
                _infoRow(Icons.location_on_rounded, booking.location),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.call_rounded, size: 16),
                        label: const Text('Call'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: BorderSide(color: AppColors.line2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/tracking'),
                        icon: const Icon(Icons.my_location_rounded, size: 16),
                        label: const Text('Track Provider'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: const Color(0xFF1A0A05),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          textStyle: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0);
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 15),
        const SizedBox(width: 8),
        Text(text,
            style: GoogleFonts.inter(
                color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }

  Widget _trackingCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LIVE TRACKING',
              style: GoogleFonts.robotoMono(
                  color: AppColors.textMuted, fontSize: 10, letterSpacing: 2)),
          const SizedBox(height: 12),
          Row(
            children: [
              _statusStep(true, 'Booked', '10:30 AM'),
              _statusLine(true),
              _statusStep(true, 'On the way', '11:00 AM'),
              _statusLine(false),
              _statusStep(false, 'Arrived', '—'),
              _statusLine(false),
              _statusStep(false, 'Done', '—'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _statusStep(bool done, String label, String time) {
    return Column(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: done ? AppColors.accent : AppColors.surfaceHighest,
            shape: BoxShape.circle,
            border: Border.all(
                color: done ? AppColors.accent : AppColors.line2, width: 2),
          ),
          child: done
              ? const Icon(Icons.check_rounded,
                  color: Color(0xFF1A0A05), size: 14)
              : null,
        ),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.inter(
                color: done ? AppColors.textPrimary : AppColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w600)),
        Text(time,
            style: GoogleFonts.inter(
                color: AppColors.textMuted, fontSize: 8)),
      ],
    );
  }

  Widget _statusLine(bool done) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 26),
        color: done
            ? AppColors.accent.withValues(alpha: 0.6)
            : AppColors.surfaceHighest,
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _staticPast.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final p = _staticPast[i];
        return _HistoryCard(item: p, index: i);
      },
    );
  }

  Widget _emptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line2),
          ),
          child: Icon(icon, color: AppColors.textMuted, size: 32),
        ),
        const SizedBox(height: 16),
        Text(title,
            style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                color: AppColors.textMuted, fontSize: 13, height: 1.5)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onAction,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: const Color(0xFF1A0A05),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle:
                GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          child: Text(actionLabel),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

class _PastBooking {
  final String name;
  final String service;
  final String location;
  final String date;
  final int price;
  final double rating;
  final String emoji;
  _PastBooking(this.name, this.service, this.location, this.date, this.price,
      this.rating, this.emoji);
}

class _HistoryCard extends StatelessWidget {
  final _PastBooking item;
  final int index;
  const _HistoryCard({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(item.emoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    Text(item.service,
                        style: GoogleFonts.inter(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Rs ${item.price}',
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('DONE',
                        style: GoogleFonts.robotoMono(
                            color: AppColors.textMuted,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0x14F1EDE4)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: AppColors.textMuted, size: 13),
              const SizedBox(width: 4),
              Text(item.location,
                  style: GoogleFonts.inter(
                      color: AppColors.textMuted, fontSize: 11)),
              const SizedBox(width: 12),
              const Icon(Icons.access_time_rounded,
                  color: AppColors.textMuted, size: 13),
              const SizedBox(width: 4),
              Text(item.date,
                  style: GoogleFonts.inter(
                      color: AppColors.textMuted, fontSize: 11)),
              const Spacer(),
              Row(
                children: [
                  ...List.generate(
                    5,
                    (i) => Icon(
                      i < item.rating.round()
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: AppColors.gold,
                      size: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(item.rating.toStringAsFixed(1),
                      style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    side: BorderSide(color: AppColors.line2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    foregroundColor: AppColors.textSecondary,
                  ),
                  child: Text('Rate & Review',
                      style:
                          GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                    foregroundColor: AppColors.accent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Book Again',
                      style:
                          GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 80).ms, duration: 350.ms);
  }
}
