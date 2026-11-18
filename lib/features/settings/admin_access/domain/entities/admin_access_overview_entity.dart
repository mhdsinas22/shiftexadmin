import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_access_audit_log_entity.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_operator_entity.dart';

class AdminAccessOverviewEntity {
  final AdminOperatorEntity currentAdmin;
  final int operatorsCount;
  final List<AdminOperatorEntity> operators;
  final List<AdminAccessAuditLogEntity> auditLogs;

  const AdminAccessOverviewEntity({
    required this.currentAdmin,
    required this.operatorsCount,
    this.operators = const [],
    this.auditLogs = const [],
  });
}
