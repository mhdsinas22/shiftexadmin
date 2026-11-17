import 'package:shiftexadmin/features/ads/data/models/advertisement_model.dart';
import 'package:shiftexadmin/features/ads/data/models/advertisement_statistics_model.dart';

abstract class AdvertisementRemoteDataSource {
  Future<List<AdvertisementModel>> getAdvertisements({String? filter});

  Future<AdvertisementStatisticsModel> getAdvertisementStatistics();

  Future<AdvertisementModel> getAdvertisementById(String id);

  Future<AdvertisementModel> createAdvertisement(
    AdvertisementModel ad, {
    List<int>? imageBytes,
    String? imageFileName,
  });

  Future<AdvertisementModel> updateAdvertisement(
    AdvertisementModel ad, {
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

  Future<List<AdvertisementModel>> getActiveCustomerAdvertisements({
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
