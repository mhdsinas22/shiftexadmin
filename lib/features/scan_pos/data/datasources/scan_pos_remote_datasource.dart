import 'package:shiftexadmin/features/scan_pos/data/models/pos_allocation_result_model.dart';
import 'package:shiftexadmin/features/scan_pos/data/models/pos_transaction_model.dart';
import 'package:shiftexadmin/features/scan_pos/data/models/verified_pos_customer_model.dart';
import 'package:shiftexadmin/features/scan_pos/domain/entities/verified_pos_customer_entity.dart';

abstract class ScanPosRemoteDataSource {
  Future<VerifiedPosCustomerModel> verifyCustomerQr({
    required String qrInput,
    required ScanPosMode mode,
  });

  Future<List<VerifiedPosCustomerModel>> searchCustomers({
    required String query,
    int limit = 10,
  });

  Future<VerifiedPosCustomerModel> getCustomerWallet({
    required String customerId,
  });

  Future<PosAllocationResultModel> allocatePoints({
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

  Future<PosClaimRedemptionResultModel> redeemClaimQr({
    required String tokenId,
    required int redeemPoints,
    required String billNumber,
    required String branchName,
    required String idempotencyKey,
  });

  Future<List<PosTransactionModel>> getRecentTransactions({
    int limit = 15,
    int offset = 0,
  });
}
