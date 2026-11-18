import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_operator_entity.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_permission.dart';

class AdminOperatorModel extends AdminOperatorEntity {
  const AdminOperatorModel({
    required super.userId,
    required super.fullName,
    required super.email,
    required super.role,
    super.terminalAssignment,
    super.permissionSummary,
    super.badgeLabel,
    super.isKeyMaster,
    super.isCurrentUser,
    super.status,
    super.permissions,
    super.createdBy,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AdminOperatorModel.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final createdAt = json['created_at'] != null
        ? (DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? now)
        : now;
    final updatedAt = json['updated_at'] != null
        ? (DateTime.tryParse(json['updated_at'].toString())?.toLocal() ??
              createdAt)
        : createdAt;

    final role = AdminRoleType.fromString(json['role']?.toString());
    final rawPerms = json['permissions'];
    final List<String> permissions = rawPerms is List
        ? rawPerms.map((e) => e.toString()).toList()
        : role.defaultPermissions;

    final isKeyMaster = json['is_key_master'] as bool? ?? false;

    return AdminOperatorModel(
      userId: json['user_id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? 'Admin Operator',
      email: json['email']?.toString() ?? '',
      role: role,
      terminalAssignment:
          json['terminal_assignment']?.toString() ?? role.defaultTerminal,
      permissionSummary:
          json['permission_summary']?.toString() ?? 'All Permissions',
      badgeLabel: isKeyMaster
          ? 'Key Master'
          : (json['badge_label']?.toString() ?? 'Active'),
      isKeyMaster: isKeyMaster,
      isCurrentUser: json['is_current_user'] as bool? ?? false,
      status: json['status']?.toString() ?? 'active',
      permissions: permissions,
      createdBy: json['created_by']?.toString(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
