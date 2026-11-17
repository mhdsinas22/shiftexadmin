import 'package:shiftexadmin/features/ads/domain/entities/advertisement_entity.dart';
import 'package:shiftexadmin/features/ads/domain/repositories/advertisement_repository.dart';

class CreateAdvertisementUseCase {
  final AdvertisementRepository repository;

  CreateAdvertisementUseCase({required this.repository});

  Future<AdvertisementEntity> call(
    AdvertisementEntity advertisement, {
    List<int>? imageBytes,
    String? imageFileName,
  }) {
    return repository.createAdvertisement(
      advertisement,
      imageBytes: imageBytes,
      imageFileName: imageFileName,
    );
  }
}
