/// Shared marketplace values. Public worker records never contain coordinates.
library;

String normalizePakistaniPhone(String input) {
  var value = input.trim();
  if (!RegExp(r'^[+0-9\s()\-]+$').hasMatch(value)) {
    throw const FormatException('Enter a Pakistani mobile number, such as 03001234567.');
  }
  value = value.replaceAll(RegExp(r'[\s()\-]'), '');
  if (value.startsWith('0092')) value = '+92${value.substring(4)}';
  if (RegExp(r'^03\d{9}$').hasMatch(value)) value = '+92${value.substring(1)}';
  if (RegExp(r'^923\d{9}$').hasMatch(value)) value = '+$value';
  if (!RegExp(r'^\+923\d{9}$').hasMatch(value)) {
    throw const FormatException('Enter a valid Pakistani mobile number.');
  }
  return value;
}

bool isPakistaniPhone(String input) {
  try {
    normalizePakistaniPhone(input);
    return true;
  } on FormatException {
    return false;
  }
}

String _string(dynamic value, [String fallback = '']) => value is String ? value : fallback;
double _double(dynamic value, [double fallback = 0]) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? fallback;
int _int(dynamic value, [int fallback = 0]) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;
DateTime? _date(dynamic value) => value is String ? DateTime.tryParse(value)?.toUtc() : null;
List<String> _strings(dynamic value) => value is List ? value.whereType<String>().toList() : [];
Map<String, dynamic> _map(dynamic value) => value is Map ? Map<String, dynamic>.from(value) : {};

enum WorkerAvailability {
  availableNow('available_now', 'Available now'),
  availableLater('available_later', 'Available later'),
  busy('busy', 'Busy'),
  offline('offline', 'Offline'),
  unknown('unknown', 'Availability unknown');

  const WorkerAvailability(this.value, this.label);
  final String value;
  final String label;

  static WorkerAvailability parse(dynamic value) => values.firstWhere(
    (state) => state.value == value,
    orElse: () => unknown,
  );

  WorkerAvailability fresh({DateTime? updatedAt, DateTime? locationUpdatedAt, DateTime? now}) {
    final current = (now ?? DateTime.now()).toUtc();
    bool recent(DateTime? date, Duration age) => date != null &&
        !date.isAfter(current.add(const Duration(minutes: 5))) &&
        current.difference(date) <= age;
    if (this == availableNow &&
        (!recent(updatedAt, const Duration(minutes: 30)) ||
         !recent(locationUpdatedAt, const Duration(minutes: 30)))) {
      return unknown;
    }
    if ((this == availableLater || this == busy) &&
        !recent(updatedAt, const Duration(hours: 24))) {
      return unknown;
    }
    return this;
  }
}

class ProfessionSkill {
  const ProfessionSkill({required this.id, required this.name});
  final String id, name;
}

class ProfessionQuestion {
  const ProfessionQuestion({required this.id, required this.label,
    this.type = 'text', this.required = false, this.options = const []});
  final String id, label, type;
  final bool required;
  final List<String> options;
  String get key => id;

  factory ProfessionQuestion.fromJson(Map<String, dynamic> json) => ProfessionQuestion(
    id: _string(json['key'] ?? json['id']), label: _string(json['label']),
    type: _string(json['type'], 'text'), required: json['required'] == true,
    options: _strings(json['options']),
  );

  void validate(dynamic answer) {
    final empty = answer == null || answer == '' || (answer is List && answer.isEmpty);
    if (required && empty) throw FormatException('Please answer: $label.');
    if (empty) return;
    if (type == 'boolean' || type == 'bool') {
      if (answer is! bool) throw FormatException('Choose yes or no for $label.');
    } else if (type == 'multiselect' || type == 'multi_select') {
      if (answer is! List || answer.any((item) => item is! String || !options.contains(item))) {
        throw FormatException('Choose valid options for $label.');
      }
    } else if (type == 'select') {
      if (answer is! String || !options.contains(answer)) {
        throw FormatException('Choose an option for $label.');
      }
    } else if (type == 'number') {
      final number = answer is num ? answer : num.tryParse('$answer');
      if (number == null || !number.isFinite || number < 0 || number > 1000000) {
        throw FormatException('Enter a valid number for $label.');
      }
    } else if (answer is! String || answer.length > 1000) {
      throw FormatException('Enter an answer under 1000 characters for $label.');
    }
  }
}

