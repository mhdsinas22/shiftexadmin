import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_access_audit_log_entity.dart';

class AdminAccessAuditLogModel extends AdminAccessAuditLogEntity {
  const AdminAccessAuditLogModel({
    required super.id,
    super.actorUserId,
    super.actorEmail,
    super.targetUserId,
    super.targetEmail,
    required super.action,
    super.previousRole,
    super.newRole,
    super.previousPermissions,
    super.newPermissions,
    super.note,
    required super.createdAt,
  });

  factory AdminAccessAuditLogModel.fromJson(Map<String, dynamic> json) {
    final prevPermsRaw = json['previous_permissions'];
    final newPermsRaw = json['new_permissions'];

    return AdminAccessAuditLogModel(
      id: json['id']?.toString() ?? '',
      actorUserId: json['actor_user_id']?.toString(),
      actorEmail: json['actor_email']?.toString() ?? '',
      targetUserId: json['target_user_id']?.toString(),
      targetEmail: json['target_email']?.toString() ?? '',
      action: json['action']?.toString() ?? 'UPDATE_ADMIN_PERMISSIONS',
      previousRole: json['previous_role']?.toString(),
      newRole: json['new_role']?.toString(),
      previousPermissions: prevPermsRaw is List
          ? prevPermsRaw.map((e) => e.toString()).toList()
          : const [],
      newPermissions: newPermsRaw is List
          ? newPermsRaw.map((e) => e.toString()).toList()
          : const [],
      note: json['note']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString())?.toLocal() ??
                DateTime.now())
          : DateTime.now(),
    );
  }
}
