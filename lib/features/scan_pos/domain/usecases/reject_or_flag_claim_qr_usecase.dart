import 'package:shiftexadmin/features/scan_pos/domain/entities/pos_allocation_result_entity.dart';
import 'package:shiftexadmin/features/scan_pos/domain/repositories/scan_pos_repository.dart';

class RejectOrFlagClaimQrUseCase {
  final ScanPosRepository repository;

  const RejectOrFlagClaimQrUseCase(this.repository);

  Future<PosClaimRejectOrFlagResultEntity> call({
    required String tokenId,
    required String action,
    required String reason,
    String branchName = 'Counter #1 POS',
  }) {
    final cleanToken = tokenId.trim();
    final cleanAction = action.trim().toLowerCase();
    final cleanReason = reason.trim();

    if (cleanToken.isEmpty) {
      throw ArgumentError('Claim QR token ID is required.');
    }
    if (cleanAction != 'reject' && cleanAction != 'flag') {
      throw ArgumentError('Action must be reject or flag.');
    }
    if (cleanReason.length < 3) {
      throw ArgumentError('Please enter a reason (at least 3 characters).');
    }

    return repository.rejectOrFlagClaimQr(
      tokenId: cleanToken,
      action: cleanAction,
      reason: cleanReason,
      branchName: branchName.trim().isNotEmpty
          ? branchName.trim()
          : 'Counter #1 POS',
    );
  }
}
