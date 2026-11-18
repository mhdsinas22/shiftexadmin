import 'package:shiftexadmin/features/settings/admin_access/data/models/admin_access_audit_log_model.dart';
import 'package:shiftexadmin/features/settings/admin_access/data/models/admin_operator_model.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_access_overview_entity.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_permission.dart';

class AdminAccessOverviewModel extends AdminAccessOverviewEntity {
  const AdminAccessOverviewModel({
    required super.currentAdmin,
    required super.operatorsCount,
    super.operators,
    super.auditLogs,
  });

  factory AdminAccessOverviewModel.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final currentAdminRaw = json['current_admin'];
    final currentAdmin = currentAdminRaw is Map
        ? AdminOperatorModel.fromJson(
            Map<String, dynamic>.from(currentAdminRaw),
          )
        : AdminOperatorModel(
            userId: '',
            fullName: 'ShiftEx Admin',
            email: '',
            role: AdminRoleType.superAdmin,
            isKeyMaster: true,
            isCurrentUser: true,
            permissions: AdminPermission.allPermissions,
            createdAt: now,
            updatedAt: now,
          );

    final operatorsRaw = json['operators'];
    final operators = operatorsRaw is List
        ? operatorsRaw
              .whereType<Map>()
              .map(
                (row) =>
                    AdminOperatorModel.fromJson(Map<String, dynamic>.from(row)),
              )
              .toList()
        : <AdminOperatorModel>[currentAdmin];

    final logsRaw = json['audit_logs'];
    final logs = logsRaw is List
        ? logsRaw
              .whereType<Map>()
              .map(
                (row) => AdminAccessAuditLogModel.fromJson(
                  Map<String, dynamic>.from(row),
                ),
              )
              .toList()
        : const <AdminAccessAuditLogModel>[];

    return AdminAccessOverviewModel(
      currentAdmin: currentAdmin,
      operatorsCount:
          (json['operators_count'] as num?)?.toInt() ?? operators.length,
      operators: operators,
      auditLogs: logs,
    );
  }
}
