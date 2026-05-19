class ServiceProvider {
  final String id;
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

  double get distanceKm {
    // Simulated distance based on id for demo
    final distances = {'P001': 2.1, 'P002': 3.4, 'P003': 1.8, 'P004': 4.2, 'P005': 0.9};
    return distances[id] ?? 5.0;
  }

  String get priceRange => 'Rs. ${priceMin.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} – ${priceMax.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
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
