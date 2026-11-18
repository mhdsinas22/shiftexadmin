import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_permission.dart';

abstract class AdminAccessEvent {
  const AdminAccessEvent();
}

class LoadAdminAccessRequested extends AdminAccessEvent {
  const LoadAdminAccessRequested();
}

class RefreshAdminAccessRequested extends AdminAccessEvent {
  const RefreshAdminAccessRequested();
}

class CreateAdminAccountRequested extends AdminAccessEvent {
  final String fullName;
  final String email;
  final String password;
  final String confirmPassword;
  final AdminRoleType role;
  final String terminalAssignment;
  final List<String> permissions;

  const CreateAdminAccountRequested({
    required this.fullName,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.role,
    required this.terminalAssignment,
    required this.permissions,
  });
}

class UpdateAdminOperatorPermissionsRequested extends AdminAccessEvent {
  final String targetUserId;
  final AdminRoleType role;
  final String terminalAssignment;
  final List<String> permissions;
  final String status;

  const UpdateAdminOperatorPermissionsRequested({
    required this.targetUserId,
    required this.role,
    required this.terminalAssignment,
    required this.permissions,
    this.status = 'active',
  });
}
