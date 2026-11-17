import 'package:shiftexadmin/features/ads/domain/repositories/advertisement_repository.dart';

class ScheduleAdvertisementUseCase {
  final AdvertisementRepository repository;

  ScheduleAdvertisementUseCase({required this.repository});

  Future<void> call(String id, DateTime startAt, DateTime endAt) {
    return repository.scheduleAdvertisement(id, startAt, endAt);
  }
}
