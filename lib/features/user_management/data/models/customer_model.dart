import 'package:shiftexadmin/features/user_management/domain/entities/customer_entity.dart';

class CustomerModel extends CustomerEntity {
  const CustomerModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.mobileNumber,
    required super.approvalStatus,
    super.approvedBy,
    super.approvedAt,
    super.rejectionReason,
    required super.createdAt,
    required super.updatedAt,
    super.customerCode,
    super.membershipTier,
    super.instantPoints,
    super.instantRupees,
    super.futurePoints,
    super.futurePointsNote,
    super.restrictedReason,
    super.earnedPoints,
    super.earnedRupees,
    super.earnedTxCount,
  });

  static int _parseInt(dynamic raw, [int fallback = 0]) {
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? fallback;
  }

  static double _parseDouble(dynamic raw, [double fallback = 0.0]) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? fallback;
  }

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final createdAtStr = json['created_at'] as String?;
    final updatedAtStr = json['updated_at'] as String?;
    final approvedAtStr = json['approved_at'] as String?;

    final createdAt = createdAtStr != null
        ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
        : DateTime.now();
    final updatedAt = updatedAtStr != null
        ? DateTime.tryParse(updatedAtStr) ?? DateTime.now()
        : DateTime.now();
    final approvedAt = approvedAtStr != null
        ? DateTime.tryParse(approvedAtStr)
        : null;

    final status = (json['approval_status'] as String? ?? 'pending')
        .toLowerCase();

    final walletMap = json['wallet'] is Map
        ? Map<String, dynamic>.from(json['wallet'] as Map)
        : null;

    final instantPts = json['instant_points'] != null
        ? _parseInt(json['instant_points'])
        : json['available_points'] != null
        ? _parseInt(json['available_points'])
        : walletMap != null
        ? _parseInt(
            walletMap['instant_points'] ?? walletMap['available_points'],
          )
        : 0;

    final futurePts = json['future_points'] != null
        ? _parseInt(json['future_points'])
        : json['locked_points'] != null
        ? _parseInt(json['locked_points'])
        : walletMap != null
        ? _parseInt(walletMap['future_points'] ?? walletMap['locked_points'])
        : 0;

    final ptsPerRupeeRaw = _parseInt(json['points_per_rupee'], 10);
    final ptsPerRupee = ptsPerRupeeRaw > 0 ? ptsPerRupeeRaw : 10;

    final rupees = json['instant_rupees'] != null
        ? _parseDouble(json['instant_rupees'])
        : double.parse((instantPts / ptsPerRupee).toStringAsFixed(2));

    final earnedPts = json['earned_points'] != null
        ? _parseInt(json['earned_points'])
        : json['lifetime_earned_points'] != null
        ? _parseInt(json['lifetime_earned_points'])
        : walletMap != null && walletMap['lifetime_earned_points'] != null
        ? _parseInt(walletMap['lifetime_earned_points'])
        : instantPts + futurePts;

    final earnedInr = json['earned_rupees'] != null
        ? _parseDouble(json['earned_rupees'])
        : double.parse((earnedPts / ptsPerRupee).toStringAsFixed(2));

    final earnedTxCnt = _parseInt(json['earned_tx_count']);

    final customerCode =
        json['customer_code']?.toString() ??
        walletMap?['customer_code']?.toString();

    final membershipTier =
        json['membership_tier']?.toString() ??
        walletMap?['membership_tier']?.toString();

    String? futureNote;
    if (futurePts > 0) {
      futureNote = status == 'pending' ? 'Welcome Gift' : 'Hold remaining';
    }

    String? restReason = json['rejection_reason'] as String?;
    if (status == 'suspended' && (restReason == null || restReason.isEmpty)) {
      restReason = 'Suspicious account activity';
    }

    return CustomerModel(
      id: id,
      fullName: json['full_name'] as String? ?? 'Unknown Customer',
      email: json['email'] as String? ?? '',
      mobileNumber: json['mobile_number'] as String? ?? '',
      approvalStatus: status,
      approvedBy: json['approved_by'] as String?,
      approvedAt: approvedAt,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
      customerCode: customerCode,
      membershipTier: membershipTier,
      instantPoints: instantPts,
      instantRupees: rupees,
      futurePoints: futurePts,
      futurePointsNote: futureNote,
      restrictedReason: restReason,
      earnedPoints: earnedPts,
      earnedRupees: earnedInr,
      earnedTxCount: earnedTxCnt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'mobile_number': mobileNumber,
      'approval_status': approvalStatus,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'customer_code': customerCode,
      'membership_tier': membershipTier,
      'instant_points': instantPoints,
      'instant_rupees': instantRupees,
      'future_points': futurePoints,
      'earned_points': earnedPoints,
      'earned_rupees': earnedRupees,
      'earned_tx_count': earnedTxCount,
    };
  }
}
