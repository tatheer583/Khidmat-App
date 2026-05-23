import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';

class ServiceRequestScreen extends StatefulWidget {
  final String? prefilledService;
  const ServiceRequestScreen({super.key, this.prefilledService});

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  final _notesCtrl = TextEditingController();
  String? _selectedService;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _budgetMin = 500;
  int _budgetMax = 5000;
  String _urgency = 'Normal';
  bool _submitting = false;
  int _step = 0; // 0=service, 1=datetime, 2=budget, 3=confirm

  static const _services = [
    ('❄️', 'AC Repair', 'AC theek karwana hai'),
    ('🔧', 'Plumber', 'Pipe ya nalkay ka kaam'),
    ('⚡', 'Electrician', 'Bijli ka kaam'),
    ('✂️', 'Beautician', 'Beauty services ghar par'),
    ('📚', 'Tutor', 'Home tutor'),
    ('🧹', 'House Cleaner', 'Ghar ki safai'),
    ('🪚', 'Carpenter', 'Furniture ya lakri ka kaam'),
    ('🎨', 'Painter', 'Painting ka kaam'),
    ('🚗', 'Driver', 'Driver ki zaroorat'),
    ('👨‍🍳', 'Cook', 'Khana banana'),
    ('🌿', 'Gardener', 'Baghbani'),
    ('🔨', 'Handyman', 'General repair'),
  ];

  static const _urgencies = [
    ('🔴', 'Urgent', 'Within 2 hours'),
    ('🟡', 'Today', 'Same day'),
    ('🟢', 'Normal', 'Schedule date/time'),
  ];

