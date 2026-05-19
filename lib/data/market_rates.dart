class MarketRate {
  final int min;
  final int max;
  final int avg;
  const MarketRate({required this.min, required this.max, required this.avg});
}

const Map<String, MarketRate> marketRates = {
  'AC Technician': MarketRate(min: 1500, max: 2500, avg: 2000),
  'AC Repair': MarketRate(min: 1500, max: 2500, avg: 2000),
  'Plumber': MarketRate(min: 800, max: 1500, avg: 1100),
  'Electrician': MarketRate(min: 1000, max: 2000, avg: 1500),
  'Tutor': MarketRate(min: 500, max: 1500, avg: 1000),
  'Beautician': MarketRate(min: 1200, max: 3000, avg: 2000),
  'Carpenter': MarketRate(min: 1000, max: 2500, avg: 1700),
  'Painter': MarketRate(min: 2000, max: 5000, avg: 3500),
  'Deep Cleaning': MarketRate(min: 3000, max: 8500, avg: 5500),
};

MarketRate getRateFor(String category) {
  for (final key in marketRates.keys) {
    if (category.toLowerCase().contains(key.toLowerCase()) ||
        key.toLowerCase().contains(category.toLowerCase())) {
      return marketRates[key]!;
    }
  }
  return const MarketRate(min: 1000, max: 3000, avg: 2000);
}
