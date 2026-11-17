import 'package:shiftexadmin/features/ads/data/datasources/advertisement_remote_datasource.dart';
import 'package:shiftexadmin/features/ads/data/models/advertisement_model.dart';
import 'package:shiftexadmin/features/ads/domain/entities/advertisement_entity.dart';
import 'package:shiftexadmin/features/ads/domain/entities/advertisement_statistics_entity.dart';
import 'package:shiftexadmin/features/ads/domain/repositories/advertisement_repository.dart';

class AdvertisementRepositoryImpl implements AdvertisementRepository {
  final AdvertisementRemoteDataSource remoteDataSource;

  AdvertisementRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<AdvertisementEntity>> getAdvertisements({String? filter}) async {
    return remoteDataSource.getAdvertisements(filter: filter);
  }

  @override
  Future<AdvertisementStatisticsEntity> getAdvertisementStatistics() async {
    return remoteDataSource.getAdvertisementStatistics();
  }

  @override
  Future<AdvertisementEntity> getAdvertisementById(String id) async {
    return remoteDataSource.getAdvertisementById(id);
  }

  @override
  Future<AdvertisementEntity> createAdvertisement(
    AdvertisementEntity ad, {
    List<int>? imageBytes,
    String? imageFileName,
  }) async {
    final model = AdvertisementModel.fromEntity(ad);
    return remoteDataSource.createAdvertisement(
      model,
      imageBytes: imageBytes,
      imageFileName: imageFileName,
    );
  }

  @override
  Future<AdvertisementEntity> updateAdvertisement(
    AdvertisementEntity ad, {
    List<int>? imageBytes,
    String? imageFileName,
  }) async {
    final model = AdvertisementModel.fromEntity(ad);
    return remoteDataSource.updateAdvertisement(
      model,
      imageBytes: imageBytes,
      imageFileName: imageFileName,
    );
  }

  @override
  Future<void> publishAdvertisement(String id) async {
    return remoteDataSource.publishAdvertisement(id);
  }

  @override
  Future<void> scheduleAdvertisement(
    String id,
    DateTime startAt,
    DateTime endAt,
  ) async {
    return remoteDataSource.scheduleAdvertisement(id, startAt, endAt);
  }

  @override
  Future<void> deactivateAdvertisement(String id) async {
    return remoteDataSource.deactivateAdvertisement(id);
  }

  @override
  Future<void> deleteAdvertisement(String id) async {
    return remoteDataSource.deleteAdvertisement(id);
  }

  @override
  Future<String?> uploadAdvertisementImage(
    List<int> bytes,
    String fileName,
  ) async {
    return remoteDataSource.uploadAdvertisementImage(bytes, fileName);
  }

  @override
  Future<List<AdvertisementEntity>> getActiveCustomerAdvertisements({
    String? customerId,
    String? sessionId,
  }) async {
    return remoteDataSource.getActiveCustomerAdvertisements(
      customerId: customerId,
      sessionId: sessionId,
    );
  }

  @override
  Future<void> trackEvent({
    required String advertisementId,
    required String eventType,
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) async {
    return remoteDataSource.trackEvent(
      advertisementId: advertisementId,
      eventType: eventType,
      sessionId: sessionId,
      metadata: metadata,
    );
  }
}
