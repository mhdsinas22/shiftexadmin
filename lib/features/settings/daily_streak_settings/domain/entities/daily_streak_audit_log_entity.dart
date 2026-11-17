class DailyStreakAuditLogEntity {
  final String id;
  final String settingKey;
  final bool? previousEnabled;
  final bool newEnabled;
  final int? previousPoints;
  final int newPoints;
  final String? changedBy;
  final String changedByEmail;
  final String? note;
  final DateTime createdAt;

  const DailyStreakAuditLogEntity({
    required this.id,
    required this.settingKey,
    this.previousEnabled,
    required this.newEnabled,
    this.previousPoints,
    required this.newPoints,
    this.changedBy,
    required this.changedByEmail,
    this.note,
    required this.createdAt,
  });
}
