import 'package:shiftexadmin/features/scan_pos/domain/entities/verified_pos_customer_entity.dart';
import 'package:shiftexadmin/features/scan_pos/domain/repositories/scan_pos_repository.dart';

class GetPosCustomerWalletUseCase {
  final ScanPosRepository repository;

  const GetPosCustomerWalletUseCase({required this.repository});

  Future<VerifiedPosCustomerEntity> call({required String customerId}) {
    final trimmed = customerId.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Customer ID is required to verify wallet balance.');
    }
    return repository.getCustomerWallet(customerId: trimmed);
  }
}
