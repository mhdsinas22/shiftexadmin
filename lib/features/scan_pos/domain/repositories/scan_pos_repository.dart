import 'package:shiftexadmin/features/scan_pos/domain/entities/pos_allocation_result_entity.dart';
import 'package:shiftexadmin/features/scan_pos/domain/entities/pos_transaction_entity.dart';
import 'package:shiftexadmin/features/scan_pos/domain/entities/verified_pos_customer_entity.dart';

abstract class ScanPosRepository {
  Future<VerifiedPosCustomerEntity> verifyCustomerQr({
    required String qrInput,
    required ScanPosMode mode,
  });

  Future<List<VerifiedPosCustomerEntity>> searchCustomers({
    required String query,
    int limit = 10,
  });

  Future<VerifiedPosCustomerEntity> getCustomerWallet({
    required String customerId,
  });

  Future<PosAllocationResultEntity> allocatePoints({
    required String customerId,
    required int instantPoints,
    required int futurePoints,
    required String billNumber,
    required String branchName,
    String? tokenId,
    required String idempotencyKey,
    int unlockDays = 7,
    int expiryDays = 365,
  });

  Future<PosClaimRedemptionResultEntity> redeemClaimQr({
    required String tokenId,
    required int redeemPoints,
    required String billNumber,
    required String branchName,
    required String idempotencyKey,
  });

  Future<PosClaimRejectOrFlagResultEntity> rejectOrFlagClaimQr({
    required String tokenId,
    required String action,
    required String reason,
    required String branchName,
  });

  Future<List<PosTransactionEntity>> getRecentTransactions({
    int limit = 15,
    int offset = 0,
  });
}
