import '../models/local_data.dart';

const _serviceWords = {
  'Plumber': [
    'plumber',
    'pipe',
    'leak',
    'tap',
    'pani',
    'nalkay',
    'پلمبر',
    'پانی',
    'نل',
  ],
  'Electrician': [
    'electrician',
    'electric',
    'bijli',
    'wiring',
    'بجلی',
    'الیکٹریشن',
  ],
  'AC Technician': ['ac', 'air conditioner', 'cooling', 'اے سی'],
  'Carpenter': ['carpenter', 'wood', 'lakri', 'furniture', 'بڑھئی', 'لکڑی'],
  'Painter': ['painter', 'paint', 'rang', 'پینٹر', 'رنگ'],
  'Cleaning': ['cleaning', 'safai', 'clean', 'صفائی'],
  'Tutor': ['tutor', 'teacher', 'tuition', 'ٹیوٹر', 'استاد', 'ٹیوشن'],
  'Beautician': [
    'beautician',
    'makeup',
    'facial',
    'mehndi',
    'بیوٹیشن',
    'مہندی',
  ],
};

String? serviceForQuery(String query) {
  final lower = query.toLowerCase();
  for (final entry in _serviceWords.entries) {
    for (final word in entry.value) {
      final boundary = RegExp(r'^[a-z ]+$').hasMatch(word);
      final pattern = boundary
          ? '(?<![a-z])${RegExp.escape(word)}(?![a-z])'
          : RegExp.escape(word);
      if (RegExp(pattern).hasMatch(lower)) return entry.key;
    }
  }
  return null;
}

List<WorkerContact> findSavedWorkers(
  List<WorkerContact> workers,
  String query, {
  String? category,
  bool favoritesOnly = false,
}) {
  final normalized = query.toLowerCase().trim();
  final matchedService = serviceForQuery(normalized);
  final result = workers.where((w) {
    if (favoritesOnly && !w.favorite) return false;
    if (category != null && w.category != category) return false;
    final searchable =
        '${w.name} ${w.phone} ${w.city} ${w.category} ${w.details}'
            .toLowerCase();
    return normalized.isEmpty ||
        searchable.contains(normalized) ||
        w.category == matchedService;
  }).toList();
  result.sort((a, b) {
    final favorite = (b.favorite ? 1 : 0).compareTo(a.favorite ? 1 : 0);
    return favorite != 0
        ? favorite
        : a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return result;
}
