class DailyStreakSettingsEntity {
  final String id;
  final bool dailyLoginEnabled;
  final int dailyLoginPoints;
  final int streakDurationDays;
  final int lockDurationDays;
  final int eligibilityScansPerCycle;
  final String timezone;
  final String dailyResetTime;
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
    this.pointsToInrRate = 0.10,
    this.updatedBy,
    required this.updatedAt,
  });

  double equivalentInrFor(int points) => points * pointsToInrRate;

  String get formattedResetHour => '06:00 AM IST (UTC+05:30)';

  String get formattedEligibility => '$eligibilityScansPerCycle check-in / 24h cycle';

  DailyStreakSettingsEntity copyWith({
    String? id,
    bool? dailyLoginEnabled,
    int? dailyLoginPoints,
    int? streakDurationDays,
    int? lockDurationDays,
    int? eligibilityScansPerCycle,
    String? timezone,
    String? dailyResetTime,
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
      pointsToInrRate: pointsToInrRate ?? this.pointsToInrRate,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
