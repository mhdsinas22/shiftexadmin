import 'package:shiftexadmin/features/dashboard/domain/entities/dashboard_statistics_entity.dart';

class TopPerformingUserEntity {
  final int rank;
  final String customerId;
  final String fullName;
  final String membershipId;
  final String tierBadge;
  final String hubName;
  final int totalPointsEarned;
  final int posScanCount;

  const TopPerformingUserEntity({
    required this.rank,
    required this.customerId,
    required this.fullName,
    required this.membershipId,
    this.tierBadge = 'Elite Tier',
    this.hubName = 'Central Hub',
    required this.totalPointsEarned,
    this.posScanCount = 0,
  });

  bool get isTopEarner => rank == 1;

  String get formattedPoints =>
      '${DashboardStatisticsEntity.formatIndianNumber(totalPointsEarned)} pts';

  String get activitySubtitle =>
      isTopEarner ? 'Top Earner' : '$posScanCount scans';

  String get membershipAndHubLabel => '$membershipId • $hubName';
}
