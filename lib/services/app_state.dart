import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/provider_model.dart';
import '../models/agent_log.dart';
import '../models/provider_job.dart';
import '../agents/faham_agent.dart';
import '../agents/bharosa_agent.dart';
import '../agents/molbhaav_agent.dart';
import '../data/providers_data.dart';
import '../data/provider_jobs_data.dart';
import 'gemini_service.dart';

enum PipelineStage { idle, parsing, searching, scoring, negotiating, booking, complete }
enum UserRole { none, customer, provider }

class ServiceRequest {
  final String service;
  final DateTime? date;
  final TimeOfDay? time;
  final int budgetMin;
  final int budgetMax;
  final String urgency;
  final String notes;

  const ServiceRequest({
    required this.service,
    this.date,
    this.time,
    required this.budgetMin,
    required this.budgetMax,
    required this.urgency,
    required this.notes,
  });
}

class AppState extends ChangeNotifier {
  final _uuid = const Uuid();

  // ─── User Profile ───
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';
  String _userCity = 'Islamabad';

  String get userName => _userName.isNotEmpty ? _userName : 'Guest';
  String get userEmail => _userEmail;
  String get userPhone => _userPhone;
  String get userCity => _userCity;
  String get userInitial => _userName.isNotEmpty ? _userName[0].toUpperCase() : 'G';

  void setUserProfile({required String name, required String email, String phone = ''}) {
    _userName = name;
    _userEmail = email;
    _userPhone = phone;
    notifyListeners();
  }

  // ─── Service Request ───
  ServiceRequest? _serviceRequest;
  ServiceRequest? get serviceRequest => _serviceRequest;

  // ─── Role ───
  UserRole _role = UserRole.none;
  UserRole get role => _role;
  void setRole(UserRole r) {
    _role = r;
    if (r == UserRole.provider && _jobs.isEmpty) {
      _jobs.addAll(seedJobs());
      _earnings.addAll(seedEarnings());
      _reviews.addAll(seedReviews());
    }
    notifyListeners();
  }

  // ─── Provider data ───
  final List<ProviderJob> _jobs = [];
  final List<EarningEntry> _earnings = [];
  final List<ProviderReview> _reviews = [];
  List<ProviderJob> get jobs => List.unmodifiable(_jobs);
  List<ProviderJob> get incomingJobs =>
      _jobs.where((j) => j.status == JobStatus.incoming).toList();
  List<ProviderJob> get acceptedJobs => _jobs
      .where((j) => j.status == JobStatus.accepted || j.status == JobStatus.inProgress)
      .toList();
  List<ProviderJob> get completedJobs =>
      _jobs.where((j) => j.status == JobStatus.completed).toList();
  List<EarningEntry> get earnings => List.unmodifiable(_earnings);
  List<ProviderReview> get reviews => List.unmodifiable(_reviews);

  int get totalEarnings => _earnings.fold(0, (a, e) => a + e.amount);
  int get weekEarnings => _earnings
      .where((e) => DateTime.now().difference(e.date).inDays < 7)
      .fold(0, (a, e) => a + e.amount);
  double get providerAvgRating => _reviews.isEmpty
      ? 0
      : _reviews.map((r) => r.rating).reduce((a, b) => a + b) / _reviews.length;

  void updateJobStatus(String jobId, JobStatus status) {
    final j = _jobs.firstWhere((j) => j.id == jobId);
    j.status = status;
    if (status == JobStatus.completed) {
      _earnings.insert(
        0,
        EarningEntry(
          jobId: j.id,
          customerName: j.customerName,
          service: j.service,
          amount: j.quotedPrice,
          date: DateTime.now(),
        ),
      );
    }
    notifyListeners();
  }

  // ─── Chat ───
  final List<ChatMessage> messages = [];
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  // ─── Pipeline ───
  PipelineStage _stage = PipelineStage.idle;
  PipelineStage get stage => _stage;
  AgentId? _activeAgent;
  AgentId? get activeAgent => _activeAgent;
  final List<AgentLogEntry> agentLogs = [];

  // ─── Intent / Booking State ───
  String? currentQuery;
  ParsedIntent? currentIntent;
  List<BharosaReport>? rankedProviders;
  BharosaReport? selectedProvider;
  NegotiationResult? negotiationResult;
  BookingReceipt? currentBooking;
  String? geminiApiKey;

  // Pipeline with full service request details
  void startPipelineWithRequest({
    required String query,
    required String service,
    DateTime? date,
    TimeOfDay? time,
    required int budgetMin,
    required int budgetMax,
    required String urgency,
    required String notes,
  }) {
    _serviceRequest = ServiceRequest(
      service: service,
      date: date,
      time: time,
      budgetMin: budgetMin,
      budgetMax: budgetMax,
      urgency: urgency,
      notes: notes,
    );
    startPipeline(query);
  }

