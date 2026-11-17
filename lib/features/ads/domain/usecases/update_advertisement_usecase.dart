import 'package:shiftexadmin/features/ads/domain/entities/advertisement_entity.dart';
import 'package:shiftexadmin/features/ads/domain/repositories/advertisement_repository.dart';

class UpdateAdvertisementUseCase {
  final AdvertisementRepository repository;

  UpdateAdvertisementUseCase({required this.repository});

  Future<AdvertisementEntity> call(
    AdvertisementEntity advertisement, {
    List<int>? imageBytes,
    String? imageFileName,
  }) {
    return repository.updateAdvertisement(
      advertisement,
      imageBytes: imageBytes,
      imageFileName: imageFileName,
    );
  }
}