  static const _budgetPresets = [
    (500, 1500, 'Budget (500–1.5k)'),
    (1500, 3000, 'Standard (1.5–3k)'),
    (3000, 6000, 'Premium (3–6k)'),
    (6000, 15000, 'Expert (6–15k)'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedService = widget.prefilledService;
    if (_selectedService != null) _step = 1;
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                      begin: const Offset(0.05, 0), end: Offset.zero)
                      .animate(anim),
                  child: child,
                ),
              ),
              child: _buildStep(),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final stepTitles = ['Choose Service', 'Date & Time', 'Budget', 'Confirm'];
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line2),
          ),
          child: Icon(
            _step == 0 ? Icons.close_rounded : Icons.arrow_back_rounded,
            color: AppColors.textSecondary,
            size: 18,
          ),
        ),
        onPressed: () {
          if (_step == 0) {
            Navigator.pop(context);
          } else {
            setState(() => _step--);
          }
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stepTitles[_step],
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
          Text('Step ${_step + 1} of 4',
              style: GoogleFonts.inter(
                  color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: List.generate(4, (i) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 3 ? 6 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              height: 4,
              decoration: BoxDecoration(
                color: i <= _step ? AppColors.accent : AppColors.surfaceHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        )),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildServiceStep();
      case 1:
        return _buildDateTimeStep();
      case 2:
        return _buildBudgetStep();
      case 3:
        return _buildConfirmStep();
      default:
        return const SizedBox();
    }
  }

  // ─── Step 1: Service Selection ─────────────────────
  Widget _buildServiceStep() {
    return SingleChildScrollView(
      key: const ValueKey(0),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kaunsi service chahiye?',
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Service select karein ya type karein',
              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.05,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: _services.length,
            itemBuilder: (_, i) {
              final (emoji, name, _) = _services[i];
              final selected = _selectedService == name;
              return GestureDetector(
                onTap: () => setState(() => _selectedService = name),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? AppColors.primaryGradient
                        : null,
                    color: selected ? null : AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : AppColors.line2,
                    ),
                    boxShadow: selected
                        ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 12)]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 6),
                      Text(name,
                          style: GoogleFonts.inter(
                            color: selected ? const Color(0xFF1A0A05) : AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: (i * 40).ms, duration: 300.ms);
            },
          ),
          const SizedBox(height: 20),
          _fieldLabel('Or describe what you need'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line2),
            ),
            child: TextField(
              controller: _notesCtrl,
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'e.g. "AC nahi chal raha, gas leak lag raha hai"',
                hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _fieldLabel('Urgency'),
          Row(
            children: _urgencies.map((u) {
              final (dot, label, sub) = u;
              final selected = _urgency == label;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _urgency = label),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: EdgeInsets.only(
                        right: label != 'Normal' ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.accent.withValues(alpha: 0.12)
                          : AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.accent.withValues(alpha: 0.5)
                            : AppColors.line,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(dot, style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(label,
                            style: GoogleFonts.inter(
                              color: selected ? AppColors.accent : AppColors.textPrimary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            )),
                        Text(sub,
                            style: GoogleFonts.inter(
                                color: AppColors.textMuted, fontSize: 9.5),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Date & Time ───────────────────────────
  Widget _buildDateTimeStep() {
    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kab chahiye?',
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Date aur time select karein',
              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 24),
          // Quick date buttons
          _fieldLabel('Select Date'),
          const SizedBox(height: 10),
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final d = DateTime.now().add(Duration(days: i));
                final selected = _selectedDate != null &&
                    _selectedDate!.day == d.day &&
                    _selectedDate!.month == d.month;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 62,
                    decoration: BoxDecoration(
                      gradient: selected ? AppColors.primaryGradient : null,
                      color: selected ? null : AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? Colors.transparent : AppColors.line2,
                      ),
                      boxShadow: selected
                          ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 10)]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          i == 0 ? 'Today' : DateFormat('EEE').format(d),
                          style: GoogleFonts.inter(
                            color: selected ? const Color(0xFF1A0A05) : AppColors.textMuted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text('${d.day}',
                            style: GoogleFonts.inter(
                              color: selected ? const Color(0xFF1A0A05) : AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            )),
                        Text(DateFormat('MMM').format(d),
                            style: GoogleFonts.inter(
                              color: selected ? const Color(0x881A0A05) : AppColors.textMuted,
                              fontSize: 9.5,
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 60)),
                builder: (ctx, child) => Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(primary: AppColors.accent),
                  ),
                  child: child!,
                ),
              );
              if (d != null) setState(() => _selectedDate = d);
            },
            icon: const Icon(Icons.calendar_month_rounded, size: 16),
            label: const Text('Pick a different date'),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
          ),
          const SizedBox(height: 24),
          _fieldLabel('Select Time'),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            childAspectRatio: 2.2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: _timeSlots.map((t) {
              final selected = _selectedTime?.hour == t.hour &&
                  _selectedTime?.minute == t.minute;
              return GestureDetector(
                onTap: () => setState(() => _selectedTime = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.accent
                        : AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? Colors.transparent : AppColors.line2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    t.format(context),
                    style: GoogleFonts.robotoMono(
                      color: selected ? const Color(0xFF1A0A05) : AppColors.textPrimary,
                      fontSize: 11.5,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: _selectedTime ?? TimeOfDay.now(),
                builder: (ctx, child) => Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(primary: AppColors.accent),
                  ),
                  child: child!,
                ),
              );
              if (t != null) setState(() => _selectedTime = t);
            },
            icon: const Icon(Icons.access_time_rounded, size: 16),
            label: const Text('Pick a custom time'),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
          ),
        ],
      ),
    );
  }

  static final _timeSlots = [
    const TimeOfDay(hour: 8, minute: 0),
    const TimeOfDay(hour: 9, minute: 0),
    const TimeOfDay(hour: 10, minute: 0),
    const TimeOfDay(hour: 11, minute: 0),
    const TimeOfDay(hour: 12, minute: 0),
    const TimeOfDay(hour: 13, minute: 0),
    const TimeOfDay(hour: 14, minute: 0),
    const TimeOfDay(hour: 15, minute: 0),
    const TimeOfDay(hour: 16, minute: 0),
    const TimeOfDay(hour: 17, minute: 0),
    const TimeOfDay(hour: 18, minute: 0),
    const TimeOfDay(hour: 19, minute: 0),
  ];

  // ─── Step 3: Budget ────────────────────────────────
  Widget _buildBudgetStep() {
    return SingleChildScrollView(
      key: const ValueKey(2),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kitna budget hai?',
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('AI apke budget mein best match dhundhega',
              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 24),
          // Budget display card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 16)
              ],
            ),
            child: Column(
              children: [
                Text('YOUR BUDGET',
                    style: GoogleFonts.robotoMono(
                        color: const Color(0x881A0A05),
                        fontSize: 10,
                        letterSpacing: 2)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Rs ${NumberFormat('#,###').format(_budgetMin)}',
                        style: GoogleFonts.inter(
                            color: const Color(0xFF1A0A05),
                            fontSize: 26,
                            fontWeight: FontWeight.w900)),
                    Text(' – ',
                        style: GoogleFonts.inter(
                            color: const Color(0x881A0A05),
                            fontSize: 22,
                            fontWeight: FontWeight.w700)),
                    Text('Rs ${NumberFormat('#,###').format(_budgetMax)}',
                        style: GoogleFonts.inter(
                            color: const Color(0xFF1A0A05),
                            fontSize: 26,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('AI will negotiate within this range',
                    style: GoogleFonts.inter(
                        color: const Color(0x881A0A05), fontSize: 11.5)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _fieldLabel('Quick presets'),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 3.2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: _budgetPresets.map((p) {
              final (mn, mx, label) = p;
              final selected = _budgetMin == mn && _budgetMax == mx;
              return GestureDetector(
                onTap: () => setState(() {
                  _budgetMin = mn;
                  _budgetMax = mx;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.accent.withValues(alpha: 0.12)
                        : AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? AppColors.accent.withValues(alpha: 0.5)
                          : AppColors.line2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(label,
                      style: GoogleFonts.inter(
                        color: selected ? AppColors.accent : AppColors.textPrimary,
                        fontSize: 12.5,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          _fieldLabel('Fine-tune your range'),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('Rs ${NumberFormat('#,###').format(_budgetMin)}',
                  style: GoogleFonts.robotoMono(
                      color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('Rs ${NumberFormat('#,###').format(_budgetMax)}',
                  style: GoogleFonts.robotoMono(
                      color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          RangeSlider(
            values: RangeValues(_budgetMin.toDouble(), _budgetMax.toDouble()),
            min: 200,
            max: 20000,
            divisions: 99,
            activeColor: AppColors.accent,
            inactiveColor: AppColors.surfaceHighest,
            onChanged: (v) => setState(() {
              _budgetMin = v.start.round();
              _budgetMax = v.end.round();
            }),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppColors.gold, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'KHIDMAT AI will negotiate with providers to get you the best price within your budget.',
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 4: Confirm ───────────────────────────────
  Widget _buildConfirmStep() {
    final service = _selectedService ?? 'Service';
    final dateStr = _selectedDate != null
        ? DateFormat('EEEE, d MMMM').format(_selectedDate!)
        : 'Not selected';
    final timeStr = _selectedTime?.format(context) ?? 'Not selected';

    return SingleChildScrollView(
      key: const ValueKey(3),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Confirm karein',
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Sab kuch theek hai? AI providers dhundh dega.',
              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppColors.accent.withValues(alpha: 0.15),
                      Colors.transparent,
                    ]),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 10)],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _getEmoji(service),
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(service,
                              style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900)),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _urgencyColor().withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(_urgency.toUpperCase(),
                                style: GoogleFonts.robotoMono(
                                    color: _urgencyColor(),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _confirmRow(Icons.calendar_today_rounded, 'Date', dateStr, AppColors.info),
                      const SizedBox(height: 12),
                      _confirmRow(Icons.access_time_rounded, 'Time', timeStr, AppColors.success),
                      const SizedBox(height: 12),
                      _confirmRow(Icons.account_balance_wallet_rounded, 'Budget',
                          'Rs ${NumberFormat('#,###').format(_budgetMin)} – Rs ${NumberFormat('#,###').format(_budgetMax)}',
                          AppColors.gold),
                      if (_notesCtrl.text.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _confirmRow(Icons.notes_rounded, 'Notes', _notesCtrl.text, AppColors.textMuted),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology_rounded, color: AppColors.accent, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('KHIDMAT AI will now:',
                          style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('• Find verified $service providers near you\n• Rank them by trust score & rating\n• Negotiate best price within your budget',
                          style: GoogleFonts.inter(
                              color: AppColors.textMuted, fontSize: 11.5, height: 1.5)),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
        ],
      ),
    );
  }

  Widget _confirmRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      color: AppColors.textMuted, fontSize: 11)),
              Text(value,
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Bottom Bar ────────────────────────────────────
  Widget _buildBottomBar() {
    final isLast = _step == 3;
    final canProceed = _step == 0
        ? (_selectedService != null || _notesCtrl.text.trim().isNotEmpty)
        : _step == 1
            ? (_selectedDate != null && _selectedTime != null)
            : true;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(top: BorderSide(color: AppColors.line)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: canProceed && !_submitting ? _nextStep : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 54,
            decoration: BoxDecoration(
              gradient: canProceed ? AppColors.primaryGradient : null,
              color: canProceed ? null : AppColors.surfaceHighest,
              borderRadius: BorderRadius.circular(14),
              boxShadow: canProceed
                  ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))]
                  : null,
            ),
            alignment: Alignment.center,
            child: _submitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Color(0xFF1A0A05), strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLast ? 'Find Providers Now' : 'Continue',
                        style: GoogleFonts.inter(
                          color: canProceed ? const Color(0xFF1A0A05) : AppColors.textMuted,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (canProceed) ...[
                        const SizedBox(width: 8),
                        Icon(
                          isLast ? Icons.search_rounded : Icons.arrow_forward_rounded,
                          color: const Color(0xFF1A0A05),
                          size: 20,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  void _nextStep() {
    if (_step < 3) {
      setState(() => _step++);
    } else {
      _submitRequest();
    }
  }

  Future<void> _submitRequest() async {
    setState(() => _submitting = true);
    final service = _selectedService ?? _notesCtrl.text.trim();
    final dateStr = _selectedDate != null
        ? DateFormat('d/M/yyyy').format(_selectedDate!)
        : 'Today';
    final timeStr = _selectedTime?.format(context) ?? '10:00 AM';
    final query =
        '$service in ${context.read<AppState>().userCity} on $dateStr at $timeStr, budget Rs $_budgetMin to $_budgetMax, urgency: $_urgency. Notes: ${_notesCtrl.text.trim()}';

    context.read<AppState>().startPipelineWithRequest(
          query: query,
          service: service,
          date: _selectedDate,
          time: _selectedTime,
          budgetMin: _budgetMin,
          budgetMax: _budgetMax,
          urgency: _urgency,
          notes: _notesCtrl.text.trim(),
        );
    if (!mounted) return;
    context.go('/processing');
  }

  String _getEmoji(String service) {
    final map = {
      'AC Repair': '❄️', 'Plumber': '🔧', 'Electrician': '⚡',
      'Beautician': '✂️', 'Tutor': '📚', 'House Cleaner': '🧹',
      'Carpenter': '🪚', 'Painter': '🎨', 'Driver': '🚗',
      'Cook': '👨‍🍳', 'Gardener': '🌿', 'Handyman': '🔨',
    };
    return map[service] ?? '🔧';
  }

  Color _urgencyColor() {
    switch (_urgency) {
      case 'Urgent': return AppColors.error;
      case 'Today': return AppColors.warning;
      default: return AppColors.success;
    }
  }

  Widget _fieldLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(label,
            style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600)),
      );
}
