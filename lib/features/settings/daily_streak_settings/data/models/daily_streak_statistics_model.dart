import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/entities/daily_streak_statistics_entity.dart';

class DailyStreakStatisticsModel extends DailyStreakStatisticsEntity {
  const DailyStreakStatisticsModel({
    required super.totalPointsDistributed,
    required super.distributedPoints30d,
    required super.activeStreakers,
    required super.completionRate7d,
    super.completedStreaks30d,
    super.totalCheckinsCount,
    super.analyticsAvailable,
    super.currentCycleDate,
  });

  factory DailyStreakStatisticsModel.fromJson(Map<String, dynamic> json) {
    final rawRate = json['completion_rate_7d'];
    final double completionRate = rawRate is num
        ? rawRate.toDouble()
        : (double.tryParse(rawRate?.toString() ?? '') ?? 0.0);

    return DailyStreakStatisticsModel(
      totalPointsDistributed:
          (json['total_points_distributed'] as num?)?.toInt() ?? 0,
      distributedPoints30d:
          (json['distributed_points_30d'] as num?)?.toInt() ?? 0,
      activeStreakers: (json['active_streakers'] as num?)?.toInt() ?? 0,
      completionRate7d: completionRate,
      completedStreaks30d:
          (json['completed_streaks_30d'] as num?)?.toInt() ?? 0,
      totalCheckinsCount: (json['total_checkins_count'] as num?)?.toInt() ?? 0,
      analyticsAvailable: json['analytics_available'] as bool? ?? false,
      currentCycleDate: json['current_cycle_date'] != null
          ? DateTime.tryParse(json['current_cycle_date'].toString())
          : null,
    );
  }
}
