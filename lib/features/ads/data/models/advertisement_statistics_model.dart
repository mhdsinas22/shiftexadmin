import 'package:shiftexadmin/features/ads/domain/entities/advertisement_entity.dart';
import 'package:shiftexadmin/features/ads/domain/entities/advertisement_statistics_entity.dart';

class AdvertisementStatisticsModel extends AdvertisementStatisticsEntity {
  const AdvertisementStatisticsModel({
    required super.totalAds,
    required super.activeCount,
    required super.scheduledCount,
    required super.endedAndDraftCount,
    super.draftCount,
    super.endedCount,
    super.deactivatedCount,
  });

  factory AdvertisementStatisticsModel.fromList(List<AdvertisementEntity> ads) {
    int active = 0;
    int scheduled = 0;
    int draft = 0;
    int ended = 0;
    int deactivated = 0;

    for (final ad in ads) {
      if (ad.isDeactivated) {
        deactivated++;
      } else if (ad.isDraft) {
        draft++;
      } else if (ad.isActive) {
        active++;
      } else if (ad.isScheduled) {
        scheduled++;
      } else if (ad.isEnded) {
        ended++;
      }
    }

    final int endedAndDraft = draft + ended + deactivated;

    return AdvertisementStatisticsModel(
      totalAds: ads.length,
      activeCount: active,
      scheduledCount: scheduled,
      endedAndDraftCount: endedAndDraft,
      draftCount: draft,
      endedCount: ended,
      deactivatedCount: deactivated,
    );
  }

  factory AdvertisementStatisticsModel.fromJson(Map<String, dynamic> json) {
    final draft = (json['draft_count'] as num?)?.toInt() ?? 0;
    final ended = (json['ended_count'] as num?)?.toInt() ?? 0;
    final deactivated = (json['deactivated_count'] as num?)?.toInt() ?? 0;
    final active = (json['active_count'] as num?)?.toInt() ?? 0;
    final scheduled = (json['scheduled_count'] as num?)?.toInt() ?? 0;
    final total = (json['total_ads'] as num?)?.toInt() ?? (active + scheduled + draft + ended + deactivated);

    return AdvertisementStatisticsModel(
      totalAds: total,
      activeCount: active,
      scheduledCount: scheduled,
      endedAndDraftCount: draft + ended + deactivated,
      draftCount: draft,
      endedCount: ended,
      deactivatedCount: deactivated,
    );
  }
}
