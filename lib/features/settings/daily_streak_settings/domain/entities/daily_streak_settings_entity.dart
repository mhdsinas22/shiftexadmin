import 'package:shiftexadmin/features/settings/points_to_cash/domain/entities/points_to_cash_config_entity.dart';

class DailyStreakSettingsEntity {
  final String id;
  final bool dailyLoginEnabled;
  final int dailyLoginPoints;
  final int streakDurationDays;
  final int lockDurationDays;
  final int eligibilityScansPerCycle;
  final String timezone;
  final String dailyResetTime;
  final int? pointsPerRupee;
  final double pointsToInrRate;
  final String? updatedBy;
  final DateTime updatedAt;

  const DailyStreakSettingsEntity({
    required this.id,
    required this.dailyLoginEnabled,
    required this.dailyLoginPoints,
    this.streakDurationDays = 7,
    this.lockDurationDays = 7,
    this.eligibilityScansPerCycle = 1,
    this.timezone = 'Asia/Kolkata',
    this.dailyResetTime = '06:00:00',
    this.pointsPerRupee,
    this.pointsToInrRate = 0.10,
    this.updatedBy,
    required this.updatedAt,
  });

  int get effectivePointsPerRupee {
    if (pointsPerRupee != null && pointsPerRupee! > 0) {
      return pointsPerRupee!;
    }
    if (pointsToInrRate > 0) {
      return (1.0 / pointsToInrRate).round().clamp(1, 10000);
    }
    return 10;
  }

  double equivalentInrFor(int points) => PointsToCashConfigEntity.inrFromPoints(
    points: points,
    pointsPerRupee: effectivePointsPerRupee,
  );

  String get formattedResetHour => '06:00 AM IST (UTC+05:30)';

  String get formattedEligibility =>
      '$eligibilityScansPerCycle check-in / 24h cycle';

  DailyStreakSettingsEntity copyWith({
    String? id,
    bool? dailyLoginEnabled,
    int? dailyLoginPoints,
    int? streakDurationDays,
    int? lockDurationDays,
    int? eligibilityScansPerCycle,
    String? timezone,
    String? dailyResetTime,
    int? pointsPerRupee,
    double? pointsToInrRate,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return DailyStreakSettingsEntity(
      id: id ?? this.id,
      dailyLoginEnabled: dailyLoginEnabled ?? this.dailyLoginEnabled,
      dailyLoginPoints: dailyLoginPoints ?? this.dailyLoginPoints,
      streakDurationDays: streakDurationDays ?? this.streakDurationDays,
      lockDurationDays: lockDurationDays ?? this.lockDurationDays,
      eligibilityScansPerCycle:
          eligibilityScansPerCycle ?? this.eligibilityScansPerCycle,
      timezone: timezone ?? this.timezone,
      dailyResetTime: dailyResetTime ?? this.dailyResetTime,
      pointsPerRupee: pointsPerRupee ?? this.pointsPerRupee,
      pointsToInrRate: pointsToInrRate ?? this.pointsToInrRate,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
