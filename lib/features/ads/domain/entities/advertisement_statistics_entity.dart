class AdvertisementStatisticsEntity {
  final int totalAds;
  final int activeCount;
  final int scheduledCount;
  final int endedAndDraftCount;
  final int draftCount;
  final int endedCount;
  final int deactivatedCount;

  const AdvertisementStatisticsEntity({
    required this.totalAds,
    required this.activeCount,
    required this.scheduledCount,
    required this.endedAndDraftCount,
    this.draftCount = 0,
    this.endedCount = 0,
    this.deactivatedCount = 0,
  });

  factory AdvertisementStatisticsEntity.empty() {
    return const AdvertisementStatisticsEntity(
      totalAds: 0,
      activeCount: 0,
      scheduledCount: 0,
      endedAndDraftCount: 0,
      draftCount: 0,
      endedCount: 0,
      deactivatedCount: 0,
    );
  }
}
