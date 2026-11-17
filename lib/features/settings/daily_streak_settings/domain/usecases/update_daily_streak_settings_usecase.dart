import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/entities/daily_streak_settings_entity.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/repositories/daily_streak_settings_repository.dart';

class UpdateDailyStreakSettingsUseCase {
  final DailyStreakSettingsRepository repository;

  const UpdateDailyStreakSettingsUseCase({required this.repository});

  static const int minPointsPerCheckin = 1;
  static const int maxPointsPerCheckin = 1000;

  Future<DailyStreakSettingsEntity> call({
    required bool enabled,
    required int pointsPerCheckin,
    String? note,
  }) {
    if (pointsPerCheckin < minPointsPerCheckin ||
        pointsPerCheckin > maxPointsPerCheckin) {
      throw ArgumentError(
        'Points per daily check-in must be between $minPointsPerCheckin and $maxPointsPerCheckin.',
      );
    }

    return repository.updateDailyStreakSettings(
      enabled: enabled,
      pointsPerCheckin: pointsPerCheckin,
      note: note,
    );
  }

  Future<DailyStreakSettingsEntity> execute({
    required bool enabled,
    required int pointsPerCheckin,
    String? note,
  }) =>
      call(
        enabled: enabled,
        pointsPerCheckin: pointsPerCheckin,
        note: note,
      );
}
