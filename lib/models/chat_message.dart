import 'provider_model.dart';

enum MessageType { user, agent, intentCard, receipt, system }
enum UrgencyLevel { high, medium, low }

class ParsedIntent {
  final String serviceType;
  final String location;
  final String time;
  final UrgencyLevel urgency;
  final int? budget;
  final String specialNotes;
  final String detectedLanguage;

  const ParsedIntent({
    required this.serviceType,
    required this.location,
    required this.time,
    required this.urgency,
    this.budget,
    this.specialNotes = '',
    this.detectedLanguage = 'English',
  });
}

class ChatMessage {
  final String id;
  final MessageType type;
  final String? text;
  final DateTime timestamp;
  final ParsedIntent? intent;
  final BookingReceipt? receipt;
  final bool isTyping;

  const ChatMessage({
    required this.id,
    required this.type,
    this.text,
    required this.timestamp,
    this.intent,
    this.receipt,
    this.isTyping = false,
  });

  factory ChatMessage.user(String text) => ChatMessage(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    type: MessageType.user,
    text: text,
    timestamp: DateTime.now(),
  );

  factory ChatMessage.agent(String text) => ChatMessage(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    type: MessageType.agent,
    text: text,
    timestamp: DateTime.now(),
  );

  factory ChatMessage.typing() => ChatMessage(
    id: 'typing',
    type: MessageType.agent,
    isTyping: true,
    timestamp: DateTime.now(),
  );

  factory ChatMessage.intentCard(ParsedIntent intent) => ChatMessage(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    type: MessageType.intentCard,
    intent: intent,
    timestamp: DateTime.now(),
  );

  factory ChatMessage.receipt(BookingReceipt receipt) => ChatMessage(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    type: MessageType.receipt,
    receipt: receipt,
    timestamp: DateTime.now(),
  );

  factory ChatMessage.system(String text) => ChatMessage(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    type: MessageType.system,
    text: text,
    timestamp: DateTime.now(),
  );
}
