import 'package:shiftexadmin/features/scan_pos/domain/entities/verified_pos_customer_entity.dart';

class VerifiedPosCustomerModel extends VerifiedPosCustomerEntity {
  const VerifiedPosCustomerModel({
    required super.customerId,
    required super.fullName,
    required super.email,
    required super.mobileNumber,
    required super.approvalStatus,
    required super.membershipId,
    super.membershipTier,
    required super.availablePoints,
    required super.lockedPoints,
    super.lifetimeEarnedPoints,
    super.lifetimeRedeemedPoints,
    super.pointsPerRupee,
    super.pointsToInrRate,
    super.currencyCode,
    super.tokenId,
    super.tokenCode,
    super.qrPayload,
    super.tokenPurpose,
    super.allowDeduction,
    super.tokenExpiresAt,
    super.claimPoints,
    super.verificationMethod,
  });

  factory VerifiedPosCustomerModel.fromJson(Map<String, dynamic> json) {
    final rawRate = json['points_to_inr_rate'];
    final double parsedRate = rawRate is num
        ? rawRate.toDouble()
        : (double.tryParse(rawRate?.toString() ?? '') ?? 0.10);

    final rawPtsPerRupee =
        json['points_per_rupee'] ?? json['points_per_currency_unit'];
    int parsedPtsPerRupee;
    if (rawPtsPerRupee is num) {
      parsedPtsPerRupee = rawPtsPerRupee.round();
    } else {
      parsedPtsPerRupee =
          double.tryParse(rawPtsPerRupee?.toString() ?? '')?.round() ??
          (parsedRate > 0 ? (1.0 / parsedRate).round() : 10);
    }
    if (parsedPtsPerRupee <= 0) parsedPtsPerRupee = 10;

    return VerifiedPosCustomerModel(
      customerId: json['customer_id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? 'SHIIFTEX Member',
      email: json['email']?.toString() ?? '',
      mobileNumber: json['mobile_number']?.toString() ?? '',
      approvalStatus: json['approval_status']?.toString() ?? 'pending',
      membershipId: json['membership_id']?.toString() ?? '',
      membershipTier:
          json['membership_tier']?.toString() ?? 'Pebble Black Member',
      availablePoints: (json['available_points'] as num?)?.toInt() ?? 0,
      lockedPoints: (json['locked_points'] as num?)?.toInt() ?? 0,
      lifetimeEarnedPoints:
          (json['lifetime_earned_points'] as num?)?.toInt() ?? 0,
      lifetimeRedeemedPoints:
          (json['lifetime_redeemed_points'] as num?)?.toInt() ?? 0,
      pointsPerRupee: parsedPtsPerRupee,
      pointsToInrRate: parsedRate,
      currencyCode: json['currency_code']?.toString() ?? 'INR',
      tokenId: json['token_id']?.toString(),
      tokenCode: json['token_code']?.toString(),
      qrPayload: json['qr_payload']?.toString(),
      tokenPurpose: json['token_purpose']?.toString(),
      allowDeduction: json['allow_deduction'] as bool? ?? false,
      tokenExpiresAt: json['token_expires_at'] != null
          ? DateTime.tryParse(json['token_expires_at'].toString())
          : null,
      claimPoints: (json['claim_points'] as num?)?.toInt(),
      verificationMethod: json['verification_method']?.toString() ?? 'qr',
    );
  }
}
