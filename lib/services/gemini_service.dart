import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/chat_message.dart';

class GeminiService {
  static GeminiService? _instance;
  GenerativeModel? _model;
  ChatSession? _chat;
  bool _initialized = false;
  String _lastApiKey = '';

  GeminiService._();
  static GeminiService get instance => _instance ??= GeminiService._();

  void initialize(String apiKey) {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) return;
    if (trimmed == _lastApiKey && _initialized) return;
    _lastApiKey = trimmed;
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: trimmed,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 600,
        topP: 0.92,
      ),
      systemInstruction: Content.system(_systemPrompt),
    );
    _chat = _model!.startChat();
    _initialized = true;
  }

  bool get isInitialized => _initialized;

  static const String _systemPrompt = '''
You are KHIDMAT AI — a warm, smart, and genuinely helpful service-booking assistant for Pakistan.

KHIDMAT helps users find and book trusted local home service workers: plumbers (nalkay wala), electricians (bijli wala), AC technicians, carpenters (barhai), painters, tutors, beauticians, house cleaners, drivers, cooks, gardeners, and handymen.

YOUR PERSONALITY:
- Warm, friendly, and efficient — like a trusted friend who happens to know every skilled worker in the city
- You speak naturally in whatever language the user uses: Urdu, Roman Urdu, English, or a natural mix
- Keep replies SHORT (2-4 sentences max) and conversational — never lecture
- Be proactive: if someone says they have a problem, immediately offer to find help

CONVERSATION FLOW:
1. If user needs a service → Ask ONE clarifying question if needed (area/location), then confirm you're finding providers
2. If user confirms or gives location → Say "Perfect! Let me find the best [service] providers near [location] right now."
3. If user asks about pricing → Give realistic Pakistan market rates (e.g., "Plumber: Rs 500-1500 for basic visit, AC service: Rs 1000-3000")
4. If user asks about safety/trust → Mention KHIDMAT verifies all providers with ID checks and ratings
5. If user just chats → Respond naturally and gently guide toward their service need

REALISTIC PAKISTAN PRICING (approximate):
- Plumber: Rs 500-2000
- Electrician: Rs 800-2500
- AC Service/Repair: Rs 1500-5000
- Carpenter: Rs 1000-5000
- House Cleaner: Rs 1500-3000 (per day)
- Tutor: Rs 3000-8000/month
- Beautician (home): Rs 1500-5000
- Painter: Rs 80-120 per sq ft

STRICT RULES:
- NEVER make up specific provider names, phone numbers, or guaranteed prices — the app handles real matching
- NEVER say you "can't help" or "don't have that capability" for home services
- NEVER give medical, legal, or financial advice beyond basic service info
- NEVER use more than 2 emojis per message
- NEVER write long bullet lists — keep it conversational
- If asked something unrelated to services or KHIDMAT, politely steer back

EXAMPLE RESPONSES:
User: "AC theek nahi ho raha" → "Oh, AC mein masla? Technician bhej deta hun! Aap kahan hain — city aur area batayein?"
User: "I need a plumber in Karachi" → "Got it! Plumber in Karachi — which area? (DHA, Clifton, Gulshan, etc.)"
User: "Kitna charge hoga?" → "Plumber ka basic visit Rs 500-1500 hota hai, issue ke hisaab se. Exact quote provider dega aane ke baad."
User: "Hello" → "Assalamu Alaikum! Koi service chahiye? Plumber, electrician, AC technician — batayein, main abhi dhundh deta hun!"
''';

  Future<String> generateResponse(String userMessage, {List<ChatMessage>? history}) async {
    if (!_initialized || _chat == null || _model == null) {
      return _fallbackResponse(userMessage);
    }
    try {
      final response = await _chat!.sendMessage(Content.text(userMessage));
      final text = response.text?.trim();
      if (text == null || text.isEmpty) return _fallbackResponse(userMessage);
      return text;
    } on GenerativeAIException catch (e) {
      if (e.message.contains('quota') || e.message.contains('rate')) {
        return 'Thoda wait karein, bahut requests aa rahi hain. Dobara try karein please!';
      }
      return _fallbackResponse(userMessage);
    } catch (_) {
      return _fallbackResponse(userMessage);
    }
  }

  void resetConversation() {
    if (_model != null) _chat = _model!.startChat();
  }

  String _fallbackResponse(String input) {
    final l = input.toLowerCase();
    if (l.contains('ac') || l.contains('cooling') || l.contains('thanda') || l.contains('aaee')) {
      return 'AC ka masla? Seedha samajh gaya! Aap ka area batayein — technician abhi bhejta hun. 👍';
    }
    if (l.contains('plumb') || l.contains('nalkay') || l.contains('pipe') || l.contains('leak') || l.contains('toti')) {
      return 'Nalkay ya pipe ka issue? Experienced plumber arrange karta hun. Kahan hain aap?';
    }
    if (l.contains('bijli') || l.contains('electric') || l.contains('wiring') || l.contains('socket')) {
      return 'Bijli ka masla serious hota hai — electrician turant bhejta hun. Area batayein?';
    }
    if (l.contains('tutor') || l.contains('teacher') || l.contains('padhna') || l.contains('class')) {
      return 'Tutor chahiye? Subject aur class (grade) batayein — best match dhundh deta hun!';
    }
    if (l.contains('clean') || l.contains('safai') || l.contains('maid') || l.contains('cook')) {
      return 'Ghar ki safai ya cook? Verified helpers available hain. Area aur waqt batayein?';
    }
    if (l.contains('salam') || l.contains('hello') || l.contains('hi') || l.contains('assalam')) {
      return 'Wa Alaikum Assalam! KHIDMAT mein khush aamdeed. Kaunsi service chahiye — plumber, electrician, AC, tutor?';
    }
    if (l.contains('price') || l.contains('rate') || l.contains('kitna') || l.contains('cost')) {
      return 'Service ke hisaab se rate alag hote hain. Batayein kaunsi service chahiye — accurate rate bata sakta hun!';
    }
    return 'Assalamu Alaikum! Main KHIDMAT AI hun. Plumber, electrician, AC technician, tutor — jo chahiye batayein, abhi arrange karta hun!';
  }
}
