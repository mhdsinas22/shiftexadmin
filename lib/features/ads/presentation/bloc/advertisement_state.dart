import 'package:shiftexadmin/features/ads/domain/entities/advertisement_entity.dart';
import 'package:shiftexadmin/features/ads/domain/entities/advertisement_statistics_entity.dart';

enum AdvertisementStatus {
  initial,
  loading,
  loaded,
  submitting,
  publishing,
  scheduling,
  deactivating,
  deleting,
  error,
}

class AdvertisementState {
  final AdvertisementStatus status;
  final List<AdvertisementEntity> advertisements;
  final List<AdvertisementEntity> allAdvertisements;
  final AdvertisementStatisticsEntity statistics;
  final String selectedFilter;
  final AdvertisementEntity? selectedAd;
  final bool isQuickCreateExpanded;
  final String errorMessage;
  final String? successMessage;
  final bool hasLoadedOnce;

  const AdvertisementState({
    this.status = AdvertisementStatus.initial,
    this.advertisements = const [],
    this.allAdvertisements = const [],
    this.statistics = const AdvertisementStatisticsEntity(
      totalAds: 0,
      activeCount: 0,
      scheduledCount: 0,
      endedAndDraftCount: 0,
    ),
    this.selectedFilter = 'all',
    this.selectedAd,
    this.isQuickCreateExpanded = false,
    this.errorMessage = '',
    this.successMessage,
    this.hasLoadedOnce = false,
  });

  AdvertisementState copyWith({
    AdvertisementStatus? status,
    List<AdvertisementEntity>? advertisements,
    List<AdvertisementEntity>? allAdvertisements,
    AdvertisementStatisticsEntity? statistics,
    String? selectedFilter,
    AdvertisementEntity? selectedAd,
    bool? isQuickCreateExpanded,
    String? errorMessage,
    String? successMessage,
    bool? hasLoadedOnce,
    bool clearSelectedAd = false,
    bool clearSuccessMessage = false,
  }) {
    return AdvertisementState(
      status: status ?? this.status,
      advertisements: advertisements ?? this.advertisements,
      allAdvertisements: allAdvertisements ?? this.allAdvertisements,
      statistics: statistics ?? this.statistics,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      selectedAd:
          clearSelectedAd ? null : (selectedAd ?? this.selectedAd),
      isQuickCreateExpanded:
          isQuickCreateExpanded ?? this.isQuickCreateExpanded,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
    );
  }
}
