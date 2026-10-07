enum AccountRole {
  customer('Work giver'),
  worker('Worker');

  const AccountRole(this.label);
  final String label;
}

enum JobStatus {
  planned('Planned'),
  confirmed('Confirmed'),
  inProgress('In progress'),
  completed('Completed'),
  cancelled('Cancelled');

  const JobStatus(this.label);
  final String label;
  bool get active => this != completed && this != cancelled;
}

const serviceCategories = [
  'Plumber',
  'Electrician',
  'AC Technician',
  'Carpenter',
  'Painter',
  'Cleaning',
  'Tutor',
  'Beautician',
  'Other',
];

String cleanPhone(String input) {
  var value = input.trim().replaceAll(RegExp(r'[\s()\-]'), '');
  if (value.startsWith('00')) value = '+${value.substring(2)}';
  if (RegExp(r'^03\d{9}$').hasMatch(value)) value = '+92${value.substring(1)}';
  return value;
}

bool validPhone(String value, {bool optional = false}) =>
    (optional && value.trim().isEmpty) ||
    RegExp(r'^\+?[0-9]{7,15}$').hasMatch(cleanPhone(value));

void _text(String value, int minimum, int maximum, String message) {
  if (value.trim().length < minimum || value.length > maximum) {
    throw FormatException(message);
  }
}

void _phone(String value, {bool optional = false}) {
  if (!validPhone(value, optional: optional)) {
    throw const FormatException('Enter a valid phone number');
  }
}

void _number(int value, int maximum, String message) {
  if (value < 0 || value > maximum) throw FormatException(message);
}

class KhidmatProfile {
  const KhidmatProfile({
    required this.name,
    required this.city,
    required this.role,
    this.phone = '',
    this.profession = 'Plumber',
    this.experienceYears = 0,
    this.details = '',
  });
  final String name, city, phone, profession, details;
  final AccountRole role;
  final int experienceYears;

  void validate() {
    _text(name, 2, 100, 'Enter your name');
    _text(city, 2, 80, 'Enter your city');
    _phone(phone, optional: true);
    _text(details, 0, 2000, 'Details are too long');
    _number(experienceYears, 60, 'Enter experience from 0 to 60 years');
    if (!serviceCategories.contains(profession)) {
      throw const FormatException('Choose a service');
    }
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'city': city,
    'role': role.name,
    'profession': profession,
    'experience_years': experienceYears,
    'details': details,
  };

  factory KhidmatProfile.fromJson(Map<String, dynamic> row) => KhidmatProfile(
    name: row['name'] as String,
    phone: row['phone'] as String,
    city: row['city'] as String,
    role: AccountRole.values.byName(row['role'] as String),
    profession: row['profession'] as String,
    experienceYears: row['experience_years'] as int,
    details: row['details'] as String,
  )..validate();
}

class WorkerContact {
  const WorkerContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.category,
    required this.city,
    this.details = '',
    this.experienceYears = 0,
    this.rate = 0,
    this.favorite = false,
  });
  final String id, name, phone, category, city, details;
  final int experienceYears, rate;
  final bool favorite;

  void validate() {
    _text(id, 1, 100, 'Invalid contact');
    _text(name, 2, 100, 'Enter the worker name');
    _text(city, 2, 80, 'Enter your city');
    _phone(phone);
    _text(details, 0, 2000, 'Details are too long');
    _number(experienceYears, 60, 'Enter experience from 0 to 60 years');
    _number(rate, 1000000, 'Enter a valid rupee amount');
    if (!serviceCategories.contains(category)) {
      throw const FormatException('Choose a service');
    }
  }

  WorkerContact withFavorite(bool value) => WorkerContact(
    id: id,
    name: name,
    phone: phone,
    category: category,
    city: city,
    details: details,
    experienceYears: experienceYears,
    rate: rate,
    favorite: value,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'category': category,
    'city': city,
    'details': details,
    'experience_years': experienceYears,
    'rate': rate,
    'favorite': favorite,
  };
  factory WorkerContact.fromJson(Map<String, dynamic> row) => WorkerContact(
    id: row['id'] as String,
    name: row['name'] as String,
    phone: row['phone'] as String,
    category: row['category'] as String,
    city: row['city'] as String,
    details: row['details'] as String,
    experienceYears: row['experience_years'] as int,
    rate: row['rate'] as int,
    favorite: row['favorite'] as bool,
  )..validate();
}