class Profession {
  const Profession({required this.id, required this.category, required this.name,
    this.nameUr = '', this.skills = const [], this.questions = const []});
  final String id, category, name, nameUr;
  final List<ProfessionSkill> skills;
  final List<ProfessionQuestion> questions;

  factory Profession.fromJson(Map<String, dynamic> json) => Profession(
    id: _string(json['id']), category: _string(json['category']),
    name: _string(json['name']), nameUr: _string(json['name_ur']),
    skills: (json['skills'] is List ? json['skills'] as List : []).map((value) {
      if (value is String) return ProfessionSkill(id: value, name: value);
      final row = _map(value);
      return ProfessionSkill(id: _string(row['id'] ?? row['name']), name: _string(row['name']));
    }).toList(),
    questions: (json['questions'] is List ? json['questions'] as List : [])
        .whereType<Map>().map((row) => ProfessionQuestion.fromJson(_map(row))).toList(),
  );
}

class MarketplaceProfile {
  const MarketplaceProfile({required this.id, this.fullName = '', this.phone = '',
    this.city = '', this.neighbourhood = '', this.roles = const ['customer'],
    this.status = 'active', this.avatarUrl, this.whatsapp = ''});
  final String id, fullName, phone, city, neighbourhood, status, whatsapp;
  final List<String> roles;
  final String? avatarUrl;
  bool get isActive => status == 'active';
  bool get isWorker => roles.contains('worker');
  bool get isCustomer => roles.contains('customer');
  bool get needsOnboarding => fullName.trim().length < 2 || city.trim().length < 2;

  factory MarketplaceProfile.fromJson(Map<String, dynamic> json) => MarketplaceProfile(
    id: _string(json['id']), fullName: _string(json['full_name']), phone: _string(json['phone']),
    city: _string(json['city']), neighbourhood: _string(json['neighbourhood']),
    roles: _strings(json['roles']), status: _string(json['status'], 'unknown'),
    avatarUrl: json['avatar_url'] as String?, whatsapp: _string(json['whatsapp']),
  );
}

class SearchLocation {
  const SearchLocation({this.latitude, this.longitude, this.city = '',
    this.neighbourhood = '', this.isDevice = false});
  final double? latitude, longitude;
  final String city, neighbourhood;
  final bool isDevice;
  bool get hasCoordinates => latitude != null && longitude != null;
  String get label => isDevice ? 'Current location' :
      [neighbourhood, city].where((part) => part.isNotEmpty).join(', ');

  void validate() {
    if ((latitude == null) != (longitude == null) ||
        (latitude != null && (!latitude!.isFinite || latitude! < -90 || latitude! > 90)) ||
        (longitude != null && (!longitude!.isFinite || longitude! < -180 || longitude! > 180))) {
      throw const FormatException('Choose a valid search location.');
    }
    if (!hasCoordinates && city.trim().length < 2) {
      throw const FormatException('Choose your city or use device location.');
    }
    if (city.length > 80 || neighbourhood.length > 120) {
      throw const FormatException('Your location name is too long.');
    }
  }
}

class WorkerSearch {
  const WorkerSearch({this.query = '', this.professionId, this.skillId, this.radiusKm = 15,
    this.minPrice, this.maxPrice, this.minRating = 0, this.minExperience = 0,
    this.availableOnly = false, this.sort = 'distance'});
  final String query, sort;
  final String? professionId, skillId;
  final double radiusKm, minRating;
  final double? minPrice, maxPrice;
  final int minExperience;
  final bool availableOnly;

  WorkerSearch copyWith({String? query, String? professionId, String? skillId,
    double? radiusKm, double? minPrice, double? maxPrice, double? minRating,
    int? minExperience, bool? availableOnly, String? sort, bool clearProfession = false,
    bool clearSkill = false, bool clearPrice = false}) => WorkerSearch(
      query: query ?? this.query, professionId: clearProfession ? null : professionId ?? this.professionId,
      skillId: clearSkill || clearProfession ? null : skillId ?? this.skillId,
      radiusKm: radiusKm ?? this.radiusKm,
      minPrice: clearPrice ? null : minPrice ?? this.minPrice,
      maxPrice: clearPrice ? null : maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating, minExperience: minExperience ?? this.minExperience,
      availableOnly: availableOnly ?? this.availableOnly, sort: sort ?? this.sort,
    );

