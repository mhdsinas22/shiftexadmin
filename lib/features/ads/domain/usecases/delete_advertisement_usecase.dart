import 'package:shiftexadmin/features/ads/domain/repositories/advertisement_repository.dart';

class DeleteAdvertisementUseCase {
  final AdvertisementRepository repository;

  DeleteAdvertisementUseCase({required this.repository});

  Future<void> call(String id) {
    return repository.deleteAdvertisement(id);
  }
}
