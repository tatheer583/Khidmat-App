import '../models/chat_message.dart';

class FahamAgent {
  static const _serviceMap = [
    {'keys': ['ac', 'air conditioner', 'cooling', 'aye si', 'split ac', 'inverter ac', 'ac theek', 'ac service', 'ac wala'], 'label': 'AC Technician'},
    {'keys': ['plumber', 'plumbing', 'nalkay', 'pipe', 'leak', 'flush', 'tap', 'nalkay wala', 'pani'], 'label': 'Plumber'},
    {'keys': ['electrician', 'bijli', 'wiring', 'electric', 'switch', 'socket', 'bijli wala', 'bijli ka masla', 'light'], 'label': 'Electrician'},
    {'keys': ['tutor', 'teacher', 'tuition', 'padhai', 'study', 'math', 'science', 'padhao', 'parhao'], 'label': 'Tutor'},
    {'keys': ['beautician', 'parlor', 'parlour', 'makeup', 'beauty', 'facial', 'mehndi', 'waxing', 'threading'], 'label': 'Beautician'},
    {'keys': ['carpenter', 'mistri', 'lakdi', 'wood', 'furniture', 'door', 'almari', 'wardrobe', 'lakri'], 'label': 'Carpenter'},
    {'keys': ['painter', 'paint', 'rang', 'color', 'wall paint', 'rangai', 'distemper'], 'label': 'Painter'},
    {'keys': ['cleaning', 'safai', 'deep clean', 'house cleaning', 'safai wala', 'safai wali', 'ghar ki safai'], 'label': 'Deep Cleaning'},
  ];

  static const _locationMap = [
    {'keys': ['g-13', 'g13', 'g 13'], 'label': 'G-13, Islamabad'},
    {'keys': ['g-11', 'g11', 'g 11'], 'label': 'G-11, Islamabad'},
    {'keys': ['g-14', 'g14', 'g 14'], 'label': 'G-14, Islamabad'},
    {'keys': ['g-9', 'g9', 'g 9'], 'label': 'G-9, Islamabad'},
    {'keys': ['g-10', 'g10', 'g 10'], 'label': 'G-10, Islamabad'},
    {'keys': ['f-10', 'f10', 'f 10'], 'label': 'F-10, Islamabad'},
    {'keys': ['f-8', 'f8', 'f 8'], 'label': 'F-8, Islamabad'},
    {'keys': ['f-11', 'f11', 'f 11'], 'label': 'F-11, Islamabad'},
    {'keys': ['f-7', 'f7', 'f 7'], 'label': 'F-7, Islamabad'},
    {'keys': ['i-8', 'i8', 'i 8'], 'label': 'I-8, Islamabad'},
    {'keys': ['i-10', 'i10', 'i 10'], 'label': 'I-10, Islamabad'},
    {'keys': ['dha', 'dha phase'], 'label': 'DHA, Lahore'},
    {'keys': ['gulberg', 'gulburg'], 'label': 'Gulberg III, Lahore'},
    {'keys': ['bahria', 'bahria town'], 'label': 'Bahria Town, Islamabad'},
    {'keys': ['blue area'], 'label': 'Blue Area, Islamabad'},
    {'keys': ['islamabad'], 'label': 'Islamabad'},
    {'keys': ['lahore'], 'label': 'Lahore'},
    {'keys': ['karachi'], 'label': 'Karachi'},
    {'keys': ['rawalpindi', 'pindi'], 'label': 'Rawalpindi'},
  ];

  static const _timeMap = [
    {'keys': ['abhi', 'now', 'turant', 'foran', 'فوری'], 'label': 'Abhi (Right Now)'},
    {'keys': ['aaj', 'today', 'aj'], 'label': 'Aaj (Today)'},
    {'keys': ['kal', 'tomorrow'], 'label': 'Kal (Tomorrow)'},
    {'keys': ['parson', 'day after'], 'label': 'Parson (Day After)'},
    {'keys': ['subah', 'morning'], 'label': 'Subah (Morning 9–12)'},
    {'keys': ['dopahar', 'afternoon'], 'label': 'Dopahar (Afternoon 12–3)'},
    {'keys': ['sham', 'evening'], 'label': 'Sham (Evening 4–7)'},
    {'keys': ['weekend', 'saturday', 'sunday', 'chutti'], 'label': 'Weekend'},
    {'keys': ['next week', 'aglay hafta', 'agle hafte'], 'label': 'Aglay Hafta (Next Week)'},
  ];