  void validate() {
    if (query.length > 120 || !radiusKm.isFinite || radiusKm < 1 || radiusKm > 100) {
      throw const FormatException('Use a search under 120 characters and a radius from 1 to 100 km.');
    }
    if ((minPrice != null && (!minPrice!.isFinite || minPrice! < 0 || minPrice! > 10000000)) ||
        (maxPrice != null && (!maxPrice!.isFinite || maxPrice! < 0 || maxPrice! > 10000000)) ||
        (minPrice != null && maxPrice != null && minPrice! > maxPrice!)) {
      throw const FormatException('Enter a valid minimum and maximum price.');
    }
    if (!minRating.isFinite || minRating < 0 || minRating > 5 || minExperience < 0 || minExperience > 60) {
      throw const FormatException('Choose a rating from 0 to 5 and experience from 0 to 60 years.');
    }
    if (!['distance', 'rating', 'price', 'experience', 'relevance'].contains(sort)) {
      throw const FormatException('Choose a valid sorting option.');
    }
  }

  Map<String, dynamic> toRpc(SearchLocation location, {int offset = 0, int limit = 20}) {
    validate(); location.validate();
    if (offset < 0 || offset > 10000 || limit < 1 || limit > 100) {
      throw const FormatException('Choose a valid result page.');
    }
    return {'p_query': query.trim(), 'p_profession_id': professionId, 'p_skill': skillId,
      'p_latitude': location.latitude, 'p_longitude': location.longitude,
      'p_city': location.hasCoordinates ? null : location.city.trim(),
      'p_radius_km': radiusKm, 'p_min_price': minPrice, 'p_max_price': maxPrice,
      'p_min_experience': minExperience, 'p_min_rating': minRating,
      'p_available_only': availableOnly, 'p_sort': sort, 'p_offset': offset, 'p_limit': limit};
  }
}

class WorkerReview {
  const WorkerReview({required this.rating, this.comment = '', this.createdAt});
  final int rating;
  final String comment;
  final DateTime? createdAt;
  factory WorkerReview.fromJson(Map<String, dynamic> json) => WorkerReview(
    rating: _int(json['rating']), comment: _string(json['comment']), createdAt: _date(json['created_at']));
}

class MarketplaceWorker {
  const MarketplaceWorker({required this.id, required this.name, this.city = '',
    this.neighbourhood = '', this.avatarUrl, this.professionId = '', this.professionName = '',
    this.skills = const [], this.experienceYears = 0, this.description = '',
    this.languages = const [], this.rate = 0, this.priceUnit = 'day', this.serviceRadiusKm = 15,
    this.availability = WorkerAvailability.unknown, this.availabilityUpdatedAt,
    this.locationUpdatedAt, this.rating = 0, this.reviewCount = 0, this.distanceKm,
    this.portfolioUrls = const [], this.published = false, this.shareContact = false,
    this.workingDays = const [], this.startTime = '', this.endTime = '',
    this.answers = const {}, this.reviews = const []});
  final String id, name, city, neighbourhood, professionId, professionName, description, priceUnit, startTime, endTime;
  final String? avatarUrl;
  final List<String> skills, languages, portfolioUrls;
  final List<int> workingDays;
  final int experienceYears, reviewCount;
  final double rate, serviceRadiusKm, rating;
  final double? distanceKm;
  final WorkerAvailability availability;
  final DateTime? availabilityUpdatedAt, locationUpdatedAt;
  final bool published, shareContact;
  final Map<String, dynamic> answers;
  final List<WorkerReview> reviews;
  String get fullName => name;
  WorkerAvailability get currentAvailability => availability.fresh(
      updatedAt: availabilityUpdatedAt, locationUpdatedAt: locationUpdatedAt);
  String get serviceArea => [neighbourhood, city].where((part) => part.isNotEmpty).join(', ');

