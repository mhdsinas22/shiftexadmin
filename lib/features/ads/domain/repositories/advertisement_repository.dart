import 'package:shiftexadmin/features/ads/domain/entities/advertisement_entity.dart';
import 'package:shiftexadmin/features/ads/domain/entities/advertisement_statistics_entity.dart';

abstract class AdvertisementRepository {
  Future<List<AdvertisementEntity>> getAdvertisements({String? filter});

  Future<AdvertisementStatisticsEntity> getAdvertisementStatistics();

  Future<AdvertisementEntity> getAdvertisementById(String id);

  Future<AdvertisementEntity> createAdvertisement(
    AdvertisementEntity ad, {
    List<int>? imageBytes,
    String? imageFileName,
  });

  Future<AdvertisementEntity> updateAdvertisement(
    AdvertisementEntity ad, {
    List<int>? imageBytes,
    String? imageFileName,
  });

  Future<void> publishAdvertisement(String id);

  Future<void> scheduleAdvertisement(
    String id,
    DateTime startAt,
    DateTime endAt,
  );

  Future<void> deactivateAdvertisement(String id);

  Future<void> deleteAdvertisement(String id);

  Future<String?> uploadAdvertisementImage(
    List<int> bytes,
    String fileName,
  );

  Future<List<AdvertisementEntity>> getActiveCustomerAdvertisements({
    String? customerId,
    String? sessionId,
  });

  Future<void> trackEvent({
    required String advertisementId,
    required String eventType,
    String? sessionId,
    Map<String, dynamic>? metadata,
  });
}