  // Pipeline-mode entry point (no chat messages — used by new search-based home)
  void startPipeline(String query) {
    currentQuery = query;
    currentIntent = null;
    rankedProviders = null;
    selectedProvider = null;
    negotiationResult = null;
    currentBooking = null;
    agentLogs.clear();
    messages.clear();
    _stage = PipelineStage.idle;
    _activeAgent = null;
    _isProcessing = true;
    notifyListeners();
    _runFahamAgent(query);
  }

  void setGeminiApiKey(String key) {
    geminiApiKey = key;
    GeminiService.instance.initialize(key);
    notifyListeners();
  }

  void addWelcomeMessages() {
    if (messages.isNotEmpty) return;
    messages.add(ChatMessage.agent(
      'Assalamu Alaikum! 👋 Main KHIDMAT AI hun.\n\n'
      'Main Pakistan ke informal economy workers ke saath aapko connect karta hun — '
      'plumbers, electricians, AC technicians, tutors, beauticians aur bahut kuch.\n\n'
      'Sirf batayein aapko kya chahiye — Urdu, Roman Urdu ya English mein! 🇵🇰',
    ));
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isProcessing) return;

    // Add user message
    messages.add(ChatMessage.user(text));
    _isProcessing = true;
    notifyListeners();

    // Show typing indicator
    final typingMsg = ChatMessage.typing();
    messages.add(typingMsg);
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    // Remove typing indicator
    messages.removeWhere((m) => m.id == 'typing');

    // Get Gemini response
    final geminiResponse = await GeminiService.instance.generateResponse(text);
    messages.add(ChatMessage.agent(geminiResponse));
    notifyListeners();

