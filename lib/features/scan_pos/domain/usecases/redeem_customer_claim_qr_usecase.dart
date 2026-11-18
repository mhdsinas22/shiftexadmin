import 'package:shiftexadmin/features/scan_pos/domain/entities/pos_allocation_result_entity.dart';
import 'package:shiftexadmin/features/scan_pos/domain/repositories/scan_pos_repository.dart';

class RedeemCustomerClaimQrUseCase {
  final ScanPosRepository repository;

  const RedeemCustomerClaimQrUseCase({required this.repository});

  Future<PosClaimRedemptionResultEntity> call({
    required String tokenId,
    required int redeemPoints,
    required String billNumber,
    required String branchName,
    required String idempotencyKey,
  }) {
    if (tokenId.trim().isEmpty) {
      throw ArgumentError('Claim QR token ID is required.');
    }
    if (redeemPoints <= 0) {
      throw ArgumentError('Redeem points must be greater than 0.');
    }
    if (billNumber.trim().length < 2) {
      throw ArgumentError('Valid bill reference number is required.');
    }
    if (idempotencyKey.trim().isEmpty) {
      throw ArgumentError('Idempotency key is required.');
    }

    return repository.redeemClaimQr(
      tokenId: tokenId,
      redeemPoints: redeemPoints,
      billNumber: billNumber.trim(),
      branchName: branchName.trim().isEmpty ? 'Counter #1 POS' : branchName.trim(),
      idempotencyKey: idempotencyKey.trim(),
    );
  }
}
