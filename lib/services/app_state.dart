import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/provider_model.dart';
import '../models/agent_log.dart';
import '../models/live_booking.dart';
import '../agents/faham_agent.dart';
import '../agents/bharosa_agent.dart';
import 'backend_session.dart';
import 'khidmat_repository.dart';

enum PipelineStage {
  idle,
  parsing,
  searching,
  scoring,
  negotiating,
  booking,
  complete,
}

class AppState extends ChangeNotifier {
  final BackendSession session;
  AppState(this.session) {
    _accountId = session.user?.id;
    session.addListener(_accountChanged);
  }
  KhidmatRepository get repository => KhidmatRepository(session.client);
  final List<ChatMessage> messages = [];
  final List<AgentLogEntry> agentLogs = [];
  bool isProcessing = false;
  PipelineStage stage = PipelineStage.idle;
  AgentId? activeAgent;
  String? error;
  String? currentQuery;
  ParsedIntent? currentIntent;
  List<BharosaReport>? rankedProviders;
  BharosaReport? selectedProvider;
  NegotiationResult? negotiationResult;
  BookingReceipt? currentBooking;
  LiveBooking? liveBooking;
  String? quoteId;
  DateTime? quoteExpiresAt;
  String searchCity = 'Islamabad';
  int _generation = 0;
  String? _accountId;

  void _accountChanged() {
    if (_accountId != session.user?.id) {
      _accountId = session.user?.id;
      reset();
    }
  }

  void _log(AgentId agent, List<String> lines) {
    agentLogs.add(
      AgentLogEntry(
        id: const Uuid().v4(),
        agent: agent,
        timestamp: DateTime.now(),
        duration: 'live',
        status: AgentStatus.complete,
        lines: lines,
      ),
    );
  }

  Future<void> startPipeline(String query, {String? city}) async {
    if (isProcessing || query.trim().isEmpty) return;
    reset();
    final generation = ++_generation;
    currentQuery = query.trim();
    searchCity = city?.trim().isNotEmpty == true
        ? city!.trim()
        : session.profile?['city'] as String? ?? 'Islamabad';
    if (searchCity.isEmpty) searchCity = 'Islamabad';
    isProcessing = true;
    stage = PipelineStage.parsing;
    activeAgent = AgentId.faham;
    notifyListeners();
    try {
      currentIntent = FahamAgent.parse(query);
      _log(AgentId.faham, [
        'Service: ${currentIntent!.serviceType}',
        'City selected by customer: $searchCity',
        'Local language matching',
      ]);
      stage = PipelineStage.searching;
      activeAgent = AgentId.dhoond;
      notifyListeners();
      final providers = await repository.findProviders(
        currentIntent!.serviceType,
        searchCity,
      );
      if (generation != _generation) return;
      _log(AgentId.dhoond, [
        'Queried approved, available listings in $searchCity',
        '${providers.length} matching providers',
      ]);
      stage = PipelineStage.scoring;
      activeAgent = AgentId.bharosa;
      rankedProviders = BharosaAgent.rankAll(providers);
      _log(AgentId.bharosa, [
        'Ranked by verified reviews and completed jobs',
        'New providers display without an invented reputation',
      ]);
    } catch (e) {
      if (generation != _generation) return;
      error = describeError(e);
      rankedProviders = [];
    } finally {
      if (generation == _generation) {
        isProcessing = false;
        stage = PipelineStage.idle;
        activeAgent = null;
        notifyListeners();
      }
    }
  }

  Future<void> startNegotiation(BharosaReport report) async {
    if (isProcessing) return;
    final generation = _generation;
    selectedProvider = report;
    negotiationResult = null;
    quoteId = null;
    quoteExpiresAt = null;
    error = null;
    isProcessing = true;
    stage = PipelineStage.negotiating;
    activeAgent = AgentId.molBhaav;
    notifyListeners();
    try {
      final q = await repository.getQuote(report.provider.id);
      if (generation != _generation) return;
      quoteId = q['id'] as String;
      quoteExpiresAt = DateTime.parse(q['expires_at'] as String);
      final original = (q['original_price'] as num).toInt();
      final price = (q['final_price'] as num).toInt();
      final savings = original - price;
      negotiationResult = NegotiationResult(
        providerName: report.provider.name,
        serviceType: report.provider.category,
        marketMin: report.provider.priceMin,
        marketMax: report.provider.priceMax,
        providerQuote: original,
        rounds: [
          NegotiationRound(
            round: 1,
            actor: 'provider',
            amount: price,
            action: 'quoted',
            note: 'Provider-authorized booking rate',
          ),
        ],
        finalPrice: price,
        savings: savings,
        savingsPercent: original > 0 ? (savings / original * 100).round() : 0,
        outcome: savings > 0 ? 'NEGOTIATED' : 'ACCEPTED',
        movedToNext: false,
        explanation:
            'This rate is authorized by the provider. The quote is valid for 10 minutes. '
            'Payment is cash after service. Extra work must be agreed separately.',
      );
      _log(AgentId.molBhaav, [
        'Server quote: $quoteId',
        'Provider-authorized rate: Rs. $price',
      ]);
    } catch (e) {
      if (generation == _generation) error = describeError(e);
    } finally {
      if (generation == _generation) {
        isProcessing = false;
        stage = PipelineStage.idle;
        activeAgent = null;
        notifyListeners();
      }
    }
  }

  Future<LiveBooking?> book(
    DateTime day,
    String slot,
    String address,
    String notes,
  ) async {
    if (isProcessing || quoteId == null) return null;
    final generation = _generation;
    isProcessing = true;
    stage = PipelineStage.booking;
    activeAgent = AgentId.book;
    error = null;
    notifyListeners();
    try {
      final result = await repository.createBooking(
        quoteId!,
        day,
        slot,
        address,
        notes,
      );
      if (generation != _generation) return null;
      liveBooking = result;
      _log(AgentId.book, [
        'Booking ${result.id} persisted',
        'Time slot reserved; waiting for provider acceptance',
      ]);
      stage = PipelineStage.complete;
      return result;
    } catch (e) {
      if (generation == _generation) error = describeError(e);
      return null;
    } finally {
      if (generation == _generation) {
        isProcessing = false;
        activeAgent = null;
        notifyListeners();
      }
    }
  }

  void reset() {
    _generation++;
    messages.clear();
    agentLogs.clear();
    currentQuery = null;
    currentIntent = null;
    rankedProviders = null;
    selectedProvider = null;
    negotiationResult = null;
    currentBooking = null;
    liveBooking = null;
    quoteId = null;
    quoteExpiresAt = null;
    error = null;
    stage = PipelineStage.idle;
    activeAgent = null;
    isProcessing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _generation++;
    session.removeListener(_accountChanged);
    super.dispose();
  }
}
