import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../services/gemini_service.dart';
import '../../services/app_state.dart';

class CustomerChatScreen extends StatefulWidget {
  const CustomerChatScreen({super.key});

  @override
  State<CustomerChatScreen> createState() => _CustomerChatScreenState();
}

class _CustomerChatScreenState extends State<CustomerChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _messages = [];
  bool _sending = false;
  bool _showQuickReplies = true;

  static const _quickReplies = [
    ('❄️', 'AC Repair', 'AC theek karwana hai, thanda nahi kar raha'),
    ('🔧', 'Plumber', 'Plumber chahiye, pipe leak ho raha hai'),
    ('⚡', 'Electrician', 'Electrician chahiye, bijli ka masla hai'),
    ('✂️', 'Beautician', 'Beautician chahiye ghar par, bridal/party'),
    ('📚', 'Tutor', 'Home tutor chahiye bachon ke liye'),
    ('🧹', 'House Cleaner', 'Ghar ki safai karwani hai'),
    ('🪚', 'Carpenter', 'Carpenter chahiye furniture ka kaam'),
    ('🎨', 'Painter', 'Ghar paint karwana hai'),
  ];

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(_Msg(
      fromUser: false,
      text: 'Assalamu Alaikum! 👋 Main KHIDMAT AI hun.\n\nAapko kaunsi service chahiye? Neeche se choose karein ya directly type karein — Urdu, Roman Urdu ya English mein!',
    ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? prefill]) async {
    final text = (prefill ?? _ctrl.text).trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _messages.add(_Msg(fromUser: true, text: text));
      _sending = true;
      _showQuickReplies = false;
      _ctrl.clear();
    });
    _scrollDown();

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final reply = await GeminiService.instance.generateResponse(text);
    if (!mounted) return;
    setState(() {
      _messages.add(_Msg(fromUser: false, text: reply));
      _sending = false;
      // Show "find provider" card if service intent detected
      if (_hasServiceIntent(text)) {
        _messages.add(_Msg(
          fromUser: false,
          isAction: true,
          actionQuery: text,
        ));
      }
    });
    _scrollDown();
  }

  bool _hasServiceIntent(String text) {
    final l = text.toLowerCase();
    final keywords = [
      'plumb', 'nalkay', 'pipe', 'leak',
      'electric', 'bijli', 'wiring',
      'ac ', 'cooling', 'thanda',
      'tutor', 'teacher', 'padhna',
      'clean', 'safai', 'maid',
      'carpenter', 'barhai', 'furniture',
      'paint', 'rang',
      'beautician', 'makeup',
      'driver', 'cook', 'khana',
    ];
    return keywords.any((k) => l.contains(k));
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          if (_showQuickReplies && _messages.length <= 1) _buildQuickReplies(),
          _buildComposer(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 10)],
            ),
            alignment: Alignment.center,
            child: Text('K',
                style: GoogleFonts.inter(
                    color: const Color(0xFF1A0A05),
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('KHIDMAT Assistant',
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                        color: AppColors.success, shape: BoxShape.circle),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .scaleXY(begin: 0.7, end: 1.2, duration: 800.ms)
                      .then()
                      .scaleXY(begin: 1.2, end: 0.7, duration: 800.ms),
                  const SizedBox(width: 5),
                  Text('Online · Gemini AI',
                      style: GoogleFonts.inter(
                          color: AppColors.textMuted, fontSize: 10.5)),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textMuted, size: 20),
          tooltip: 'New conversation',
          onPressed: () {
            GeminiService.instance.resetConversation();
            setState(() {
              _messages.clear();
              _showQuickReplies = true;
              _addWelcomeMessage();
            });
          },
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.line),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length + (_sending ? 1 : 0),
      itemBuilder: (_, i) {
        if (i >= _messages.length) {
          return const _TypingBubble();
        }
        final m = _messages[i];
        if (m.isAction) {
          return _FindProviderCard(query: m.actionQuery ?? '');
        }
        return _Bubble(message: m, index: i);
      },
    );
  }

  Widget _buildQuickReplies() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text('POPULAR SERVICES',
                style: GoogleFonts.robotoMono(
                    color: AppColors.textMuted, fontSize: 10, letterSpacing: 2)),
          ),
          SizedBox(
            height: 72,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              scrollDirection: Axis.horizontal,
              itemCount: _quickReplies.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final (emoji, label, query) = _quickReplies[i];
                return GestureDetector(
                  onTap: () => _send(query),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        AppColors.accent.withValues(alpha: 0.12),
                        AppColors.surfaceCard,
                      ]),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 3),
                        Text(label,
                            style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: (i * 60).ms, duration: 300.ms);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(top: BorderSide(color: AppColors.line)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, -4)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.line2),
                ),
                child: TextField(
                  controller: _ctrl,
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary, fontSize: 14),
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    filled: false,
                    hintText: 'Koi bhi service maangein…',
                    hintStyle: GoogleFonts.inter(
                        color: AppColors.textMuted, fontSize: 13.5),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sending ? null : _send,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: _sending ? null : AppColors.primaryGradient,
                  color: _sending ? AppColors.surfaceHighest : null,
                  shape: BoxShape.circle,
                  boxShadow: _sending
                      ? null
                      : [
                          BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.4),
                              blurRadius: 12)
                        ],
                ),
                child: Icon(
                  _sending ? Icons.hourglass_empty_rounded : Icons.send_rounded,
                  color: _sending ? AppColors.textMuted : const Color(0xFF1A0A05),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Message Model ────────────────────────────────────
class _Msg {
  final bool fromUser;
  final String text;
  final bool isAction;
  final String? actionQuery;

  _Msg({
    this.fromUser = false,
    this.text = '',
    this.isAction = false,
    this.actionQuery,
  });
}

// ─── Chat Bubble ──────────────────────────────────────
class _Bubble extends StatelessWidget {
  final _Msg message;
  final int index;
  const _Bubble({required this.message, required this.index});

  @override
  Widget build(BuildContext context) {
    final fromUser = message.fromUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisAlignment:
              fromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!fromUser) ...[
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 8, bottom: 2),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text('K',
                    style: GoogleFonts.inter(
                        color: const Color(0xFF1A0A05),
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
              ),
            ],
            Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                gradient: fromUser ? AppColors.primaryGradient : null,
                color: fromUser ? null : AppColors.surfaceCard,
                border: fromUser ? null : Border.all(color: AppColors.line2),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(fromUser ? 18 : 4),
                  bottomRight: Radius.circular(fromUser ? 4 : 18),
                ),
                boxShadow: fromUser
                    ? [
                        BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ]
                    : null,
              ),
              child: Text(
                message.text,
                style: GoogleFonts.inter(
                  color: fromUser
                      ? const Color(0xFF1A0A05)
                      : AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.48,
                  fontWeight:
                      fromUser ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.08, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }
}

// ─── Typing Bubble ────────────────────────────────────
class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text('K',
                  style: GoogleFonts.inter(
                      color: const Color(0xFF1A0A05),
                      fontSize: 13,
                      fontWeight: FontWeight.w800)),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                border: Border.all(color: AppColors.line2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  return Container(
                    margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .scaleXY(
                          begin: 0.5,
                          end: 1.0,
                          duration: 500.ms,
                          delay: (i * 150).ms,
                          curve: Curves.easeInOut)
                      .then()
                      .scaleXY(begin: 1.0, end: 0.5, duration: 500.ms);
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Find Provider CTA Card ───────────────────────────
class _FindProviderCard extends StatelessWidget {
  final String query;
  const _FindProviderCard({required this.query});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Container(
        margin: const EdgeInsets.only(left: 36),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            AppColors.accent.withValues(alpha: 0.15),
            AppColors.surfaceCard,
          ]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.search_rounded,
                      color: AppColors.accent, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Providers found nearby!',
                          style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                      Text('Tap to view verified & rated providers',
                          style: GoogleFonts.inter(
                              color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<AppState>().startPipeline(query);
                  context.push('/processing');
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('View Providers'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: const Color(0xFF1A0A05),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}
