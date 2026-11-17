import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/entities/daily_streak_statistics_entity.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/repositories/daily_streak_settings_repository.dart';

class GetDailyStreakStatisticsUseCase {
  final DailyStreakSettingsRepository repository;

  const GetDailyStreakStatisticsUseCase({required this.repository});

  Future<DailyStreakStatisticsEntity> call() {
    return repository.getDailyStreakStatistics();
  }

  Future<DailyStreakStatisticsEntity> execute() => call();
}
