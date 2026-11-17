import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/entities/daily_streak_audit_log_entity.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/entities/daily_streak_settings_entity.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/entities/daily_streak_statistics_entity.dart';

abstract class DailyStreakSettingsRepository {
  Future<DailyStreakSettingsEntity> getDailyStreakSettings();

  Future<DailyStreakSettingsEntity> updateDailyStreakSettings({
    required bool enabled,
    required int pointsPerCheckin,
    String? note,
  });

  Future<DailyStreakStatisticsEntity> getDailyStreakStatistics();

  Future<List<DailyStreakAuditLogEntity>> getAuditLogs({int limit = 50});
}
