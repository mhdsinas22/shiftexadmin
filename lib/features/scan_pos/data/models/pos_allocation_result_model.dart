import 'package:shiftexadmin/features/scan_pos/domain/entities/pos_allocation_result_entity.dart';

class PosAllocationResultModel extends PosAllocationResultEntity {
  const PosAllocationResultModel({
    required super.success,
    required super.customerId,
    required super.fullName,
    required super.membershipId,
    required super.instantPointsAllocated,
    required super.futurePointsAllocated,
    required super.totalPointsAllocated,
    super.instantInrEquivalent,
    super.futureInrEquivalent,
    required super.totalInrEquivalent,
    super.pointsPerRupee,
    super.pointsToInrRate,
    super.currencyCode,
    super.rateVersionId,
    required super.billNumber,
    required super.branchName,
    required super.availablePoints,
    required super.lockedPoints,
    super.lifetimeEarnedPoints,
    super.lifetimeRedeemedPoints,
    super.instantTransactionId,
    super.futureTransactionId,
    super.futureAllocationId,
    super.unlockAt,
    required super.allocatedAt,
  });

  static double _parseNum(dynamic raw, double fallback) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? fallback;
  }

  static int _parsePtsPerRupee(dynamic raw, double rate) {
    int parsed;
    if (raw is num) {
      parsed = raw.round();
    } else {
      parsed =
          double.tryParse(raw?.toString() ?? '')?.round() ??
          (rate > 0 ? (1.0 / rate).round() : 10);
    }
    return parsed > 0 ? parsed : 10;
  }

  factory PosAllocationResultModel.fromJson(Map<String, dynamic> json) {
    final double inr = _parseNum(json['total_inr_equivalent'], 0.0);
    final double instantInr = _parseNum(json['instant_inr_equivalent'], 0.0);
    final double futureInr = _parseNum(json['future_inr_equivalent'], 0.0);
    final double rate = _parseNum(json['points_to_inr_rate'], 0.10);
    final int ptsPerRupee = _parsePtsPerRupee(
      json['points_per_rupee'] ?? json['points_per_currency_unit'],
      rate,
    );

    return PosAllocationResultModel(
      success: json['success'] as bool? ?? true,
      customerId: json['customer_id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      membershipId: json['membership_id']?.toString() ?? '',
      instantPointsAllocated:
          (json['instant_points_allocated'] as num?)?.toInt() ?? 0,
      futurePointsAllocated:
          (json['future_points_allocated'] as num?)?.toInt() ?? 0,
      totalPointsAllocated:
          (json['total_points_allocated'] as num?)?.toInt() ?? 0,
      instantInrEquivalent: instantInr,
      futureInrEquivalent: futureInr,
      totalInrEquivalent: inr,
      pointsPerRupee: ptsPerRupee,
      pointsToInrRate: rate,
      currencyCode: json['currency_code']?.toString() ?? 'INR',
      rateVersionId: json['rate_version_id']?.toString(),
      billNumber: json['bill_number']?.toString() ?? '',
      branchName: json['branch_name']?.toString() ?? 'Counter #1 POS',
      availablePoints: (json['available_points'] as num?)?.toInt() ?? 0,
      lockedPoints: (json['locked_points'] as num?)?.toInt() ?? 0,
      lifetimeEarnedPoints:
          (json['lifetime_earned_points'] as num?)?.toInt() ?? 0,
      lifetimeRedeemedPoints:
          (json['lifetime_redeemed_points'] as num?)?.toInt() ?? 0,
      instantTransactionId: json['instant_transaction_id']?.toString(),
      futureTransactionId: json['future_transaction_id']?.toString(),
      futureAllocationId: json['future_allocation_id']?.toString(),
      unlockAt: json['unlock_at'] != null
          ? DateTime.tryParse(json['unlock_at'].toString())
          : null,
      allocatedAt: json['allocated_at'] != null
          ? DateTime.tryParse(json['allocated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class PosClaimRedemptionResultModel extends PosClaimRedemptionResultEntity {
  const PosClaimRedemptionResultModel({
    required super.success,
    required super.customerId,
    required super.fullName,
    required super.membershipId,
    required super.tokenCode,
    required super.redeemedPoints,
    required super.inrValue,
    super.pointsPerRupee,
    super.pointsToInrRate,
    super.currencyCode,
    required super.billNumber,
    required super.branchName,
    required super.availablePoints,
    required super.lockedPoints,
    super.lifetimeRedeemedPoints,
    required super.transactionId,
    required super.redeemedAt,
  });

  factory PosClaimRedemptionResultModel.fromJson(Map<String, dynamic> json) {
    final double inr = PosAllocationResultModel._parseNum(
      json['inr_value'],
      0.0,
    );
    final double rate = PosAllocationResultModel._parseNum(
      json['points_to_inr_rate'],
      0.10,
    );
    final int ptsPerRupee = PosAllocationResultModel._parsePtsPerRupee(
      json['points_per_rupee'] ?? json['points_per_currency_unit'],
      rate,
    );

    return PosClaimRedemptionResultModel(
      success: json['success'] as bool? ?? true,
      customerId: json['customer_id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      membershipId: json['membership_id']?.toString() ?? '',
      tokenCode: json['token_code']?.toString() ?? '',
      redeemedPoints: (json['redeemed_points'] as num?)?.toInt() ?? 0,
      inrValue: inr,
      pointsPerRupee: ptsPerRupee,
      pointsToInrRate: rate,
      currencyCode: json['currency_code']?.toString() ?? 'INR',
      billNumber: json['bill_number']?.toString() ?? '',
      branchName: json['branch_name']?.toString() ?? 'Counter #1 POS',
      availablePoints: (json['available_points'] as num?)?.toInt() ?? 0,
      lockedPoints: (json['locked_points'] as num?)?.toInt() ?? 0,
      lifetimeRedeemedPoints:
          (json['lifetime_redeemed_points'] as num?)?.toInt() ?? 0,
      transactionId: json['transaction_id']?.toString() ?? '',
      redeemedAt: json['redeemed_at'] != null
          ? DateTime.tryParse(json['redeemed_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class PosClaimRejectOrFlagResultModel extends PosClaimRejectOrFlagResultEntity {
  const PosClaimRejectOrFlagResultModel({
    super.success,
    required super.action,
    required super.auditStatus,
    required super.tokenId,
    super.claimId,
    required super.claimReference,
    required super.reason,
    super.branchName,
    super.availablePoints,
    super.reservedPoints,
    required super.processedAt,
  });

  factory PosClaimRejectOrFlagResultModel.fromJson(Map<String, dynamic> json) {
    return PosClaimRejectOrFlagResultModel(
      success: json['success'] as bool? ?? true,
      action: json['action']?.toString() ?? 'reject',
      auditStatus: json['audit_status']?.toString() ?? 'rejected',
      tokenId: json['token_id']?.toString() ?? '',
      claimId: json['claim_id']?.toString(),
      claimReference: json['claim_reference']?.toString() ?? 'CLM-0000',
      reason: json['reason']?.toString() ?? '',
      branchName: json['branch_name']?.toString() ?? 'Counter #1 POS',
      availablePoints: (json['available_points'] as num?)?.toInt() ?? 0,
      reservedPoints: (json['reserved_points'] as num?)?.toInt() ?? 0,
      processedAt: json['processed_at'] != null
          ? DateTime.tryParse(json['processed_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
