import 'package:shiftexadmin/features/ads/domain/repositories/advertisement_repository.dart';

class TrackAdvertisementEventUseCase {
  final AdvertisementRepository repository;

  TrackAdvertisementEventUseCase({required this.repository});

  Future<void> call({
    required String advertisementId,
    required String eventType,
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) {
    return repository.trackEvent(
      advertisementId: advertisementId,
      eventType: eventType,
      sessionId: sessionId,
      metadata: metadata,
    );
  }
}
