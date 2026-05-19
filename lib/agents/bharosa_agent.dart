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
  // Trust Score = completion(×0.40) + speed(×0.30) + vouches(×0.20) + rating(×0.10)
  static int _computeTrustScore(ServiceProvider p) {
    final completionScore = p.completionRate * 100;
    final speedScore = (100 - ((p.responseTimeMinutes - 5) / 55) * 100).clamp(0, 100);
    final vouchScore = ((p.communityVouches / 20) * 100).clamp(0, 100);
    final ratingScore = ((p.rating - 1) / 4) * 100;

    return (completionScore * 0.40 + speedScore * 0.30 + vouchScore * 0.20 + ratingScore * 0.10)
        .round()
        .clamp(0, 100);
  }

  static List<String> _detectRedFlags(ServiceProvider p) {
    final flags = <String>[];
    if (p.cancellationsLast7d >= 2) {
      flags.add('${p.cancellationsLast7d} cancellations in last 7 days — reliability risk');
    }
    if (p.responseTimeMinutes > 120) {
      flags.add('Very slow response (${p.responseTimeMinutes} min avg) — delay risk');
    } else if (p.responseTimeMinutes > 60) {
      flags.add('Response time above average (${p.responseTimeMinutes} min)');
    }
    if (p.rating >= 4.0 && p.completionRate < 0.80) {
      flags.add('Rating/completion discrepancy: ${p.rating}★ but ${(p.completionRate * 100).round()}% completion');
    }
    if (p.reviewCount < 15) {
      flags.add('Limited review history (${p.reviewCount} reviews) — new provider');
    }
    if (p.communityVouches < 3) {
      flags.add('Low community endorsement (${p.communityVouches} vouches)');
    }
    flags.addAll(p.redFlags);
    return flags;
  }

  static List<String> _detectStrengths(ServiceProvider p) {
    final strengths = <String>[];
    if (p.completionRate >= 0.95) {
      strengths.add('Excellent completion rate: ${(p.completionRate * 100).round()}%');
    } else if (p.completionRate >= 0.90) {
      strengths.add('Good completion rate: ${(p.completionRate * 100).round()}%');
    }
    if (p.responseTimeMinutes <= 15) {
      strengths.add('Fast responder: replies in ~${p.responseTimeMinutes} min');
    }
    if (p.communityVouches >= 10) {
      strengths.add('Strong community trust: ${p.communityVouches} vouches');
    }
    if (p.rating >= 4.5) {
      strengths.add('Highly rated: ${p.rating}★ (${p.reviewCount} reviews)');
    }
    if (p.cancellationsLast7d == 0) {
      strengths.add('Zero cancellations this week');
    }
    if (p.reviewCount >= 100) {
      strengths.add('Well-established: ${p.reviewCount}+ reviews');
    }
    return strengths;
  }

  static BharosaRecommendation _getRecommendation(int score, List<String> flags) {
    if (flags.length >= 3) return BharosaRecommendation.avoid;
    if (score >= 80 && flags.isEmpty) return BharosaRecommendation.strongYes;
    if (score >= 65) return BharosaRecommendation.yes;
    if (score >= 45) return BharosaRecommendation.caution;
    return BharosaRecommendation.avoid;
  }

  static String _explain(ServiceProvider p, int score, BharosaRecommendation rec, List<String> flags) {
    switch (rec) {
      case BharosaRecommendation.strongYes:
        return '${p.name} highly trustworthy — ${(p.completionRate * 100).round()}% completion, '
            '${p.communityVouches} community vouches, ${p.responseTimeMinutes} min response. '
            'KHIDMAT top recommendation!';
      case BharosaRecommendation.yes:
        return '${p.name} is a good option. Trust score $score/100. '
            '${flags.isNotEmpty ? 'Some minor concerns exist.' : 'No major issues.'} Overall recommended.';
      case BharosaRecommendation.caution:
        return '${p.name} — thoda ehtiyaat karein. ${flags.isNotEmpty ? flags.first : 'Trust score average hai'}. '
            'Use only if no better option available.';
      case BharosaRecommendation.avoid:
        return '${p.name} se avoid karein. ${flags.take(2).join('. ')}. Not recommended.';
    }
  }

  static BharosaReport evaluate(ServiceProvider p) {
    final trustScore = _computeTrustScore(p);
    final strengths = _detectStrengths(p);
    final redFlags = _detectRedFlags(p);
    final recommendation = _getRecommendation(trustScore, redFlags);
    final explanation = _explain(p, trustScore, recommendation, redFlags);

    return BharosaReport(
      provider: p,
      trustScore: trustScore,
      strengths: strengths,
      redFlags: redFlags,
      recommendation: recommendation,
      explanation: explanation,
    );
  }

  static List<BharosaReport> rankAll(List<ServiceProvider> providers) {
    return providers
        .map(evaluate)
        .toList()
      ..sort((a, b) {
        if (b.trustScore != a.trustScore) return b.trustScore - a.trustScore;
        return a.redFlags.length - b.redFlags.length;
      });
  }
}
