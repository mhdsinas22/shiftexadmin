import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/entities/daily_streak_audit_log_entity.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/repositories/daily_streak_settings_repository.dart';

class GetDailyStreakAuditLogsUseCase {
  final DailyStreakSettingsRepository repository;

  const GetDailyStreakAuditLogsUseCase({required this.repository});

  Future<List<DailyStreakAuditLogEntity>> call({int limit = 50}) {
    return repository.getAuditLogs(limit: limit);
  }

  Future<List<DailyStreakAuditLogEntity>> execute({int limit = 50}) =>
      call(limit: limit);
}
