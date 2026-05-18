class BusPass {
  final int id;
  final String passId;
  final String passType;
  final DateTime issueDate;
  final DateTime expiryDate;
  final String status;
  final int dailyTripCount;
  final String? userEmail;
  final String? username;
  final String? userPhone;
  final String? collegeName;
  final String? routeFrom;
  final String? routeTo;
  final String? userAddress;
  final String? userPhoto;
  final String? userIdProof;

  final String paymentStatus;
  final bool isCurrentlyValid;
  final DateTime? currentValidTo;
  final String? activeRenewalId;
  final String? activeRenewalMonth;

  BusPass({
    required this.id,
    required this.passId,
    required this.passType,
    required this.issueDate,
    required this.expiryDate,
    required this.status,
    required this.daily_trip_count,
    required this.paymentStatus,
    required this.isCurrentlyValid,
    this.currentValidTo,
    this.activeRenewalId,
    this.activeRenewalMonth,
    this.userEmail,
    this.username,
    this.userPhone,
    this.collegeName,
    this.routeFrom,
    this.routeTo,
    this.userAddress,
    this.userPhoto,
    this.userIdProof,
  }) : dailyTripCount = daily_trip_count;

  final int daily_trip_count;

  factory BusPass.fromJson(Map<String, dynamic> json) {
    return BusPass(
      id: json['id'] ?? 0,
      passId: json['main_pass_id'] ?? json['pass_id'] ?? '',
      passType: json['pass_type'] ?? 'STUDENT',
      issueDate: json['issue_date'] != null ? DateTime.parse(json['issue_date']) : DateTime.now(),
      expiryDate: json['expiry_date'] != null ? DateTime.parse(json['expiry_date']) : DateTime.now(),
      status: json['status'] ?? 'PENDING',
      daily_trip_count: json['daily_trip_count'] ?? 0,
      paymentStatus: json['payment_status'] ?? 'PENDING',
      isCurrentlyValid: json['is_currently_valid'] ?? false,
      currentValidTo: json['current_valid_to'] != null ? DateTime.parse(json['current_valid_to']) : null,
      activeRenewalId: json['active_renewal_id'],
      activeRenewalMonth: json['active_renewal_month'],
      userEmail: json['user_email'],
      username: json['username'],
      userPhone: json['user_phone'],
      collegeName: json['college_name'],
      routeFrom: json['route_from'],
      routeTo: json['route_to'],
      userAddress: json['user_address'],
      userPhoto: json['user_photo'],
      userIdProof: json['user_id_proof'],
    );
  }
}

class MonthlyRenewal {
  final String renewalId;
  final DateTime validFrom;
  final DateTime validTo;
  final String paymentStatus;
  final double amount;

  MonthlyRenewal({
    required this.renewalId,
    required this.validFrom,
    required this.validTo,
    required this.paymentStatus,
    required this.amount,
  });

  factory MonthlyRenewal.fromJson(Map<String, dynamic> json) {
    return MonthlyRenewal(
      renewalId: json['renewal_id'] ?? '',
      validFrom: DateTime.parse(json['valid_from']),
      validTo: DateTime.parse(json['valid_to']),
      paymentStatus: json['payment_status'] ?? 'PENDING',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
    );
  }
}