  factory MarketplaceWorker.fromJson(Map<String, dynamic> json) {
    final distance = json['distance_km'] == null ? null : _double(json['distance_km']);
    return MarketplaceWorker(
      id: _string(json['id']), name: _string(json['full_name'] ?? json['name']),
      city: _string(json['city']), neighbourhood: _string(json['neighbourhood']),
      avatarUrl: json['avatar_url'] as String?, professionId: _string(json['profession_id']),
      professionName: _string(json['profession_name']), skills: _strings(json['skills']),
      experienceYears: _int(json['experience_years']), description: _string(json['description']),
      languages: _strings(json['languages']), rate: _double(json['rate']),
      priceUnit: _string(json['price_unit'], 'day'), serviceRadiusKm: _double(json['service_radius_km'], 15),
      availability: WorkerAvailability.parse(json['availability']),
      availabilityUpdatedAt: _date(json['availability_updated_at']), locationUpdatedAt: _date(json['location_updated_at']),
      rating: _double(json['rating']), reviewCount: _int(json['review_count']),
      distanceKm: distance != null && distance.isFinite && distance >= 0 ? distance : null,
      portfolioUrls: _strings(json['portfolio_urls']), published: json['published'] == true,
      shareContact: json['share_contact'] == true,
      workingDays: (json['working_days'] is List ? json['working_days'] as List : []).whereType<num>().map((n) => n.toInt()).toList(),
      startTime: _string(json['start_time']), endTime: _string(json['end_time']), answers: _map(json['answers']),
      reviews: (json['reviews'] is List ? json['reviews'] as List : []).whereType<Map>().map((r) => WorkerReview.fromJson(_map(r))).toList(),
    );
  }
}

class WorkerDraft {
  const WorkerDraft({required this.professionId, this.skillIds = const [], this.experienceYears = 0,
    this.description = '', this.languages = const [], this.serviceRadiusKm = 15, this.rate = 0,
    this.rateUnit = 'day', this.workingDays = const [1, 2, 3, 4, 5, 6], this.startTime = '08:00',
    this.endTime = '18:00', this.answers = const {}, this.avatarPath, this.portfolioPaths = const [],
    this.published = false, this.shareContact = false});
  final String professionId, description, rateUnit, startTime, endTime;
  final List<String> skillIds, languages, portfolioPaths;
  final List<int> workingDays;
  final int experienceYears;
  final double serviceRadiusKm, rate;
  final Map<String, dynamic> answers;
  final String? avatarPath;
  final bool published, shareContact;
  String get priceUnit => rateUnit;

  factory WorkerDraft.fromWorker(MarketplaceWorker worker) => WorkerDraft(
    professionId: worker.professionId, skillIds: worker.skills, experienceYears: worker.experienceYears,
    description: worker.description, languages: worker.languages, serviceRadiusKm: worker.serviceRadiusKm,
    rate: worker.rate, rateUnit: worker.priceUnit, workingDays: worker.workingDays,
    startTime: worker.startTime.isEmpty ? '08:00' : worker.startTime,
    endTime: worker.endTime.isEmpty ? '18:00' : worker.endTime,
    answers: worker.answers, avatarPath: worker.avatarUrl, portfolioPaths: worker.portfolioUrls,
    published: worker.published, shareContact: worker.shareContact,
  );

  void validate(Profession profession) {
    if (professionId != profession.id || skillIds.any((id) => !profession.skills.any((skill) => skill.id == id))) {
      throw const FormatException('Choose a valid profession and skills.');
    }
    if (experienceYears < 0 || experienceYears > 60 || description.length > 2000 ||
        !serviceRadiusKm.isFinite || serviceRadiusKm < 1 || serviceRadiusKm > 100 ||
        !rate.isFinite || rate < 0 || rate > 10000000 || !['hour', 'day', 'job'].contains(rateUnit)) {
      throw const FormatException('Check your experience, service radius, description and price.');
    }
    final time = RegExp(r'^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$');
    if (!time.hasMatch(startTime) || !time.hasMatch(endTime) || startTime.compareTo(endTime) >= 0 ||
        workingDays.any((day) => day < 1 || day > 7) || workingDays.toSet().length != workingDays.length) {
      throw const FormatException('Choose valid working days and opening hours.');
    }
    if (languages.length > 10 || languages.any((language) => language.isEmpty || language.length > 50) || portfolioPaths.length > 10) {
      throw const FormatException('Choose up to 10 languages and portfolio images.');
    }
    if (published && (description.trim().length < 20 || skillIds.isEmpty || workingDays.isEmpty || rate <= 0)) {
      throw const FormatException('Add a description of at least 20 characters, skills, working days and price before publishing.');
    }
    if (published) {
      for (final question in profession.questions) { question.validate(answers[question.id]); }
    }
    if (answers.keys.any((key) => !profession.questions.any((q) => q.id == key))) {
      throw const FormatException('Remove answers belonging to another profession.');
    }
  }