    // Run FAHAM agent to parse intent
    await Future.delayed(const Duration(milliseconds: 500));
    await _runFahamAgent(text);
  }

  Future<void> _runFahamAgent(String input) async {
    _stage = PipelineStage.parsing;
    _activeAgent = AgentId.faham;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1200));

    final intent = FahamAgent.parse(input);
    currentIntent = intent;

    agentLogs.add(AgentLogEntry(
      id: _uuid.v4(),
      agent: AgentId.faham,
      timestamp: DateTime.now(),
      duration: '1.2s',
      status: AgentStatus.complete,
      lines: [
        'Input language: ${intent.detectedLanguage}',
        'Service detected: ${intent.serviceType}',
        'Location: ${intent.location}',
        'Time: ${intent.time}',
        'Urgency: ${intent.urgency.name.toUpperCase()}',
        if (intent.budget != null) 'Budget: Rs. ${intent.budget}',
        if (intent.specialNotes.isNotEmpty) 'Notes: ${intent.specialNotes}',
      ],
    ));

    messages.add(ChatMessage.intentCard(intent));
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));
    await _runDhoondAgent(intent);
  }

  Future<void> _runDhoondAgent(ParsedIntent intent) async {
    _stage = PipelineStage.searching;
    _activeAgent = AgentId.dhoond;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1500));

    final providers = getProvidersByCategory(intent.serviceType);

    agentLogs.add(AgentLogEntry(
      id: _uuid.v4(),
      agent: AgentId.dhoond,
      timestamp: DateTime.now(),
      duration: '1.5s',
      status: AgentStatus.complete,
      lines: [
        'Scanning providers in ${intent.location}',
        'Category filter: ${intent.serviceType}',
        '${providers.length} providers found in database',
        'Distance calculation complete',
        'Availability check: ${providers.where((p) => p.availableSlots.isNotEmpty).length} available today',
      ],
    ));

    messages.add(ChatMessage.agent(
      '🟡 DHOOND Agent: ${providers.length} providers found for ${intent.serviceType} near ${intent.location}. '
      'Running BHAROSA trust analysis...',
    ));
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));
    await _runBharosaAgent(providers, intent.serviceType);
  }

  Future<void> _runBharosaAgent(List<ServiceProvider> providers, String serviceType) async {
    _stage = PipelineStage.scoring;
    _activeAgent = AgentId.bharosa;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1800));

    final ranked = BharosaAgent.rankAll(providers);
    rankedProviders = ranked;

    agentLogs.add(AgentLogEntry(
      id: _uuid.v4(),
      agent: AgentId.bharosa,
      timestamp: DateTime.now(),
      duration: '1.8s',
      status: AgentStatus.complete,
      lines: [
        'Evaluating ${ranked.length} providers',
        'Formula: completion(×0.4) + speed(×0.3) + vouches(×0.2) + rating(×0.1)',
        ...ranked.take(3).map((r) => '${r.provider.name}: ${r.trustScore}/100 — ${r.recommendation.name}'),
        'Top recommendation: ${ranked.first.provider.name} (${ranked.first.trustScore}/100)',
      ],
    ));

    messages.add(ChatMessage.agent(
      '🟢 BHAROSA Agent: Trust analysis complete!\n\n'
      '🏆 Top Pick: **${ranked.first.provider.name}** (${ranked.first.trustScore}/100)\n'
      '${ranked.first.explanation}\n\n'
      'View all ${ranked.length} providers ↓',
    ));

    _stage = PipelineStage.idle;
    _activeAgent = null;
    _isProcessing = false;
    notifyListeners();
  }

  Future<void> startNegotiation(BharosaReport report) async {
    selectedProvider = report;
    _stage = PipelineStage.negotiating;
    _activeAgent = AgentId.molBhaav;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 2000));

    final result = MolBhaavAgent.negotiate(report.provider, currentIntent?.serviceType ?? 'General Service');
    negotiationResult = result;

    agentLogs.add(AgentLogEntry(
      id: _uuid.v4(),
      agent: AgentId.molBhaav,
      timestamp: DateTime.now(),
      duration: '2.0s',
      status: AgentStatus.complete,
      lines: [
        'Market rate: Rs. ${result.marketMin}–${result.marketMax}',
        'Provider quote: Rs. ${result.providerQuote}',
        '${result.rounds.length} negotiation rounds',
        'Outcome: ${result.outcome}',
        if (result.outcome != 'REJECTED') 'Final price: Rs. ${result.finalPrice}',
        if (result.savings > 0) 'Savings: Rs. ${result.savings} (${result.savingsPercent}%)',
      ],
    ));

    _stage = PipelineStage.idle;
    _activeAgent = null;
    notifyListeners();
  }

  Future<BookingReceipt> confirmBooking(String slot) async {
    _stage = PipelineStage.booking;
    _activeAgent = AgentId.book;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1500));

    final provider = selectedProvider!.provider;
    final intent = currentIntent!;
    final negotiation = negotiationResult!;
    final bookingId = 'KH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final receipt = BookingReceipt(
      bookingId: bookingId,
      service: intent.serviceType,
      provider: provider,
      location: intent.location,
      date: _getBookingDate(intent.time),
      time: slot,
      originalPrice: negotiation.providerQuote,
      finalPrice: negotiation.finalPrice > 0 ? negotiation.finalPrice : provider.priceMax,
      savedAmount: negotiation.savings,
      createdAt: DateTime.now(),
    );

    currentBooking = receipt;

    agentLogs.add(AgentLogEntry(
      id: _uuid.v4(),
      agent: AgentId.book,
      timestamp: DateTime.now(),
      duration: '1.5s',
      status: AgentStatus.complete,
      lines: [
        'Booking ID generated: $bookingId',
        'Provider: ${provider.name}',
        'Slot confirmed: $slot on ${receipt.date}',
        'Confirmation sent to ${provider.phone}',
        'Payment terms: Cash on completion',
      ],
    ));

    await Future.delayed(const Duration(milliseconds: 500));

    // YAAD-DAHANI agent
    _activeAgent = AgentId.yaadDahani;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1000));

    agentLogs.add(AgentLogEntry(
      id: _uuid.v4(),
      agent: AgentId.yaadDahani,
      timestamp: DateTime.now(),
      duration: '0.8s',
      status: AgentStatus.complete,
      lines: [
        'Reminder scheduled: 1 hour before appointment',
        'Follow-up: After service completion',
        'Rating prompt: 24 hours post-service',
        'Provider notified via simulated SMS',
      ],
    ));

    messages.add(ChatMessage.receipt(receipt));

    _stage = PipelineStage.complete;
    _activeAgent = null;
    notifyListeners();

    return receipt;
  }

  String _getBookingDate(String time) {
    final now = DateTime.now();
    if (time.toLowerCase().contains('kal') || time.toLowerCase().contains('tomorrow')) {
      return '${now.add(const Duration(days: 1)).day}/${now.add(const Duration(days: 1)).month}/${now.year}';
    }
    if (time.toLowerCase().contains('parson') || time.toLowerCase().contains('day after')) {
      return '${now.add(const Duration(days: 2)).day}/${now.add(const Duration(days: 2)).month}/${now.year}';
    }
    return '${now.day}/${now.month}/${now.year}';
  }

  void reset() {
    messages.clear();
    agentLogs.clear();
    currentIntent = null;
    rankedProviders = null;
    selectedProvider = null;
    negotiationResult = null;
    currentBooking = null;
    _stage = PipelineStage.idle;
    _activeAgent = null;
    _isProcessing = false;
    addWelcomeMessages();
    notifyListeners();
  }
}
