import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_operator_entity.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_permission.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/repositories/admin_access_repository.dart';

class UpdateAdminOperatorPermissionsUseCase {
  final AdminAccessRepository repository;

  const UpdateAdminOperatorPermissionsUseCase(this.repository);

  Future<AdminOperatorEntity> call({
    required String targetUserId,
    required AdminRoleType role,
    required String terminalAssignment,
    required List<String> permissions,
    String status = 'active',
  }) {
    if (targetUserId.trim().isEmpty) {
      throw Exception('Target operator ID is required.');
    }
    if (permissions.isEmpty) {
      throw Exception('Select at least one permission for the operator.');
    }
    return repository.updateOperatorPermissions(
      targetUserId: targetUserId.trim(),
      role: role,
      terminalAssignment: terminalAssignment.trim().isNotEmpty
          ? terminalAssignment.trim()
          : role.defaultTerminal,
      permissions: permissions,
      status: status.trim().toLowerCase(),
    );
  }
}
