class ServiceProvider {
  final String id;
  final String? ownerId;
  final int completedJobs;
  final String description;
  final int experienceYears;
  final String name;
  final String category;
  final String location;
  final double lat;
  final double lng;
  final double rating;
  final int reviewCount;
  final double completionRate;
  final int responseTimeMinutes;
  final int communityVouches;
  final int cancellationsLast7d;
  final int priceMin;
  final int priceMax;
  final List<String> availableSlots;
  final int trustScore;
  final String phone;
  final List<String> redFlags;
  final String? avatar;
  const ServiceProvider({
    required this.id,
    this.ownerId,
    this.completedJobs = 0,
    this.description = '',
    this.experienceYears = 0,
    required this.name,
    required this.category,
    required this.location,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.reviewCount,
    required this.completionRate,
    required this.responseTimeMinutes,
    required this.communityVouches,
    required this.cancellationsLast7d,
    required this.priceMin,
    required this.priceMax,
    required this.availableSlots,
    required this.trustScore,
    required this.phone,
    this.redFlags = const [],
    this.avatar,
  });
  factory ServiceProvider.fromJson(Map<String, dynamic> row) => ServiceProvider(
    id: row['id'] as String,
    ownerId: row['user_id'] as String?,
    name: row['name'] as String,
    category: row['category'] as String,
    location: row['location'] as String,
    lat: 0,
    lng: 0,
    rating: (row['rating'] as num? ?? 0).toDouble(),
    reviewCount: (row['review_count'] as num? ?? 0).toInt(),
    completedJobs: (row['completed_jobs'] as num? ?? 0).toInt(),
    description: row['description'] as String? ?? '',
    experienceYears: (row['experience_years'] as num? ?? 0).toInt(),
    completionRate: (row['completion_rate'] as num? ?? 0).toDouble(),
    responseTimeMinutes: 0,
    communityVouches: 0,
    cancellationsLast7d: 0,
    priceMin: (row['price_min'] as num).toInt(),
    priceMax: (row['price_max'] as num).toInt(),
    availableSlots: List<String>.from(row['available_slots'] as List? ?? []),
    trustScore: 0,
    phone: row['phone'] as String? ?? '',
    avatar: row['avatar_path'] as String?,
  );

  // GPS distance is not calculated in this version.
  double get distanceKm => double.nan;

  String get priceRange =>
      'Rs. ${priceMin.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} – ${priceMax.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
}

class BookingReceipt {
  final String bookingId;
  final String service;
  final ServiceProvider provider;
  final String location;
  final String date;
  final String time;
  final int originalPrice;
  final int finalPrice;
  final int savedAmount;
  final DateTime createdAt;
  const BookingReceipt({
    required this.bookingId,
    required this.service,
    required this.provider,
    required this.location,
    required this.date,
    required this.time,
    required this.originalPrice,
    required this.finalPrice,
    required this.savedAmount,
    required this.createdAt,
  });

  int get savingsPercent =>
      originalPrice > 0 ? ((savedAmount / originalPrice) * 100).round() : 0;
}
