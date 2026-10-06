class LiveBooking {
  final Map<String, dynamic> row;
  const LiveBooking(this.row);
  String get id => row['id'] as String;
  String get providerId => row['provider_id'] as String;
  String get customerId => row['customer_id'] as String;
  String get providerUserId => row['provider_user_id'] as String;
  String get service => row['service'] as String;
  String get status => row['status'] as String;
  String get address => row['location'] as String;
  String get notes => row['notes'] as String? ?? '';
  String get date => row['booking_date'] as String;
  String get slot => row['time_slot'] as String;
  int get price => (row['final_price'] as num).toInt();
  int get originalPrice => (row['original_price'] as num).toInt();
  Map<String, dynamic> get provider =>
      Map<String, dynamic>.from(row['provider_snapshot'] as Map);
  String get providerName => provider['name'] as String;
  String get statusLabel => switch (status) {
    'pending' => 'Waiting for provider',
    'accepted' => 'Accepted',
    'on_the_way' => 'Provider on the way',
    'in_progress' => 'Service in progress',
    'completed' => 'Completed',
    'cancelled' => 'Cancelled',
    'declined' => 'Declined',
    _ => status,
  };
  bool get canCancel => ['pending', 'accepted', 'on_the_way'].contains(status);
  bool get terminal => ['completed', 'cancelled', 'declined'].contains(status);
}
