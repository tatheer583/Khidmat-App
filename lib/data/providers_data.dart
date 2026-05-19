import '../models/provider_model.dart';

final List<ServiceProvider> allProviders = [
  const ServiceProvider(
    id: 'P001',
    name: 'Ali AC Services',
    category: 'AC Technician',
    location: 'G-13, Islamabad',
    lat: 33.6844, lng: 73.0479,
    rating: 4.8, reviewCount: 120,
    completionRate: 0.98, responseTimeMinutes: 12,
    communityVouches: 14, cancellationsLast7d: 0,
    priceMin: 1500, priceMax: 2500,
    availableSlots: ['10:00', '12:00', '15:00', '17:00'],
    trustScore: 87, phone: '+92 300 1234567',
  ),
  const ServiceProvider(
    id: 'P002',
    name: 'Ahmed Electric',
    category: 'Electrician',
    location: 'G-14, Islamabad',
    lat: 33.6750, lng: 73.0350,
    rating: 4.2, reviewCount: 45,
    completionRate: 0.72, responseTimeMinutes: 48,
    communityVouches: 3, cancellationsLast7d: 2,
    priceMin: 1200, priceMax: 2000,
    availableSlots: ['11:00', '14:00', '16:00'],
    trustScore: 54, phone: '+92 301 2345678',
    redFlags: ['2 last-minute cancellations this week', 'Slow response time'],
  ),
  const ServiceProvider(
    id: 'P003',
    name: 'Khan Cooling Fix',
    category: 'AC Technician',
    location: 'G-11, Islamabad',
    lat: 33.6950, lng: 73.0200,
    rating: 3.8, reviewCount: 12,
    completionRate: 0.85, responseTimeMinutes: 30,
    communityVouches: 2, cancellationsLast7d: 0,
    priceMin: 1000, priceMax: 1800,
    availableSlots: ['09:00', '13:00'],
    trustScore: 62, phone: '+92 302 3456789',
  ),
  const ServiceProvider(
    id: 'P004',
    name: 'Bilal Hussain',
    category: 'Electrician',
    location: 'F-10, Islamabad',
    lat: 33.6980, lng: 73.0150,
    rating: 4.5, reviewCount: 89,
    completionRate: 0.95, responseTimeMinutes: 15,
    communityVouches: 11, cancellationsLast7d: 0,
    priceMin: 1000, priceMax: 2000,
    availableSlots: ['10:00', '12:00', '14:00', '16:00', '18:00'],
    trustScore: 82, phone: '+92 303 4567890',
  ),
  const ServiceProvider(
    id: 'P005',
    name: 'Hassan Plumbing',
    category: 'Plumber',
    location: 'G-13, Islamabad',
    lat: 33.6830, lng: 73.0460,
    rating: 4.6, reviewCount: 67,
    completionRate: 0.93, responseTimeMinutes: 10,
    communityVouches: 9, cancellationsLast7d: 0,
    priceMin: 800, priceMax: 1500,
    availableSlots: ['08:00', '10:00', '14:00', '16:00'],
    trustScore: 85, phone: '+92 304 5678901',
  ),
  const ServiceProvider(
    id: 'P006',
    name: 'Nadeem Carpentry',
    category: 'Carpenter',
    location: 'G-10, Islamabad',
    lat: 33.7000, lng: 73.0300,
    rating: 4.3, reviewCount: 34,
    completionRate: 0.90, responseTimeMinutes: 25,
    communityVouches: 6, cancellationsLast7d: 1,
    priceMin: 1500, priceMax: 3000,
    availableSlots: ['09:00', '11:00', '15:00'],
    trustScore: 74, phone: '+92 305 6789012',
  ),
  const ServiceProvider(
    id: 'P007',
    name: 'Zara Beauty Salon',
    category: 'Beautician',
    location: 'F-11, Islamabad',
    lat: 33.7100, lng: 72.9900,
    rating: 4.9, reviewCount: 203,
    completionRate: 0.97, responseTimeMinutes: 8,
    communityVouches: 22, cancellationsLast7d: 0,
    priceMin: 1500, priceMax: 4000,
    availableSlots: ['11:00', '13:00', '15:00', '17:00'],
    trustScore: 92, phone: '+92 306 7890123',
  ),
  const ServiceProvider(
    id: 'P008',
    name: 'Prof. Rashid Tutor',
    category: 'Tutor',
    location: 'G-13, Islamabad',
    lat: 33.6860, lng: 73.0500,
    rating: 4.7, reviewCount: 55,
    completionRate: 0.96, responseTimeMinutes: 20,
    communityVouches: 13, cancellationsLast7d: 0,
    priceMin: 800, priceMax: 1500,
    availableSlots: ['16:00', '17:00', '18:00', '19:00'],
    trustScore: 88, phone: '+92 307 8901234',
  ),
  const ServiceProvider(
    id: 'P009',
    name: 'Raza Deep Clean',
    category: 'Deep Cleaning',
    location: 'F-10, Islamabad',
    lat: 33.6990, lng: 73.0170,
    rating: 4.4, reviewCount: 42,
    completionRate: 0.91, responseTimeMinutes: 35,
    communityVouches: 7, cancellationsLast7d: 0,
    priceMin: 4000, priceMax: 8000,
    availableSlots: ['09:00', '13:00'],
    trustScore: 77, phone: '+92 308 9012345',
  ),
  const ServiceProvider(
    id: 'P010',
    name: 'Tariq Painter',
    category: 'Painter',
    location: 'G-11, Islamabad',
    lat: 33.6960, lng: 73.0220,
    rating: 4.1, reviewCount: 28,
    completionRate: 0.88, responseTimeMinutes: 40,
    communityVouches: 5, cancellationsLast7d: 1,
    priceMin: 3000, priceMax: 7000,
    availableSlots: ['08:00', '10:00', '14:00'],
    trustScore: 68, phone: '+92 309 0123456',
  ),
];

List<ServiceProvider> getProvidersByCategory(String category) {
  final cat = category.toLowerCase();
  final filtered = allProviders.where((p) {
    final pCat = p.category.toLowerCase();
    if (cat.contains('ac') || cat.contains('air conditioner') || cat.contains('cooling')) {
      return pCat.contains('ac');
    }
    if (cat.contains('plumb') || cat.contains('nalkay') || cat.contains('pipe')) {
      return pCat.contains('plumb') || pCat == 'plumber';
    }
    if (cat.contains('electric')) {
      return pCat.contains('electric');
    }
    if (cat.contains('tutor') || cat.contains('teacher')) {
      return pCat.contains('tutor');
    }
    if (cat.contains('beautician') || cat.contains('beauty') || cat.contains('parlor')) {
      return pCat.contains('beautician') || pCat.contains('beauty');
    }
    if (cat.contains('carpenter') || cat.contains('mistri')) {
      return pCat.contains('carpenter');
    }
    if (cat.contains('paint') || cat.contains('rang')) {
      return pCat.contains('painter') || pCat.contains('paint');
    }
    if (cat.contains('clean') || cat.contains('safai')) {
      return pCat.contains('clean');
    }
    return false;
  }).toList();

  return filtered.isEmpty ? allProviders.take(4).toList() : filtered;
}
