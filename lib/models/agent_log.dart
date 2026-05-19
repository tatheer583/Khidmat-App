enum AgentId { faham, dhoond, bharosa, molBhaav, book, yaadDahani }
enum AgentStatus { running, complete, error }

class AgentInfo {
  final AgentId id;
  final String name;
  final String urduName;
  final String description;
  final int colorValue;
  final int bgColorValue;
  final String icon;

  const AgentInfo({
    required this.id,
    required this.name,
    required this.urduName,
    required this.description,
    required this.colorValue,
    required this.bgColorValue,
    required this.icon,
  });
}

const agentRegistry = {
  AgentId.faham: AgentInfo(
    id: AgentId.faham,
    name: 'FAHAM',
    urduName: 'فہم',
    description: 'Intent Understanding & Language Analysis',
    colorValue: 0xFF3B82F6,
    bgColorValue: 0xFF0D1C35,
    icon: 'psychology',
  ),
  AgentId.dhoond: AgentInfo(
    id: AgentId.dhoond,
    name: 'DHOOND',
    urduName: 'ڈھونڈ',
    description: 'Provider Discovery & Search',
    colorValue: 0xFFF59E0B,
    bgColorValue: 0xFF2A1D00,
    icon: 'radar',
  ),
  AgentId.bharosa: AgentInfo(
    id: AgentId.bharosa,
    name: 'BHAROSA',
    urduName: 'بھروسا',
    description: 'Trust Verification & Scoring',
    colorValue: 0xFF10B981,
    bgColorValue: 0xFF052918,
    icon: 'verified_user',
  ),
  AgentId.molBhaav: AgentInfo(
    id: AgentId.molBhaav,
    name: 'MOL-BHAAV',
    urduName: 'مول بھاؤ',
    description: 'Price Negotiation Intelligence',
    colorValue: 0xFF8B5CF6,
    bgColorValue: 0xFF1A0D35,
    icon: 'handshake',
  ),
  AgentId.book: AgentInfo(
    id: AgentId.book,
    name: 'BOOK',
    urduName: 'بُک',
    description: 'Booking Confirmation & Execution',
    colorValue: 0xFF14B8A6,
    bgColorValue: 0xFF042520,
    icon: 'event_available',
  ),
  AgentId.yaadDahani: AgentInfo(
    id: AgentId.yaadDahani,
    name: 'YAAD-DAHANI',
    urduName: 'یاد دہانی',
    description: 'Reminders & Follow-up Automation',
    colorValue: 0xFFF97316,
    bgColorValue: 0xFF2A1000,
    icon: 'notifications_active',
  ),
};

class AgentLogEntry {
  final String id;
  final AgentId agent;
  final DateTime timestamp;
  final String duration;
  final AgentStatus status;
  final List<String> lines;

  const AgentLogEntry({
    required this.id,
    required this.agent,
    required this.timestamp,
    required this.duration,
    required this.status,
    required this.lines,
  });
}

class NegotiationRound {
  final int round;
  final String actor;
  final int amount;
  final String action;
  final String? note;

  const NegotiationRound({
    required this.round,
    required this.actor,
    required this.amount,
    required this.action,
    this.note,
  });
}

class NegotiationResult {
  final String providerName;
  final String serviceType;
  final int marketMin;
  final int marketMax;
  final int providerQuote;
  final List<NegotiationRound> rounds;
  final int finalPrice;
  final int savings;
  final int savingsPercent;
  final String outcome;
  final bool movedToNext;
  final String explanation;

  const NegotiationResult({
    required this.providerName,
    required this.serviceType,
    required this.marketMin,
    required this.marketMax,
    required this.providerQuote,
    required this.rounds,
    required this.finalPrice,
    required this.savings,
    required this.savingsPercent,
    required this.outcome,
    required this.movedToNext,
    required this.explanation,
  });
}
