import 'package:shiftexadmin/features/scan_pos/domain/entities/pos_allocation_result_entity.dart';
import 'package:shiftexadmin/features/scan_pos/domain/repositories/scan_pos_repository.dart';

class AllocatePosPointsUseCase {
  final ScanPosRepository repository;

  const AllocatePosPointsUseCase({required this.repository});

  Future<PosAllocationResultEntity> call({
    required String customerId,
    required int instantPoints,
    required int futurePoints,
    required String billNumber,
    required String branchName,
    String? tokenId,
    required String idempotencyKey,
    int unlockDays = 7,
    int expiryDays = 365,
  }) {
    if (customerId.trim().isEmpty) {
      throw ArgumentError('Verified customer is required.');
    }
    if (instantPoints < 0 || futurePoints < 0) {
      throw ArgumentError('Points cannot be negative.');
    }
    if (instantPoints + futurePoints <= 0) {
      throw ArgumentError('Allocate at least 1 Instant or Future point.');
    }
    if (billNumber.trim().length < 2) {
      throw ArgumentError('Valid bill reference number is required.');
    }
    if (idempotencyKey.trim().isEmpty) {
      throw ArgumentError('Idempotency key is required.');
    }

    return repository.allocatePoints(
      customerId: customerId,
      instantPoints: instantPoints,
      futurePoints: futurePoints,
      billNumber: billNumber.trim(),
      branchName: branchName.trim().isEmpty ? 'Counter #1 POS' : branchName.trim(),
      tokenId: tokenId,
      idempotencyKey: idempotencyKey.trim(),
      unlockDays: unlockDays,
      expiryDays: expiryDays,
    );
  }
}
