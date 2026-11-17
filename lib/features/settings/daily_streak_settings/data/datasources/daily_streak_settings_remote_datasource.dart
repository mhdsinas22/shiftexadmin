import 'package:shiftexadmin/features/settings/daily_streak_settings/data/models/daily_streak_audit_log_model.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/data/models/daily_streak_settings_model.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/data/models/daily_streak_statistics_model.dart';

abstract class DailyStreakSettingsRemoteDataSource {
  Future<DailyStreakSettingsModel> getDailyStreakSettings();

  Future<DailyStreakSettingsModel> updateDailyStreakSettings({
    required bool enabled,
    required int pointsPerCheckin,
    String? note,
  });

  Future<DailyStreakStatisticsModel> getDailyStreakStatistics();

  Future<List<DailyStreakAuditLogModel>> getAuditLogs({int limit = 50});
}
