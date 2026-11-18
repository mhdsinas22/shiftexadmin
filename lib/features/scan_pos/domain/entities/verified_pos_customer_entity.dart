import 'package:shiftexadmin/features/settings/points_to_cash/domain/entities/points_to_cash_config_entity.dart';

enum ScanPosMode { giveReward, verifyClaim }

class ClaimAuditChecksEntity {
  final bool tokenSignatureValid;
  final bool claimNotExpired;
  final bool singleUsePassed;
  final bool replayProtectionPassed;
  final bool customerEligible;
  final bool balanceReservationValid;

  const ClaimAuditChecksEntity({
    this.tokenSignatureValid = true,
    this.claimNotExpired = true,
    this.singleUsePassed = true,
    this.replayProtectionPassed = true,
    this.customerEligible = true,
    this.balanceReservationValid = true,
  });

  bool get allChecksPassed =>
      tokenSignatureValid &&
      claimNotExpired &&
      singleUsePassed &&
      replayProtectionPassed &&
      customerEligible &&
      balanceReservationValid;
}

class VerifiedPosCustomerEntity {
  final String customerId;
  final String fullName;
  final String email;
  final String mobileNumber;
  final String approvalStatus;
  final String membershipId;
  final String membershipTier;
  final int availablePoints;
  final int reservedPoints;
  final int lockedPoints;
  final int lifetimeEarnedPoints;
  final int lifetimeRedeemedPoints;
  final int pointsPerRupee;
  final double pointsToInrRate;
  final String currencyCode;
  final String? tokenId;
  final String? tokenCode;
  final String? qrPayload;
  final String? tokenPurpose;
  final bool allowDeduction;
  final DateTime? tokenCreatedAt;
  final DateTime? tokenExpiresAt;
  final String? claimId;
  final String? claimReference;
  final String? claimStatus;
  final String? claimAuditStatus;
  final int? claimPoints;
  final double? claimDiscountAmount;
  final String rewardName;
  final String rewardCategory;
  final String merchantName;
  final String orderReference;
  final ClaimAuditChecksEntity auditChecks;
  final String verificationMethod;

  const VerifiedPosCustomerEntity({
    required this.customerId,
    required this.fullName,
    required this.email,
    required this.mobileNumber,
    required this.approvalStatus,
    required this.membershipId,
    this.membershipTier = 'Pebble Black Member',
    required this.availablePoints,
    this.reservedPoints = 0,
    required this.lockedPoints,
    this.lifetimeEarnedPoints = 0,
    this.lifetimeRedeemedPoints = 0,
    this.pointsPerRupee = 10,
    this.pointsToInrRate = 0.10,
    this.currencyCode = 'INR',
    this.tokenId,
    this.tokenCode,
    this.qrPayload,
    this.tokenPurpose,
    this.allowDeduction = false,
    this.tokenCreatedAt,
    this.tokenExpiresAt,
    this.claimId,
    this.claimReference,
    this.claimStatus,
    this.claimAuditStatus,
    this.claimPoints,
    this.claimDiscountAmount,
    this.rewardName = 'Instant POS Bill Discount',
    this.rewardCategory = 'POS Cashback & Bill Offset',
    this.merchantName = 'ShiftEx Partner Counter',
    this.orderReference = '',
    this.auditChecks = const ClaimAuditChecksEntity(),
    this.verificationMethod = 'qr',
  });

  bool get isApproved => approvalStatus.toLowerCase() == 'approved';

  bool get hasClaimToken =>
      tokenId != null && tokenPurpose == 'claim' && allowDeduction;

  bool isClaimExpiredAt([DateTime? now]) {
    if (tokenExpiresAt == null) return false;
    final ref = now ?? DateTime.now();
    return !tokenExpiresAt!.isAfter(ref);
  }

  String formattedRemainingTime([DateTime? now]) {
    if (tokenExpiresAt == null) return '05:00';
    final ref = now ?? DateTime.now();
    final diff = tokenExpiresAt!.difference(ref);
    if (diff.isNegative || diff.inSeconds <= 0) return '00:00';
    final mins = (diff.inSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  String get displayClaimReference =>
      (claimReference != null && claimReference!.trim().isNotEmpty)
      ? claimReference!.trim()
      : (tokenCode ?? 'CLM-0000');

  double get availableRupees => PointsToCashConfigEntity.inrFromPoints(
    points: availablePoints,
    pointsPerRupee: pointsPerRupee,
  );

  double get lockedRupees => PointsToCashConfigEntity.inrFromPoints(
    points: lockedPoints,
    pointsPerRupee: pointsPerRupee,
  );

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'CX';
    if (parts.length == 1) {
      return parts.first.length >= 2
          ? parts.first.substring(0, 2).toUpperCase()
          : parts.first.toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  VerifiedPosCustomerEntity copyWith({
    int? availablePoints,
    int? reservedPoints,
    int? lockedPoints,
    int? lifetimeEarnedPoints,
    int? lifetimeRedeemedPoints,
    int? pointsPerRupee,
    double? pointsToInrRate,
    String? currencyCode,
    ClaimAuditChecksEntity? auditChecks,
  }) {
    return VerifiedPosCustomerEntity(
      customerId: customerId,
      fullName: fullName,
      email: email,
      mobileNumber: mobileNumber,
      approvalStatus: approvalStatus,
      membershipId: membershipId,
      membershipTier: membershipTier,
      availablePoints: availablePoints ?? this.availablePoints,
      reservedPoints: reservedPoints ?? this.reservedPoints,
      lockedPoints: lockedPoints ?? this.lockedPoints,
      lifetimeEarnedPoints: lifetimeEarnedPoints ?? this.lifetimeEarnedPoints,
      lifetimeRedeemedPoints:
          lifetimeRedeemedPoints ?? this.lifetimeRedeemedPoints,
      pointsPerRupee: pointsPerRupee ?? this.pointsPerRupee,
      pointsToInrRate: pointsToInrRate ?? this.pointsToInrRate,
      currencyCode: currencyCode ?? this.currencyCode,
      tokenId: tokenId,
      tokenCode: tokenCode,
      qrPayload: qrPayload,
      tokenPurpose: tokenPurpose,
      allowDeduction: allowDeduction,
      tokenCreatedAt: tokenCreatedAt,
      tokenExpiresAt: tokenExpiresAt,
      claimId: claimId,
      claimReference: claimReference,
      claimStatus: claimStatus,
      claimAuditStatus: claimAuditStatus,
      claimPoints: claimPoints,
      claimDiscountAmount: claimDiscountAmount,
      rewardName: rewardName,
      rewardCategory: rewardCategory,
      merchantName: merchantName,
      orderReference: orderReference,
      auditChecks: auditChecks ?? this.auditChecks,
      verificationMethod: verificationMethod,
    );
  }
}
