import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_permission.dart';

class AdminOperatorEntity {
  final String userId;
  final String fullName;
  final String email;
  final AdminRoleType role;
  final String terminalAssignment;
  final String permissionSummary;
  final String badgeLabel;
  final bool isKeyMaster;
  final bool isCurrentUser;
  final String status;
  final List<String> permissions;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminOperatorEntity({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    this.terminalAssignment = 'ShiftEx Central Control',
    this.permissionSummary = 'All Permissions',
    this.badgeLabel = 'Key Master',
    this.isKeyMaster = false,
    this.isCurrentUser = false,
    this.status = 'active',
    this.permissions = const [],
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status.toLowerCase() == 'active';

  bool hasPermission(String permissionId) {
    if (!isActive) return false;
    if (isKeyMaster || role == AdminRoleType.superAdmin) return true;
    return permissions.contains(permissionId);
  }

  bool get canCreateAdminAccount =>
      isActive &&
      (isKeyMaster ||
          role == AdminRoleType.superAdmin ||
          hasPermission(AdminPermission.adminsManage));

  bool get canManageAdmins => hasPermission(AdminPermission.adminsManage);

  String get displayTitle => isCurrentUser ? '$fullName (You)' : fullName;

  String get displaySubtitle {
    switch (role) {
      case AdminRoleType.superAdmin:
        return 'Super Admin • $permissionSummary';
      case AdminRoleType.storeManager:
        final term = terminalAssignment.trim().isNotEmpty
            ? terminalAssignment.trim()
            : 'Term #02';
        return 'Store Manager • $term';
      case AdminRoleType.auditor:
        final summary = permissionSummary.trim().isNotEmpty
            ? permissionSummary.trim()
            : 'Read-only Ledger';
        return 'Auditor • $summary';
    }
  }

  String get displayRightBadge {
    if (isKeyMaster) return 'Key Master';
    if (!isActive) return status.toUpperCase();
    return badgeLabel.trim().isNotEmpty ? badgeLabel.trim() : 'Active';
  }

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'AD';
    if (parts.length == 1) {
      return parts.first.length >= 2
          ? parts.first.substring(0, 2).toUpperCase()
          : parts.first.toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
