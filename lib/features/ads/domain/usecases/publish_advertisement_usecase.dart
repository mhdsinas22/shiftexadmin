import 'package:shiftexadmin/features/ads/domain/repositories/advertisement_repository.dart';

class PublishAdvertisementUseCase {
  final AdvertisementRepository repository;

  PublishAdvertisementUseCase({required this.repository});

  Future<void> call(String id) {
    return repository.publishAdvertisement(id);
  }
}