  Map<String, dynamic> toJson() => {'profession_id': professionId, 'skills': skillIds,
    'experience_years': experienceYears, 'description': description.trim(), 'languages': languages,
    'service_radius_km': serviceRadiusKm, 'rate': rate, 'price_unit': rateUnit,
    'working_days': workingDays, 'start_time': startTime, 'end_time': endTime, 'answers': answers,
    'avatar_url': avatarPath, 'portfolio_urls': portfolioPaths, 'published': published, 'share_contact': shareContact};
}

class MarketplaceJob {
  const MarketplaceJob({required this.id, required this.customerId, required this.workerId,
    this.professionId = '', this.description = '', required this.scheduledAt, this.city = '',
    this.neighbourhood = '', this.address = '', this.offeredPrice, this.status = 'pending',
    this.createdAt, this.customerName = '', this.workerName = '', this.reviewed = false});
  final String id, customerId, workerId, professionId, description, city, neighbourhood, address, status, customerName, workerName;
  final DateTime scheduledAt;
  final DateTime? createdAt;
  final double? offeredPrice;
  final bool reviewed;
  bool canReview(String? userId) => userId == customerId && status == 'completed' && !reviewed;
  List<String> allowedTransitions(String? userId) {
    final customer = userId != null && userId == customerId;
    final worker = userId != null && userId == workerId;
    if (!customer && !worker) return [];
    switch (status) {
      case 'pending': return [if (worker) 'accepted', if (worker) 'declined', if (customer) 'cancelled'];
      case 'accepted': return [if (worker) 'in_progress', 'cancelled'];
      case 'in_progress': return [if (worker) 'completion_requested', 'cancelled'];
      case 'completion_requested': return [if (customer) 'completed', 'in_progress'];
      default: return [];
    }
  }

  factory MarketplaceJob.fromJson(Map<String, dynamic> json) => MarketplaceJob(
    id: _string(json['id']), customerId: _string(json['customer_id']), workerId: _string(json['worker_id']),
    professionId: _string(json['profession_id']), description: _string(json['description']),
    scheduledAt: _date(json['scheduled_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    city: _string(json['city']), neighbourhood: _string(json['neighbourhood']), address: _string(json['address']),
    offeredPrice: json['offered_price'] == null ? null : _double(json['offered_price']),
    status: _string(json['status'], 'unknown'), createdAt: _date(json['created_at']),
    customerName: _string(json['customer_name']), workerName: _string(json['worker_name']), reviewed: json['reviewed'] == true,
  );
}

class WorkerContactDetails {
  const WorkerContactDetails({required this.phone, this.whatsapp = ''});
  final String phone, whatsapp;
  factory WorkerContactDetails.fromJson(Map<String, dynamic> json) => WorkerContactDetails(
    phone: _string(json['phone']), whatsapp: _string(json['whatsapp']));
}

class MarketplaceNotification {
  const MarketplaceNotification({required this.id, required this.title, this.body = '', this.jobId,
    this.createdAt, this.readAt});
  final String id, title, body;
  final String? jobId;
  final DateTime? createdAt, readAt;
  bool get isRead => readAt != null;
  factory MarketplaceNotification.fromJson(Map<String, dynamic> json) => MarketplaceNotification(
    id: _string(json['id']), title: _string(json['title']), body: _string(json['body']),
    jobId: json['job_id'] as String?, createdAt: _date(json['created_at']), readAt: _date(json['read_at']));
}
