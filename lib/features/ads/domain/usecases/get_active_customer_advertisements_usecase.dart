import 'package:shiftexadmin/features/ads/domain/entities/advertisement_entity.dart';
import 'package:shiftexadmin/features/ads/domain/repositories/advertisement_repository.dart';

class GetActiveCustomerAdvertisementsUseCase {
  final AdvertisementRepository repository;

  GetActiveCustomerAdvertisementsUseCase({required this.repository});

  Future<List<AdvertisementEntity>> call({
    String? customerId,
    String? sessionId,
  }) {
    return repository.getActiveCustomerAdvertisements(
      customerId: customerId,
      sessionId: sessionId,
    );
  }
}
