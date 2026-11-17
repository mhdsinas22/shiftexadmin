import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/entities/daily_streak_audit_log_entity.dart';

class DailyStreakAuditLogModel extends DailyStreakAuditLogEntity {
  const DailyStreakAuditLogModel({
    required super.id,
    required super.settingKey,
    super.previousEnabled,
    required super.newEnabled,
    super.previousPoints,
    required super.newPoints,
    super.changedBy,
    required super.changedByEmail,
    super.note,
    required super.createdAt,
  });

  factory DailyStreakAuditLogModel.fromJson(Map<String, dynamic> json) {
    return DailyStreakAuditLogModel(
      id: json['id']?.toString() ?? '',
      settingKey: json['setting_key']?.toString() ?? 'daily_login_streak',
      previousEnabled: json['previous_enabled'] as bool?,
      newEnabled: json['new_enabled'] as bool? ?? true,
      previousPoints: (json['previous_points'] as num?)?.toInt(),
      newPoints: (json['new_points'] as num?)?.toInt() ?? 0,
      changedBy: json['changed_by']?.toString(),
      changedByEmail: json['changed_by_email']?.toString() ?? 'admin',
      note: json['note']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
