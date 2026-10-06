import '../models/provider_model.dart';

enum BharosaRecommendation { strongYes, yes, caution, avoid }

class BharosaReport {
  final ServiceProvider provider;
  final int trustScore;
  final List<String> strengths;
  final List<String> redFlags;
  final BharosaRecommendation recommendation;
  final String explanation;
  const BharosaReport({
    required this.provider,
    required this.trustScore,
    required this.strengths,
    required this.redFlags,
    required this.recommendation,
    required this.explanation,
  });
}

class BharosaAgent {
  static BharosaReport evaluate(ServiceProvider p) {
    final hasHistory = p.completedJobs > 0 || p.reviewCount > 0;
    final score = hasHistory
        ? (p.completionRate * 70 + p.rating / 5 * 30)
              .round()
              .clamp(0, 100)
              .toInt()
        : 0;
    final rec = !hasHistory
        ? BharosaRecommendation.caution
        : score >= 80
        ? BharosaRecommendation.strongYes
        : score >= 60
        ? BharosaRecommendation.yes
        : BharosaRecommendation.caution;
    return BharosaReport(
      provider: p,
      trustScore: score,
      strengths: [
        if (p.completedJobs > 0) '${p.completedJobs} completed jobs',
        if (p.reviewCount > 0)
          '${p.rating.toStringAsFixed(1)} / 5 from ${p.reviewCount} verified reviews',
      ],
      redFlags: hasHistory
          ? []
          : ['New provider — no completed job history yet'],
      recommendation: rec,
      explanation: hasHistory
          ? 'Ranked using completed bookings and reviews from actual customers.'
          : 'Approved listing. Customer reviews will appear after completed services.',
    );
  }

  static List<BharosaReport> rankAll(List<ServiceProvider> providers) =>
      providers.map(evaluate).toList()..sort((a, b) {
        final score = b.trustScore.compareTo(a.trustScore);
        return score != 0 ? score : a.provider.name.compareTo(b.provider.name);
      });
}
