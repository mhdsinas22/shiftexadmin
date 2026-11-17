import 'package:shiftexadmin/features/ads/domain/entities/advertisement_entity.dart';

abstract class AdvertisementEvent {
  const AdvertisementEvent();
}

class LoadAdvertisementsEvent extends AdvertisementEvent {
  final String? filter;
  const LoadAdvertisementsEvent({this.filter});
}

class FilterAdvertisementsEvent extends AdvertisementEvent {
  final String filter;
  const FilterAdvertisementsEvent(this.filter);
}

class ToggleQuickCreateEvent extends AdvertisementEvent {
  const ToggleQuickCreateEvent();
}

class CreateAdvertisementEvent extends AdvertisementEvent {
  final AdvertisementEntity advertisement;
  final List<int>? imageBytes;
  final String? imageFileName;

  const CreateAdvertisementEvent({
    required this.advertisement,
    this.imageBytes,
    this.imageFileName,
  });
}

class UpdateAdvertisementEvent extends AdvertisementEvent {
  final AdvertisementEntity advertisement;
  final List<int>? imageBytes;
  final String? imageFileName;

  const UpdateAdvertisementEvent({
    required this.advertisement,
    this.imageBytes,
    this.imageFileName,
  });
}

class PublishAdvertisementEvent extends AdvertisementEvent {
  final String id;
  const PublishAdvertisementEvent(this.id);
}

class ScheduleAdvertisementEvent extends AdvertisementEvent {
  final String id;
  final DateTime startAt;
  final DateTime endAt;

  const ScheduleAdvertisementEvent({
    required this.id,
    required this.startAt,
    required this.endAt,
  });
}

class DeactivateAdvertisementEvent extends AdvertisementEvent {
  final String id;
  const DeactivateAdvertisementEvent(this.id);
}

class DeleteAdvertisementEvent extends AdvertisementEvent {
  final String id;
  const DeleteAdvertisementEvent(this.id);
}

class SelectAdvertisementForPreviewEvent extends AdvertisementEvent {
  final AdvertisementEntity? advertisement;
  const SelectAdvertisementForPreviewEvent(this.advertisement);
}

class TrackAdvertisementEventOccurred extends AdvertisementEvent {
  final String advertisementId;
  final String eventType;
  final String? sessionId;
  final Map<String, dynamic>? metadata;

  const TrackAdvertisementEventOccurred({
    required this.advertisementId,
    required this.eventType,
    this.sessionId,
    this.metadata,
  });
}
