import 'package:shiftexadmin/features/ads/domain/repositories/advertisement_repository.dart';

class DeactivateAdvertisementUseCase {
  final AdvertisementRepository repository;

  DeactivateAdvertisementUseCase({required this.repository});

  Future<void> call(String id) {
    return repository.deactivateAdvertisement(id);
  }
}
