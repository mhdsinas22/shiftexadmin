import 'package:shiftexadmin/features/scan_pos/data/datasources/scan_pos_remote_datasource.dart';
import 'package:shiftexadmin/features/scan_pos/domain/entities/pos_allocation_result_entity.dart';
import 'package:shiftexadmin/features/scan_pos/domain/entities/pos_transaction_entity.dart';
import 'package:shiftexadmin/features/scan_pos/domain/entities/verified_pos_customer_entity.dart';
import 'package:shiftexadmin/features/scan_pos/domain/repositories/scan_pos_repository.dart';

class ScanPosRepositoryImpl implements ScanPosRepository {
  final ScanPosRemoteDataSource remoteDataSource;

  ScanPosRepositoryImpl({required this.remoteDataSource});

  @override
  Future<VerifiedPosCustomerEntity> verifyCustomerQr({
    required String qrInput,
    required ScanPosMode mode,
  }) {
    return remoteDataSource.verifyCustomerQr(qrInput: qrInput, mode: mode);
  }

  @override
  Future<List<VerifiedPosCustomerEntity>> searchCustomers({
    required String query,
    int limit = 10,
  }) {
    return remoteDataSource.searchCustomers(query: query, limit: limit);
  }

  @override
  Future<VerifiedPosCustomerEntity> getCustomerWallet({
    required String customerId,
  }) {
    return remoteDataSource.getCustomerWallet(customerId: customerId);
  }

  @override
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
  }) {
    return remoteDataSource.allocatePoints(
      customerId: customerId,
      instantPoints: instantPoints,
      futurePoints: futurePoints,
      billNumber: billNumber,
      branchName: branchName,
      tokenId: tokenId,
      idempotencyKey: idempotencyKey,
      unlockDays: unlockDays,
      expiryDays: expiryDays,
    );
  }

  @override
  Future<PosClaimRedemptionResultEntity> redeemClaimQr({
    required String tokenId,
    required int redeemPoints,
    required String billNumber,
    required String branchName,
    required String idempotencyKey,
  }) {
    return remoteDataSource.redeemClaimQr(
      tokenId: tokenId,
      redeemPoints: redeemPoints,
      billNumber: billNumber,
      branchName: branchName,
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  Future<List<PosTransactionEntity>> getRecentTransactions({
    int limit = 15,
    int offset = 0,
  }) {
    return remoteDataSource.getRecentTransactions(limit: limit, offset: offset);
  }
}
