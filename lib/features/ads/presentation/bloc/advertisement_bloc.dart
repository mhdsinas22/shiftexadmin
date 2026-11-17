import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftexadmin/core/utils/app_logger.dart';
import 'package:shiftexadmin/features/ads/data/models/advertisement_statistics_model.dart';
import 'package:shiftexadmin/features/ads/domain/entities/advertisement_entity.dart';
import 'package:shiftexadmin/features/ads/domain/usecases/create_advertisement_usecase.dart';
import 'package:shiftexadmin/features/ads/domain/usecases/deactivate_advertisement_usecase.dart';
import 'package:shiftexadmin/features/ads/domain/usecases/delete_advertisement_usecase.dart';
import 'package:shiftexadmin/features/ads/domain/usecases/get_advertisement_statistics_usecase.dart';
import 'package:shiftexadmin/features/ads/domain/usecases/get_advertisements_usecase.dart';
import 'package:shiftexadmin/features/ads/domain/usecases/publish_advertisement_usecase.dart';
import 'package:shiftexadmin/features/ads/domain/usecases/schedule_advertisement_usecase.dart';
import 'package:shiftexadmin/features/ads/domain/usecases/track_advertisement_event_usecase.dart';
import 'package:shiftexadmin/features/ads/domain/usecases/update_advertisement_usecase.dart';
import 'package:shiftexadmin/features/ads/presentation/bloc/advertisement_event.dart';
import 'package:shiftexadmin/features/ads/presentation/bloc/advertisement_state.dart';

class AdvertisementBloc extends Bloc<AdvertisementEvent, AdvertisementState> {
  final GetAdvertisementsUseCase getAdvertisementsUseCase;
  final GetAdvertisementStatisticsUseCase getAdvertisementStatisticsUseCase;
  final CreateAdvertisementUseCase createAdvertisementUseCase;
  final UpdateAdvertisementUseCase updateAdvertisementUseCase;
  final PublishAdvertisementUseCase publishAdvertisementUseCase;
  final ScheduleAdvertisementUseCase scheduleAdvertisementUseCase;
  final DeactivateAdvertisementUseCase deactivateAdvertisementUseCase;
  final DeleteAdvertisementUseCase deleteAdvertisementUseCase;
  final TrackAdvertisementEventUseCase trackAdvertisementEventUseCase;

  AdvertisementBloc({
    required this.getAdvertisementsUseCase,
    required this.getAdvertisementStatisticsUseCase,
    required this.createAdvertisementUseCase,
    required this.updateAdvertisementUseCase,
    required this.publishAdvertisementUseCase,
    required this.scheduleAdvertisementUseCase,
    required this.deactivateAdvertisementUseCase,
    required this.deleteAdvertisementUseCase,
    required this.trackAdvertisementEventUseCase,
  }) : super(const AdvertisementState()) {
    on<LoadAdvertisementsEvent>(_onLoadAdvertisements);
    on<FilterAdvertisementsEvent>(_onFilterAdvertisements);
    on<ToggleQuickCreateEvent>(_onToggleQuickCreate);
    on<CreateAdvertisementEvent>(_onCreateAdvertisement);
    on<UpdateAdvertisementEvent>(_onUpdateAdvertisement);
    on<PublishAdvertisementEvent>(_onPublishAdvertisement);
    on<ScheduleAdvertisementEvent>(_onScheduleAdvertisement);
    on<DeactivateAdvertisementEvent>(_onDeactivateAdvertisement);
    on<DeleteAdvertisementEvent>(_onDeleteAdvertisement);
    on<SelectAdvertisementForPreviewEvent>(_onSelectAdvertisementForPreview);
    on<TrackAdvertisementEventOccurred>(_onTrackAdvertisementEvent);
  }

