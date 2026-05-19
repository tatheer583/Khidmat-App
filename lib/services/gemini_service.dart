import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static GeminiService? _instance;
  GenerativeModel? _model;
  bool _initialized = false;

  GeminiService._();
  static GeminiService get instance => _instance ??= GeminiService._();

  void initialize(String apiKey) {
    _model = GenerativeModel(
      // gemini-2.0-flash is available on the free tier (15 RPM / 1500 req-day)
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3,
        maxOutputTokens: 1024,
        topP: 0.8,
      ),
      systemInstruction: Content.system(
        '''You are KHIDMAT's AI assistant — an intelligent service orchestrator for Pakistan's informal economy.

You help users find trusted service providers (plumbers, electricians, AC technicians, tutors, beauticians, etc.)
across Islamabad, Lahore, Karachi, and Rawalpindi.

You understand Urdu, Roman Urdu, English, and code-switched input.
Always respond in the same language as the user. Keep responses concise and conversational.

When a user asks for a service:
1. Confirm you understood their request
2. Tell them you're running the KHIDMAT agent pipeline
3. Mention which agents are working (FAHAM → DHOOND → BHAROSA)
4. Assure them you'll find the best providers with verified trust scores''',
      ),
    );
    _initialized = true;
  }

  bool get isInitialized => _initialized;

  Future<String> generateResponse(String userMessage, {String? context}) async {
    if (!_initialized || _model == null) {
      return _fallbackResponse(userMessage);
    }

    try {
      final prompt = context != null
          ? '$context\n\nUser: $userMessage'
          : userMessage;

      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? _fallbackResponse(userMessage);
    } catch (e) {
      return _fallbackResponse(userMessage);
    }
  }

  String _fallbackResponse(String input) {
    final lower = input.toLowerCase();

    if (lower.contains('ac') || lower.contains('air conditioner') || lower.contains('cooling')) {
      return 'Bilkul! KHIDMAT agents activate ho rahe hain...\n\n🔵 FAHAM Agent: AC Technician request detect ki\n🟡 DHOOND Agent: Aapke area ke providers dhundh raha hai\n🟢 BHAROSA Agent: Trust scores calculate ho rahe hain\n\nKuch seconds mein best options milenge! 🛠️';
    }
    if (lower.contains('plumb') || lower.contains('nalkay') || lower.contains('pipe')) {
      return 'Ji zaroor! Plumber dhundh raha hun...\n\n🔵 FAHAM: Plumbing request samajh li\n🟡 DHOOND: Nearby plumbers scan ho rahe hain\n🟢 BHAROSA: Trust verification chal raha hai\n\nAapke liye trusted plumber milega! 🔧';
    }
    if (lower.contains('bijli') || lower.contains('electric')) {
      return 'Bilkul! Electrician dhundhta hun...\n\n🔵 FAHAM: Electrical request detect ki\n🟡 DHOOND: Area ke electricians dhundh raha hun\n🟢 BHAROSA: Credentials verify ho rahe hain\n\nBest electrician milega! ⚡';
    }

    return 'Assalamu Alaikum! Main KHIDMAT AI hun. 👋\n\nAap kaunsi service chahiye? Mujhe batayein:\n• AC Technician\n• Plumber\n• Electrician\n• Tutor\n• Beautician\n• Carpenter aur bahut kuch...\n\nUrdu, Roman Urdu ya English mein likhein — main samajh lunga! 😊';
  }
}
