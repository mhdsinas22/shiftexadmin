import 'package:shiftexadmin/features/ads/domain/entities/advertisement_statistics_entity.dart';
import 'package:shiftexadmin/features/ads/domain/repositories/advertisement_repository.dart';

class GetAdvertisementStatisticsUseCase {
  final AdvertisementRepository repository;

  const GetAdvertisementStatisticsUseCase({required this.repository});

  Future<AdvertisementStatisticsEntity> call() {
    return repository.getAdvertisementStatistics();
  }

  Future<AdvertisementStatisticsEntity> execute() {
    return repository.getAdvertisementStatistics();
  }
}
