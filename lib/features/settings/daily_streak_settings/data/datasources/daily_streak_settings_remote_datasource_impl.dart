import 'package:shiftexadmin/core/utils/app_logger.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/data/datasources/daily_streak_settings_remote_datasource.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/data/models/daily_streak_audit_log_model.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/data/models/daily_streak_settings_model.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/data/models/daily_streak_statistics_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DailyStreakSettingsRemoteDataSourceImpl
    implements DailyStreakSettingsRemoteDataSource {
  final SupabaseClient supabaseClient;

  DailyStreakSettingsRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<DailyStreakSettingsModel> getDailyStreakSettings() async {
    try {
      final response = await supabaseClient
          .from('reward_settings')
          .select('*')
          .eq('singleton_key', 'global')
          .maybeSingle();

      if (response == null) {
        final fallback = await supabaseClient
            .from('reward_settings')
            .select('*')
            .limit(1)
            .maybeSingle();

        if (fallback == null) {
          throw Exception(
            'Reward settings configuration row was not found in Supabase.',
          );
        }

        return DailyStreakSettingsModel.fromJson(
          Map<String, dynamic>.from(fallback),
        );
      }

      return DailyStreakSettingsModel.fromJson(
        Map<String, dynamic>.from(response),
      );
    } catch (e) {
      AppLogger.error('Error loading daily streak settings: $e');
      rethrow;
    }
  }

  @override
  Future<DailyStreakSettingsModel> updateDailyStreakSettings({
    required bool enabled,
    required int pointsPerCheckin,
    String? note,
  }) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Unauthorized: Please sign in as an administrator.');
      }

      final response = await supabaseClient.rpc(
        'update_daily_streak_settings',
        params: {
          'p_enabled': enabled,
          'p_points': pointsPerCheckin,
          'p_note': note,
        },
      );

      if (response is Map<String, dynamic>) {
        return DailyStreakSettingsModel.fromJson(response);
      }

      if (response is List && response.isNotEmpty && response.first is Map) {
        return DailyStreakSettingsModel.fromJson(
          Map<String, dynamic>.from(response.first as Map),
        );
      }

      return getDailyStreakSettings();
    } on PostgrestException catch (e) {
      AppLogger.error('Postgrest error updating daily streak settings: ${e.message}');
      if (e.message.contains('UNAUTHORIZED')) {
        throw Exception(
          'Unauthorized: Only authorized administrators can update streak rules.',
        );
      }
      if (e.message.contains('INVALID_POINTS')) {
        throw Exception(
          'Invalid points value: Must be an integer between 1 and 1000.',
        );
      }
      throw Exception('Failed to save streak configuration: ${e.message}');
    } catch (e) {
      AppLogger.error('Error updating daily streak settings: $e');
      rethrow;
    }
  }

  @override
  Future<DailyStreakStatisticsModel> getDailyStreakStatistics() async {
    try {
      final response = await supabaseClient.rpc('get_daily_streak_statistics');

      if (response is List && response.isNotEmpty && response.first is Map) {
        return DailyStreakStatisticsModel.fromJson(
          Map<String, dynamic>.from(response.first as Map),
        );
      }

      if (response is Map) {
        return DailyStreakStatisticsModel.fromJson(
          Map<String, dynamic>.from(response),
        );
      }

      return const DailyStreakStatisticsModel(
        totalPointsDistributed: 0,
        distributedPoints30d: 0,
        activeStreakers: 0,
        completionRate7d: 0.0,
        analyticsAvailable: false,
      );
    } catch (e) {
      AppLogger.warning('Could not fetch daily streak statistics: $e');
      rethrow;
    }
  }

  @override
  Future<List<DailyStreakAuditLogModel>> getAuditLogs({int limit = 50}) async {
    try {
      final response = await supabaseClient
          .from('reward_settings_audit_logs')
          .select('*')
          .eq('setting_key', 'daily_login_streak')
          .order('created_at', ascending: false)
          .limit(limit);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map(
            (row) => DailyStreakAuditLogModel.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching daily streak audit logs: $e');
      rethrow;
    }
  }
}
