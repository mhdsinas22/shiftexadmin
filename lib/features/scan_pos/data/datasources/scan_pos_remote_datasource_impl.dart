import 'package:shiftexadmin/core/utils/app_logger.dart';
import 'package:shiftexadmin/features/scan_pos/data/datasources/scan_pos_remote_datasource.dart';
import 'package:shiftexadmin/features/scan_pos/data/models/pos_allocation_result_model.dart';
import 'package:shiftexadmin/features/scan_pos/data/models/pos_transaction_model.dart';
import 'package:shiftexadmin/features/scan_pos/data/models/verified_pos_customer_model.dart';
import 'package:shiftexadmin/features/scan_pos/domain/entities/verified_pos_customer_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScanPosRemoteDataSourceImpl implements ScanPosRemoteDataSource {
  final SupabaseClient supabaseClient;

  ScanPosRemoteDataSourceImpl({required this.supabaseClient});

  void _ensureSignedIn() {
    if (supabaseClient.auth.currentUser == null) {
      throw Exception('Unauthorized: Please sign in as an administrator.');
    }
  }

  String _mapPostgrestError(PostgrestException e) {
    final msg = e.message;
    final clean = msg.replaceFirst(
      RegExp(
        r'^(UNAUTHORIZED|INVALID_QR|WRONG_QR_MODE|QR_REVOKED|QR_ALREADY_USED|QR_EXPIRED|CUSTOMER_NOT_FOUND|CUSTOMER_NOT_APPROVED|DUPLICATE_TRANSACTION|INVALID_AMOUNT|INVALID_BILL|INSUFFICIENT_BALANCE|INVALID_CUSTOMER|WALLET_NOT_FOUND|WALLET_VERIFICATION_FAILED|LEDGER_VERIFICATION_FAILED|ALLOCATION_VERIFICATION_FAILED):\s*',
      ),
      '',
    );
    return clean.isNotEmpty ? clean : msg;
  }

  @override
  Future<VerifiedPosCustomerModel> verifyCustomerQr({
    required String qrInput,
    required ScanPosMode mode,
  }) async {
    try {
      _ensureSignedIn();
      final modeStr =
          mode == ScanPosMode.verifyClaim ? 'verify_claim' : 'give_reward';

      final response = await supabaseClient.rpc(
        'verify_customer_qr_for_pos',
        params: {
          'p_qr_input': qrInput.trim(),
          'p_mode': modeStr,
        },
      );

      if (response is Map) {
        return VerifiedPosCustomerModel.fromJson(
          Map<String, dynamic>.from(response),
        );
      }
      throw Exception('Invalid verification response from server.');
    } on PostgrestException catch (e) {
      AppLogger.warning('QR verification failed: ${e.message}');
      throw Exception(_mapPostgrestError(e));
    } catch (e) {
      AppLogger.error('Error verifying customer QR: $e');
      rethrow;
    }
  }

  @override
  Future<List<VerifiedPosCustomerModel>> searchCustomers({
    required String query,
    int limit = 10,
  }) async {
    try {
      _ensureSignedIn();
      final response = await supabaseClient.rpc(
        'search_pos_customers',
        params: {
          'p_query': query.trim(),
          'p_limit': limit,
        },
      );

      if (response is List) {
        return response
            .whereType<Map>()
            .map(
              (row) => VerifiedPosCustomerModel.fromJson(
                Map<String, dynamic>.from(row),
              ),
            )
            .toList();
      }
      return const [];
    } on PostgrestException catch (e) {
      AppLogger.error('Error searching POS customers: ${e.message}');
      throw Exception(_mapPostgrestError(e));
    } catch (e) {
      AppLogger.error('Error searching POS customers: $e');
      rethrow;
    }
  }

  @override
  Future<VerifiedPosCustomerModel> getCustomerWallet({
    required String customerId,
  }) async {
    try {
      _ensureSignedIn();
      final response = await supabaseClient.rpc(
        'get_pos_customer_wallet',
        params: {
          'p_customer_id': customerId,
        },
      );

      if (response is Map) {
        return VerifiedPosCustomerModel.fromJson(
          Map<String, dynamic>.from(response),
        );
      }
      throw Exception('Invalid wallet response from server.');
    } on PostgrestException catch (e) {
      AppLogger.error('Error refreshing customer POS wallet: ${e.message}');
      throw Exception(_mapPostgrestError(e));
    } catch (e) {
      AppLogger.error('Error refreshing customer POS wallet: $e');
      rethrow;
    }
  }

  @override
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
  }) async {
    try {
      _ensureSignedIn();
      final response = await supabaseClient.rpc(
        'allocate_pos_points',
        params: {
          'p_customer_id': customerId,
          'p_instant_points': instantPoints,
          'p_future_points': futurePoints,
          'p_bill_number': billNumber,
          'p_branch_name': branchName,
          'p_token_id': tokenId,
          'p_idempotency_key': idempotencyKey,
          'p_unlock_days': unlockDays,
          'p_expiry_days': expiryDays,
        },
      );

      if (response is Map) {
        return PosAllocationResultModel.fromJson(
          Map<String, dynamic>.from(response),
        );
      }
      throw Exception('Invalid allocation response from server.');
    } on PostgrestException catch (e) {
      AppLogger.error('Point allocation failed: ${e.message}');
      throw Exception(_mapPostgrestError(e));
    } catch (e) {
      AppLogger.error('Error allocating POS points: $e');
      rethrow;
    }
  }

  @override
  Future<PosClaimRedemptionResultModel> redeemClaimQr({
    required String tokenId,
    required int redeemPoints,
    required String billNumber,
    required String branchName,
    required String idempotencyKey,
  }) async {
    try {
      _ensureSignedIn();
      final response = await supabaseClient.rpc(
        'redeem_customer_claim_qr',
        params: {
          'p_token_id': tokenId,
          'p_redeem_points': redeemPoints,
          'p_bill_number': billNumber,
          'p_branch_name': branchName,
          'p_idempotency_key': idempotencyKey,
        },
      );

      if (response is Map) {
        return PosClaimRedemptionResultModel.fromJson(
          Map<String, dynamic>.from(response),
        );
      }
      throw Exception('Invalid redemption response from server.');
    } on PostgrestException catch (e) {
      AppLogger.error('Claim redemption failed: ${e.message}');
      throw Exception(_mapPostgrestError(e));
    } catch (e) {
      AppLogger.error('Error redeeming claim QR: $e');
      rethrow;
    }
  }

  @override
  Future<List<PosTransactionModel>> getRecentTransactions({
    int limit = 15,
    int offset = 0,
  }) async {
    try {
      _ensureSignedIn();
      final response = await supabaseClient.rpc(
        'get_pos_recent_transactions',
        params: {
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      if (response is List) {
        return response
            .whereType<Map>()
            .map(
              (row) => PosTransactionModel.fromJson(
                Map<String, dynamic>.from(row),
              ),
            )
            .toList();
      }
      return const [];
    } on PostgrestException catch (e) {
      AppLogger.error('Error loading POS transactions: ${e.message}');
      throw Exception(_mapPostgrestError(e));
    } catch (e) {
      AppLogger.error('Error loading POS transactions: $e');
      rethrow;
    }
  }
}
