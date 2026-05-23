enum JobStatus { incoming, accepted, inProgress, completed, declined, cancelled }

class ProviderJob {
  final String id;
  final String customerName;
  final String customerInitial;
  final String service;
  final String location;
  final String distanceKm;
  final String requestedTime;
  final String urgency;
  final int quotedPrice;
  final String notes;
  final DateTime createdAt;
  JobStatus status;

  ProviderJob({
    required this.id,
    required this.customerName,
    required this.customerInitial,
    required this.service,
    required this.location,
    required this.distanceKm,
    required this.requestedTime,
    required this.urgency,
    required this.quotedPrice,
    required this.notes,
    required this.createdAt,
    this.status = JobStatus.incoming,
  });
}

class EarningEntry {
  final String jobId;
  final String customerName;
  final String service;
  final int amount;
  final DateTime date;

  const EarningEntry({
    required this.jobId,
    required this.customerName,
    required this.service,
    required this.amount,
    required this.date,
  });
}

class ProviderReview {
  final String customerName;
  final String customerInitial;
  final double rating;
  final String comment;
  final String service;
  final DateTime date;

  const ProviderReview({
    required this.customerName,
    required this.customerInitial,
    required this.rating,
    required this.comment,
    required this.service,
    required this.date,
  });
}
