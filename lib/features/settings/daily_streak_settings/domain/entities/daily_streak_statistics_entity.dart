class DailyStreakStatisticsEntity {
  final int totalPointsDistributed;
  final int distributedPoints30d;
  final int activeStreakers;
  final double completionRate7d;
  final int completedStreaks30d;
  final int totalCheckinsCount;
  final bool analyticsAvailable;
  final DateTime? currentCycleDate;

  const DailyStreakStatisticsEntity({
    required this.totalPointsDistributed,
    required this.distributedPoints30d,
    required this.activeStreakers,
    required this.completionRate7d,
    this.completedStreaks30d = 0,
    this.totalCheckinsCount = 0,
    this.analyticsAvailable = false,
    this.currentCycleDate,
  });

  factory DailyStreakStatisticsEntity.empty() {
    return const DailyStreakStatisticsEntity(
      totalPointsDistributed: 0,
      distributedPoints30d: 0,
      activeStreakers: 0,
      completionRate7d: 0.0,
      completedStreaks30d: 0,
      totalCheckinsCount: 0,
      analyticsAvailable: false,
      currentCycleDate: null,
    );
  }
}
