import 'package:shiftexadmin/features/dashboard/domain/entities/pending_claim_item_entity.dart';

class PendingClaimItemModel extends PendingClaimItemEntity {
  const PendingClaimItemModel({
    required super.id,
    super.qrTokenId,
    required super.claimReference,
    required super.qrPayload,
    required super.userId,
    required super.customerName,
    required super.membershipId,
    super.merchantCounter,
    super.statusSubtitle,
    required super.points,
    super.pointsToInrRate,
    required super.discountAmount,
    super.status,
    required super.expiresAt,
    required super.createdAt,
  });

  factory PendingClaimItemModel.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final expiresAt = json['expires_at'] != null
        ? (DateTime.tryParse(json['expires_at'].toString())?.toLocal() ??
              now.add(const Duration(minutes: 5)))
        : now.add(const Duration(minutes: 5));
    final createdAt = json['created_at'] != null
        ? (DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? now)
        : now;

    final rawPoints = json['points'];
    final int points = rawPoints is num
        ? rawPoints.toInt()
        : (int.tryParse(rawPoints?.toString() ?? '') ?? 0);

    final rawRate = json['points_to_inr_rate'];
    final double rate = rawRate is num
        ? rawRate.toDouble()
        : (double.tryParse(rawRate?.toString() ?? '') ?? 0.10);

    final rawDiscount = json['discount_amount'];
    final double discount = rawDiscount is num
        ? rawDiscount.toDouble()
        : (double.tryParse(rawDiscount?.toString() ?? '') ?? (points * rate));

    final claimRef = json['claim_reference']?.toString() ?? 'CLM-0000';

    return PendingClaimItemModel(
      id: json['id']?.toString() ?? '',
      qrTokenId: json['qr_token_id']?.toString(),
      claimReference: claimRef,
      qrPayload: json['qr_payload']?.toString() ?? claimRef,
      userId: json['user_id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? 'SHIIFTEX Member',
      membershipId: json['membership_id']?.toString() ?? 'SHFT-0000',
      merchantCounter:
          json['merchant_counter']?.toString() ?? 'SHIIFTEX POS Counter',
      statusSubtitle:
          json['status_subtitle']?.toString() ?? 'Point deduction verified',
      points: points,
      pointsToInrRate: rate,
      discountAmount: discount,
      status: json['status']?.toString() ?? 'pending',
      expiresAt: expiresAt,
      createdAt: createdAt,
    );
  }
}
