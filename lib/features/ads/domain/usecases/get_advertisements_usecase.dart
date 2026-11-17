import 'package:shiftexadmin/features/ads/domain/entities/advertisement_entity.dart';
import 'package:shiftexadmin/features/ads/domain/repositories/advertisement_repository.dart';

class GetAdvertisementsUseCase {
  final AdvertisementRepository repository;

  const GetAdvertisementsUseCase({required this.repository});

  Future<List<AdvertisementEntity>> call({String? filter}) {
    return repository.getAdvertisements(filter: filter);
  }

  Future<List<AdvertisementEntity>> execute({String? filter}) {
    return repository.getAdvertisements(filter: filter);
  }
}
