class AdminAccessAuditLogEntity {
  final String id;
  final String? actorUserId;
  final String actorEmail;
  final String? targetUserId;
  final String targetEmail;
  final String action;
  final String? previousRole;
  final String? newRole;
  final List<String> previousPermissions;
  final List<String> newPermissions;
  final String note;
  final DateTime createdAt;

  const AdminAccessAuditLogEntity({
    required this.id,
    this.actorUserId,
    this.actorEmail = '',
    this.targetUserId,
    this.targetEmail = '',
    required this.action,
    this.previousRole,
    this.newRole,
    this.previousPermissions = const [],
    this.newPermissions = const [],
    this.note = '',
    required this.createdAt,
  });
}
