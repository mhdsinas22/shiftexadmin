import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_access_audit_log_entity.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_operator_entity.dart';

enum AdminAccessStatus { initial, loading, loaded, submitting, error }

class AdminAccessState {
  final AdminAccessStatus status;
  final AdminOperatorEntity? currentAdmin;
  final int operatorsCount;
  final List<AdminOperatorEntity> operators;
  final List<AdminAccessAuditLogEntity> auditLogs;
  final String errorMessage;
  final String? successMessage;
  final bool hasLoadedOnce;

  const AdminAccessState({
    this.status = AdminAccessStatus.initial,
    this.currentAdmin,
    this.operatorsCount = 0,
    this.operators = const [],
    this.auditLogs = const [],
    this.errorMessage = '',
    this.successMessage,
    this.hasLoadedOnce = false,
  });

  bool get canCreateAdminAccount =>
      currentAdmin?.canCreateAdminAccount ?? false;

  bool get canManageAdmins => currentAdmin?.canManageAdmins ?? false;

  AdminAccessState copyWith({
    AdminAccessStatus? status,
    AdminOperatorEntity? currentAdmin,
    int? operatorsCount,
    List<AdminOperatorEntity>? operators,
    List<AdminAccessAuditLogEntity>? auditLogs,
    String? errorMessage,
    String? successMessage,
    bool? hasLoadedOnce,
    bool clearSuccessMessage = false,
  }) {
    return AdminAccessState(
      status: status ?? this.status,
      currentAdmin: currentAdmin ?? this.currentAdmin,
      operatorsCount: operatorsCount ?? this.operatorsCount,
      operators: operators ?? this.operators,
      auditLogs: auditLogs ?? this.auditLogs,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
    );
  }
}
