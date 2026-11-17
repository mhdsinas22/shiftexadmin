import 'package:shiftexadmin/features/settings/daily_streak_settings/data/datasources/daily_streak_settings_remote_datasource.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/entities/daily_streak_audit_log_entity.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/entities/daily_streak_settings_entity.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/entities/daily_streak_statistics_entity.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/repositories/daily_streak_settings_repository.dart';

class DailyStreakSettingsRepositoryImpl
    implements DailyStreakSettingsRepository {
  final DailyStreakSettingsRemoteDataSource remoteDataSource;

  DailyStreakSettingsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<DailyStreakSettingsEntity> getDailyStreakSettings() {
    return remoteDataSource.getDailyStreakSettings();
  }

  @override
  Future<DailyStreakSettingsEntity> updateDailyStreakSettings({
    required bool enabled,
    required int pointsPerCheckin,
    String? note,
  }) {
    return remoteDataSource.updateDailyStreakSettings(
      enabled: enabled,
      pointsPerCheckin: pointsPerCheckin,
      note: note,
    );
  }

  @override
  Future<DailyStreakStatisticsEntity> getDailyStreakStatistics() {
    return remoteDataSource.getDailyStreakStatistics();
  }

  @override
  Future<List<DailyStreakAuditLogEntity>> getAuditLogs({int limit = 50}) {
    return remoteDataSource.getAuditLogs(limit: limit);
  }
}
