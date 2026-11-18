import 'package:shiftexadmin/core/utils/app_logger.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/data/datasources/points_to_cash_remote_datasource.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/data/models/points_to_cash_audit_log_model.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/data/models/points_to_cash_config_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PointsToCashRemoteDataSourceImpl implements PointsToCashRemoteDataSource {
  final SupabaseClient supabaseClient;

  PointsToCashRemoteDataSourceImpl({required this.supabaseClient});

  void _ensureSignedIn() {
    if (supabaseClient.auth.currentUser == null) {
      throw Exception('Unauthorized: Please sign in as an administrator.');
    }
  }

  String _mapPostgrestError(PostgrestException e) {
    final msg = e.message;
    final clean = msg.replaceFirst(
      RegExp(r'^(UNAUTHORIZED|INVALID_RATE|NOT_FOUND|IMMUTABLE_AUDIT):\s*'),
      '',
    );
    return clean.isNotEmpty ? clean : msg;
  }

  @override
  Future<PointsToCashConfigModel> getActiveConfig() async {
    try {
      _ensureSignedIn();
      final response = await supabaseClient.rpc('get_points_to_cash_config');

      if (response is Map) {
        return PointsToCashConfigModel.fromJson(
          Map<String, dynamic>.from(response),
        );
      }
      throw Exception('Invalid valuation configuration response.');
    } on PostgrestException catch (e) {
      AppLogger.error('Error loading points-to-cash config: ${e.message}');
      throw Exception(_mapPostgrestError(e));
    } catch (e) {
      AppLogger.error('Error loading points-to-cash config: $e');
      rethrow;
    }
  }

  @override
  Future<PointsToCashConfigModel> updateConversionRate({
    required int pointsPerRupee,
    String? note,
  }) async {
    try {
      _ensureSignedIn();

      final response = await supabaseClient.rpc(
        'update_points_per_rupee_rate',
        params: {'p_points_per_rupee': pointsPerRupee, 'p_note': note},
      );

      if (response is Map) {
        return PointsToCashConfigModel.fromJson(
          Map<String, dynamic>.from(response),
        );
      }

      return getActiveConfig();
    } on PostgrestException catch (e) {
      AppLogger.error('Rate update rejected by backend: ${e.message}');
      throw Exception(_mapPostgrestError(e));
    } catch (e) {
      AppLogger.error('Error updating points-to-cash rate: $e');
      rethrow;
    }
  }

  @override
  Future<List<PointsToCashAuditLogModel>> getRateHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      _ensureSignedIn();
      final response = await supabaseClient.rpc(
        'get_points_to_cash_rate_history',
        params: {'p_limit': limit, 'p_offset': offset},
      );

      if (response is List) {
        return response
            .whereType<Map>()
            .map(
              (row) => PointsToCashAuditLogModel.fromJson(
                Map<String, dynamic>.from(row),
              ),
            )
            .toList();
      }
      return const [];
    } on PostgrestException catch (e) {
      AppLogger.error('Error fetching points-to-cash history: ${e.message}');
      throw Exception(_mapPostgrestError(e));
    } catch (e) {
      AppLogger.error('Error fetching points-to-cash history: $e');
      rethrow;
    }
  }
}
