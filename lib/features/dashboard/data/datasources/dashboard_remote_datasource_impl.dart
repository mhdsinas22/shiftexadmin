import 'package:shiftexadmin/core/utils/app_logger.dart';
import 'package:shiftexadmin/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:shiftexadmin/features/dashboard/data/models/dashboard_overview_model.dart';
import 'package:shiftexadmin/features/dashboard/data/models/master_ledger_entry_model.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/master_ledger_entry_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final SupabaseClient supabaseClient;

  DashboardRemoteDataSourceImpl({required this.supabaseClient});

  void _ensureSignedIn() {
    if (supabaseClient.auth.currentUser == null) {
      throw Exception('Unauthorized: Please sign in as an administrator.');
    }
  }

  String _mapPostgrestError(PostgrestException e) {
    final msg = e.message;
    final clean = msg.replaceFirst(
      RegExp(
        r'^(UNAUTHORIZED|UNAUTHENTICATED|INVALID_CATEGORY|INVALID_CUSTOMER):\s*',
      ),
      '',
    );
    return clean.isNotEmpty ? clean : msg;
  }

  @override
  Future<DashboardOverviewModel> getDashboardOverview({
    LedgerCategoryFilter ledgerCategory = LedgerCategoryFilter.all,
  }) async {
    try {
      _ensureSignedIn();
      final response = await supabaseClient.rpc(
        'get_admin_dashboard_overview',
        params: {'p_ledger_category': ledgerCategory.queryKey},
      );

      if (response is Map) {
        return DashboardOverviewModel.fromJson(
          Map<String, dynamic>.from(response),
        );
      }
      throw Exception('Invalid dashboard response from server.');
    } on PostgrestException catch (e) {
      AppLogger.error('Failed to load Admin Dashboard: ${e.message}');
      throw Exception(_mapPostgrestError(e));
    } catch (e) {
      AppLogger.error('Error loading Admin Dashboard: $e');
      rethrow;
    }
  }

  @override
  Future<List<MasterLedgerEntryModel>> getMasterLedger({
    LedgerCategoryFilter category = LedgerCategoryFilter.all,
    String searchQuery = '',
    int limit = 15,
    int offset = 0,
  }) async {
    try {
      _ensureSignedIn();
      final response = await supabaseClient.rpc(
        'get_admin_master_ledger',
        params: {
          'p_category': category.queryKey,
          'p_search': searchQuery.trim(),
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      if (response is List) {
        return response
            .whereType<Map>()
            .map(
              (row) => MasterLedgerEntryModel.fromJson(
                Map<String, dynamic>.from(row),
              ),
            )
            .toList();
      }
      return const [];
    } on PostgrestException catch (e) {
      AppLogger.error('Failed to load Master Ledger: ${e.message}');
      throw Exception(_mapPostgrestError(e));
    } catch (e) {
      AppLogger.error('Error loading Master Ledger: $e');
      rethrow;
    }
  }
}
