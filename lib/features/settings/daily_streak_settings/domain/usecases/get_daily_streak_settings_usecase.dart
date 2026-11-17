import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/entities/daily_streak_settings_entity.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/repositories/daily_streak_settings_repository.dart';

class GetDailyStreakSettingsUseCase {
  final DailyStreakSettingsRepository repository;

  const GetDailyStreakSettingsUseCase({required this.repository});

  Future<DailyStreakSettingsEntity> call() {
    return repository.getDailyStreakSettings();
  }

  Future<DailyStreakSettingsEntity> execute() => call();
}