class JobRecord {
  const JobRecord({
    required this.id,
    required this.role,
    required this.service,
    required this.personName,
    required this.scheduledAt,
    required this.address,
    this.phone = '',
    this.contactId,
    this.amount = 0,
    this.notes = '',
    this.status = JobStatus.planned,
  });
  final String id, service, personName, phone, address, notes;
  final String? contactId;
  final DateTime scheduledAt;
  final AccountRole role;
  final JobStatus status;
  final int amount;

  void validate() {
    _text(id, 1, 100, 'Invalid job');
    _text(personName, 2, 100, 'Enter a name');
    _text(address, 2, 300, 'Enter the work address');
    _text(notes, 0, 2000, 'Notes are too long');
    _phone(phone, optional: true);
    _number(amount, 1000000, 'Enter a valid rupee amount');
    if (!serviceCategories.contains(service)) {
      throw const FormatException('Choose a service');
    }
    if (scheduledAt.year < 2000 || scheduledAt.year > 2100) {
      throw const FormatException('Choose a valid date');
    }
  }

  JobRecord withStatus(JobStatus value) => JobRecord(
    id: id,
    role: role,
    service: service,
    personName: personName,
    phone: phone,
    scheduledAt: scheduledAt,
    address: address,
    amount: amount,
    notes: notes,
    status: value,
    contactId: contactId,
  );

  JobRecord withoutContact() => JobRecord(
    id: id,
    role: role,
    service: service,
    personName: personName,
    phone: phone,
    scheduledAt: scheduledAt,
    address: address,
    amount: amount,
    notes: notes,
    status: status,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.name,
    'service': service,
    'person_name': personName,
    'phone': phone,
    'contact_id': contactId,
    'scheduled_at': scheduledAt.toIso8601String(),
    'address': address,
    'amount': amount,
    'notes': notes,
    'status': status.name,
  };

  factory JobRecord.fromJson(Map<String, dynamic> row) => JobRecord(
    id: row['id'] as String,
    role: AccountRole.values.byName(row['role'] as String),
    service: row['service'] as String,
    personName: row['person_name'] as String,
    phone: row['phone'] as String,
    contactId: row['contact_id'] as String?,
    scheduledAt: DateTime.parse(row['scheduled_at'] as String).toLocal(),
    address: row['address'] as String,
    amount: row['amount'] as int,
    notes: row['notes'] as String,
    status: JobStatus.values.byName(row['status'] as String),
  )..validate();
}

class LocalData {
  LocalData({
    this.profile,
    List<WorkerContact> workers = const [],
    List<JobRecord> jobs = const [],
  }) : workers = List.unmodifiable(workers),
       jobs = List.unmodifiable(jobs);
  final KhidmatProfile? profile;
  final List<WorkerContact> workers;
  final List<JobRecord> jobs;

  LocalData copyWith({
    KhidmatProfile? profile,
    List<WorkerContact>? workers,
    List<JobRecord>? jobs,
  }) => LocalData(
    profile: profile ?? this.profile,
    workers: workers ?? this.workers,
    jobs: jobs ?? this.jobs,
  );

  Map<String, dynamic> toJson() => {
    'app': 'Khidmat',
    'schema': 1,
    'profile': profile?.toJson(),
    'workers': workers.map((w) => w.toJson()).toList(),
    'jobs': jobs.map((j) => j.toJson()).toList(),
  };

  factory LocalData.fromJson(Map<String, dynamic> row) {
    if (row['app'] != 'Khidmat' || row['schema'] != 1) {
      throw const FormatException('Choose a Khidmat backup file');
    }
    final workers = (row['workers'] as List)
        .map((r) => WorkerContact.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
    final jobs = (row['jobs'] as List)
        .map((r) => JobRecord.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
    if (workers.length > 5000 ||
        jobs.length > 50000 ||
        workers.map((w) => w.id).toSet().length != workers.length ||
        jobs.map((j) => j.id).toSet().length != jobs.length) {
      throw const FormatException('This backup contains invalid records');
    }
    final workerIds = workers.map((w) => w.id).toSet();
    if (jobs.any(
      (j) => j.contactId != null && !workerIds.contains(j.contactId),
    )) {
      throw const FormatException('This backup contains invalid records');
    }
    return LocalData(
      profile: row['profile'] == null
          ? null
          : KhidmatProfile.fromJson(
              Map<String, dynamic>.from(row['profile'] as Map),
            ),
      workers: workers,
      jobs: jobs,
    );
  }
}