  static const _urgencyHigh = ['urgent', 'abhi', 'jaldi', 'emergency', 'foran', 'fori', 'asap', 'turant', 'now', 'immediately'];
  static const _urgencyLow = ['kisi din', 'whenever', 'flexible', 'jab free ho', 'koi jaldi nahi', 'aglay hafta', 'next week'];

  static String? _matchFirst(String input, List<Map<String, Object>> map) {
    final lower = input.toLowerCase();
    for (final entry in map) {
      final keys = entry['keys'] as List<String>;
      for (final key in keys) {
        if (lower.contains(key)) return entry['label'] as String;
      }
    }
    return null;
  }

  static int? _extractBudget(String input) {
    final patterns = [
      RegExp(r'(?:budget|bajat|rs\.?|rupees?)\s*(\d[\d,]*)', caseSensitive: false),
      RegExp(r'(\d[\d,]*)\s*(?:rs|rupees?|rupaiye)', caseSensitive: false),
      RegExp(r'(\d+)k\b', caseSensitive: false),
      RegExp(r'\b(\d{3,5})\b'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(input);
      if (match != null) {
        String valStr = match.group(1)!.replaceAll(',', '');
        int val = int.tryParse(valStr) ?? 0;
        if (input.toLowerCase().contains('k') && val < 100) val *= 1000;
        if (val >= 100 && val <= 99999) return val;
      }
    }
    return null;
  }

  static String _extractNotes(String input) {
    final notes = <String>[];
    if (RegExp(r'female|aurat|lady|khatoon', caseSensitive: false).hasMatch(input)) {
      notes.add('Female provider requested');
    }
    if (RegExp(r'experienced|tajurbakar|tajurba', caseSensitive: false).hasMatch(input)) {
      notes.add('Experienced provider preferred');
    }
    if (RegExp(r'cheap|sasta|kam rate', caseSensitive: false).hasMatch(input)) {
      notes.add('Budget-conscious');
    }
    if (RegExp(r'warranty|guarantee', caseSensitive: false).hasMatch(input)) {
      notes.add('Warranty/guarantee needed');
    }
    return notes.join(', ');
  }

  static String _detectLanguage(String input) {
    if (RegExp(r'[؀-ۿ]').hasMatch(input)) return 'Urdu';
    final romanUrdu = RegExp(r'\b(chahiye|wala|wali|hai|mein|ka|ke|ki|bhai|yaar|karna|karwana|theek|masla|nahi|koi|abhi|kal|subah|sham|bajat)\b', caseSensitive: false);
    final english = RegExp(r'\b(need|want|require|looking|find|book|get|please|help|fix)\b', caseSensitive: false);
    final hasRoman = romanUrdu.hasMatch(input);
    final hasEng = english.hasMatch(input);
    if (hasRoman && hasEng) return 'Code-Switched';
    if (hasRoman) return 'Roman Urdu';
    return 'English';
  }

  static ParsedIntent parse(String input) {
    final lower = input.toLowerCase();

    final serviceType = _matchFirst(input, _serviceMap) ?? 'General Service';
    final location = _matchFirst(input, _locationMap) ?? 'Not specified';
    final time = _matchFirst(input, _timeMap) ?? 'Flexible';
    final budget = _extractBudget(input);
    final notes = _extractNotes(input);
    final language = _detectLanguage(input);

    UrgencyLevel urgency = UrgencyLevel.medium;
    if (_urgencyHigh.any((kw) => lower.contains(kw))) {
      urgency = UrgencyLevel.high;
    } else if (_urgencyLow.any((kw) => lower.contains(kw))) {
      urgency = UrgencyLevel.low;
    }

    return ParsedIntent(
      serviceType: serviceType,
      location: location,
      time: time,
      urgency: urgency,
      budget: budget,
      specialNotes: notes,
      detectedLanguage: language,
    );
  }
}
