import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/entities/daily_streak_settings_entity.dart';

class DailyStreakSettingsModel extends DailyStreakSettingsEntity {
  const DailyStreakSettingsModel({
    required super.id,
    required super.dailyLoginEnabled,
    required super.dailyLoginPoints,
    super.streakDurationDays,
    super.lockDurationDays,
    super.eligibilityScansPerCycle,
    super.timezone,
    super.dailyResetTime,
    super.pointsToInrRate,
    super.updatedBy,
    required super.updatedAt,
  });

  factory DailyStreakSettingsModel.fromJson(Map<String, dynamic> json) {
    final rawRate = json['points_to_inr_rate'];
    final double parsedRate = rawRate is num
        ? rawRate.toDouble()
        : (double.tryParse(rawRate?.toString() ?? '') ?? 0.10);

    return DailyStreakSettingsModel(
      id: json['id']?.toString() ?? '',
      dailyLoginEnabled: json['daily_login_enabled'] as bool? ?? true,
      dailyLoginPoints: (json['daily_login_points'] as num?)?.toInt() ?? 15,
      streakDurationDays: (json['streak_duration_days'] as num?)?.toInt() ?? 7,
      lockDurationDays: (json['lock_duration_days'] as num?)?.toInt() ?? 7,
      eligibilityScansPerCycle:
          (json['eligibility_scans_per_cycle'] as num?)?.toInt() ?? 1,
      timezone: json['timezone']?.toString() ?? 'Asia/Kolkata',
      dailyResetTime: json['daily_reset_time']?.toString() ?? '06:00:00',
      pointsToInrRate: parsedRate,
      updatedBy: json['updated_by']?.toString(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'daily_login_enabled': dailyLoginEnabled,
      'daily_login_points': dailyLoginPoints,
      'streak_duration_days': streakDurationDays,
      'lock_duration_days': lockDurationDays,
      'eligibility_scans_per_cycle': eligibilityScansPerCycle,
      'timezone': timezone,
      'daily_reset_time': dailyResetTime,
      'points_to_inr_rate': pointsToInrRate,
      'updated_by': updatedBy,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}