  Future<void> _onLoadAdvertisements(
    LoadAdvertisementsEvent event,
    Emitter<AdvertisementState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AdvertisementStatus.loading,
        errorMessage: '',
        clearSuccessMessage: true,
      ),
    );

    try {
      final allAds = await getAdvertisementsUseCase.execute(filter: 'all');
      final stats = AdvertisementStatisticsModel.fromList(allAds);
      final currentFilter = event.filter ?? state.selectedFilter;

      final filteredAds = _filterAds(allAds, currentFilter);

      emit(
        state.copyWith(
          status: AdvertisementStatus.loaded,
          advertisements: filteredAds,
          allAdvertisements: allAds,
          statistics: stats,
          selectedFilter: currentFilter,
          hasLoadedOnce: true,
        ),
      );
    } catch (e) {
      AppLogger.error('Error loading advertisements in bloc: $e');
      emit(
        state.copyWith(
          status: AdvertisementStatus.error,
          errorMessage: 'Failed to load campaigns: ${e.toString()}',
          hasLoadedOnce: true,
        ),
      );
    }
  }

  void _onFilterAdvertisements(
    FilterAdvertisementsEvent event,
    Emitter<AdvertisementState> emit,
  ) {
    final filteredAds = _filterAds(state.allAdvertisements, event.filter);
    emit(
      state.copyWith(selectedFilter: event.filter, advertisements: filteredAds),
    );
  }

  void _onToggleQuickCreate(
    ToggleQuickCreateEvent event,
    Emitter<AdvertisementState> emit,
  ) {
    emit(state.copyWith(isQuickCreateExpanded: !state.isQuickCreateExpanded));
  }

  Future<void> _onCreateAdvertisement(
    CreateAdvertisementEvent event,
    Emitter<AdvertisementState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AdvertisementStatus.submitting,
        errorMessage: '',
        clearSuccessMessage: true,
      ),
    );

    try {
      final newAd = await createAdvertisementUseCase(
        event.advertisement,
        imageBytes: event.imageBytes,
        imageFileName: event.imageFileName,
      );

      final updatedAll = [newAd, ...state.allAdvertisements];
      final stats = AdvertisementStatisticsModel.fromList(updatedAll);
      final filteredAds = _filterAds(updatedAll, state.selectedFilter);

      emit(
        state.copyWith(
          status: AdvertisementStatus.loaded,
          allAdvertisements: updatedAll,
          advertisements: filteredAds,
          statistics: stats,
          isQuickCreateExpanded: false,
          successMessage: 'Campaign "${newAd.title}" created successfully.',
        ),
      );
    } catch (e) {
      AppLogger.error('Error creating campaign: $e');
      emit(
        state.copyWith(
          status: AdvertisementStatus.error,
          errorMessage: 'Failed to create campaign: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onUpdateAdvertisement(
    UpdateAdvertisementEvent event,
    Emitter<AdvertisementState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AdvertisementStatus.submitting,
        errorMessage: '',
        clearSuccessMessage: true,
      ),
    );

    try {
      final updated = await updateAdvertisementUseCase(
        event.advertisement,
        imageBytes: event.imageBytes,
        imageFileName: event.imageFileName,
      );

      final updatedAll = state.allAdvertisements.map((ad) {
        return ad.id == updated.id ? updated : ad;
      }).toList();

      final stats = AdvertisementStatisticsModel.fromList(updatedAll);
      final filteredAds = _filterAds(updatedAll, state.selectedFilter);

      emit(
        state.copyWith(
          status: AdvertisementStatus.loaded,
          allAdvertisements: updatedAll,
          advertisements: filteredAds,
          statistics: stats,
          successMessage: 'Campaign updated successfully.',
        ),
      );
    } catch (e) {
      AppLogger.error('Error updating campaign: $e');
      emit(
        state.copyWith(
          status: AdvertisementStatus.error,
          errorMessage: 'Failed to update campaign: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onPublishAdvertisement(
    PublishAdvertisementEvent event,
    Emitter<AdvertisementState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AdvertisementStatus.publishing,
        errorMessage: '',
        clearSuccessMessage: true,
      ),
    );

    try {
      final now = DateTime.now();
      AdvertisementEntity? existingAd;
      for (final item in state.allAdvertisements) {
        if (item.id == event.id) {
          existingAd = item;
          break;
        }
      }

      DateTime? extendedEndAt;
      DateTime? effectiveStartAt;
      if (existingAd != null && existingAd.endAt.isBefore(now)) {
        effectiveStartAt = existingAd.startAt.isAfter(now)
            ? now
            : existingAd.startAt;
        extendedEndAt = now.add(const Duration(days: 7));
        await scheduleAdvertisementUseCase(
          event.id,
          effectiveStartAt,
          extendedEndAt,
        );
      }

      await publishAdvertisementUseCase(event.id);

      final updatedAll = state.allAdvertisements.map((ad) {
        if (ad.id == event.id) {
          return ad.copyWith(
            status: 'published',
            publishedAt: now,
            updatedAt: now,
            startAt: effectiveStartAt,
            endAt: extendedEndAt,
            clearDeactivatedAt: true,
          );
        }
        return ad;
      }).toList();

      final stats = AdvertisementStatisticsModel.fromList(updatedAll);
      final filteredAds = _filterAds(updatedAll, state.selectedFilter);

      emit(
        state.copyWith(
          status: AdvertisementStatus.loaded,
          allAdvertisements: updatedAll,
          advertisements: filteredAds,
          statistics: stats,
          successMessage: 'Campaign published and is now live!',
        ),
      );
    } catch (e) {
      AppLogger.error('Error publishing campaign: $e');
      emit(
        state.copyWith(
          status: AdvertisementStatus.error,
          errorMessage: 'Failed to publish campaign: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onScheduleAdvertisement(
    ScheduleAdvertisementEvent event,
    Emitter<AdvertisementState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AdvertisementStatus.scheduling,
        errorMessage: '',
        clearSuccessMessage: true,
      ),
    );

    try {
      await scheduleAdvertisementUseCase(event.id, event.startAt, event.endAt);

      final updatedAll = state.allAdvertisements.map((ad) {
        if (ad.id == event.id) {
          return ad.copyWith(
            status: 'published',
            startAt: event.startAt,
            endAt: event.endAt,
            updatedAt: DateTime.now(),
            clearDeactivatedAt: true,
          );
        }
        return ad;
      }).toList();

      final stats = AdvertisementStatisticsModel.fromList(updatedAll);
      final filteredAds = _filterAds(updatedAll, state.selectedFilter);

      emit(
        state.copyWith(
          status: AdvertisementStatus.loaded,
          allAdvertisements: updatedAll,
          advertisements: filteredAds,
          statistics: stats,
          successMessage: 'Campaign successfully scheduled.',
        ),
      );
    } catch (e) {
      AppLogger.error('Error scheduling campaign: $e');
      emit(
        state.copyWith(
          status: AdvertisementStatus.error,
          errorMessage: 'Failed to schedule campaign: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onDeactivateAdvertisement(
    DeactivateAdvertisementEvent event,
    Emitter<AdvertisementState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AdvertisementStatus.deactivating,
        errorMessage: '',
        clearSuccessMessage: true,
      ),
    );

    try {
      await deactivateAdvertisementUseCase(event.id);

      final updatedAll = state.allAdvertisements.map((ad) {
        if (ad.id == event.id) {
          return ad.copyWith(
            status: 'deactivated',
            deactivatedAt: DateTime.now(),
          );
        }
        return ad;
      }).toList();

      final stats = AdvertisementStatisticsModel.fromList(updatedAll);
      final filteredAds = _filterAds(updatedAll, state.selectedFilter);

      emit(
        state.copyWith(
          status: AdvertisementStatus.loaded,
          allAdvertisements: updatedAll,
          advertisements: filteredAds,
          statistics: stats,
          successMessage: 'Campaign has been deactivated.',
        ),
      );
    } catch (e) {
      AppLogger.error('Error deactivating campaign: $e');
      emit(
        state.copyWith(
          status: AdvertisementStatus.error,
          errorMessage: 'Failed to deactivate campaign: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onDeleteAdvertisement(
    DeleteAdvertisementEvent event,
    Emitter<AdvertisementState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AdvertisementStatus.deleting,
        errorMessage: '',
        clearSuccessMessage: true,
      ),
    );

    try {
      await deleteAdvertisementUseCase(event.id);

      final updatedAll = state.allAdvertisements
          .where((ad) => ad.id != event.id)
          .toList();

      final stats = AdvertisementStatisticsModel.fromList(updatedAll);
      final filteredAds = _filterAds(updatedAll, state.selectedFilter);

      emit(
        state.copyWith(
          status: AdvertisementStatus.loaded,
          allAdvertisements: updatedAll,
          advertisements: filteredAds,
          statistics: stats,
          successMessage: 'Campaign removed.',
        ),
      );
    } catch (e) {
      AppLogger.error('Error deleting campaign: $e');
      emit(
        state.copyWith(
          status: AdvertisementStatus.error,
          errorMessage: 'Failed to delete campaign: ${e.toString()}',
        ),
      );
    }
  }

  void _onSelectAdvertisementForPreview(
    SelectAdvertisementForPreviewEvent event,
    Emitter<AdvertisementState> emit,
  ) {
    emit(
      state.copyWith(
        selectedAd: event.advertisement,
        clearSelectedAd: event.advertisement == null,
      ),
    );
  }

  Future<void> _onTrackAdvertisementEvent(
    TrackAdvertisementEventOccurred event,
    Emitter<AdvertisementState> emit,
  ) async {
    try {
      await trackAdvertisementEventUseCase(
        advertisementId: event.advertisementId,
        eventType: event.eventType,
        sessionId: event.sessionId,
        metadata: event.metadata,
      );
    } catch (e) {
      AppLogger.warning(
        'Failed to track advertisement event in background: $e',
      );
    }
  }

  List<AdvertisementEntity> _filterAds(
    List<AdvertisementEntity> list,
    String filter,
  ) {
    final clean = filter.toLowerCase().trim();
    if (clean == 'all' || clean.isEmpty || clean.startsWith('all')) {
      return list;
    }
    return list.where((ad) {
      final eff = ad.effectiveStatus.toLowerCase();
      if (clean.contains('active')) return eff == 'active';
      if (clean.contains('scheduled')) return eff == 'scheduled';
      if (clean.contains('draft')) return eff == 'draft';
      if (clean.contains('ended')) return eff == 'ended';
      if (clean.contains('deactivated')) return eff == 'deactivated';
      return eff == clean;
    }).toList();
  }
}
