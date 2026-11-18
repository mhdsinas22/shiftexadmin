import 'package:shiftexadmin/features/dashboard/domain/entities/top_performing_user_entity.dart';

class TopPerformingUserModel extends TopPerformingUserEntity {
  const TopPerformingUserModel({
    required super.rank,
    required super.customerId,
    required super.fullName,
    required super.membershipId,
    super.tierBadge,
    super.hubName,
    required super.totalPointsEarned,
    super.posScanCount,
  });

  factory TopPerformingUserModel.fromJson(Map<String, dynamic> json) {
    final rawRank = json['rank'];
    final int rank = rawRank is num
        ? rawRank.toInt()
        : (int.tryParse(rawRank?.toString() ?? '') ?? 1);

    final rawPts = json['total_points_earned'];
    final int totalPts = rawPts is num
        ? rawPts.toInt()
        : (int.tryParse(rawPts?.toString() ?? '') ?? 0);

    final rawScans = json['pos_scan_count'];
    final int scans = rawScans is num
        ? rawScans.toInt()
        : (int.tryParse(rawScans?.toString() ?? '') ?? 0);

    return TopPerformingUserModel(
      rank: rank,
      customerId: json['customer_id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? 'SHIIFTEX Member',
      membershipId: json['membership_id']?.toString() ?? 'SHFT-0000',
      tierBadge: json['tier_badge']?.toString() ?? 'Elite Tier',
      hubName: json['hub_name']?.toString() ?? 'Central Hub',
      totalPointsEarned: totalPts,
      posScanCount: scans,
    );
  }
}
