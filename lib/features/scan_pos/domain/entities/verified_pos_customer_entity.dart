import 'package:shiftexadmin/features/settings/points_to_cash/domain/entities/points_to_cash_config_entity.dart';

enum ScanPosMode { giveReward, verifyClaim }

class VerifiedPosCustomerEntity {
  final String customerId;
  final String fullName;
  final String email;
  final String mobileNumber;
  final String approvalStatus;
  final String membershipId;
  final String membershipTier;
  final int availablePoints;
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
  final DateTime? tokenExpiresAt;
  final int? claimPoints;
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
    this.tokenExpiresAt,
    this.claimPoints,
    this.verificationMethod = 'qr',
  });

  bool get isApproved => approvalStatus.toLowerCase() == 'approved';

  bool get hasClaimToken =>
      tokenId != null && tokenPurpose == 'claim' && allowDeduction;

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
    int? lockedPoints,
    int? lifetimeEarnedPoints,
    int? lifetimeRedeemedPoints,
    int? pointsPerRupee,
    double? pointsToInrRate,
    String? currencyCode,
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
      tokenExpiresAt: tokenExpiresAt,
      claimPoints: claimPoints,
      verificationMethod: verificationMethod,
    );
  }
}
