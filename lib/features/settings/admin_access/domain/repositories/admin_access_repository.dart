import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_access_overview_entity.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_operator_entity.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_permission.dart';

abstract class AdminAccessRepository {
  Stream<AdminOperatorEntity?> get currentAdminStream;
  AdminOperatorEntity? get cachedCurrentAdmin;

  Future<AdminAccessOverviewEntity> getAdminAccessOverview();

  Future<AdminOperatorEntity> createAdminAccount({
    required String fullName,
    required String email,
    required String password,
    required AdminRoleType role,
    required String terminalAssignment,
    required List<String> permissions,
  });

  Future<AdminOperatorEntity> updateOperatorPermissions({
    required String targetUserId,
    required AdminRoleType role,
    required String terminalAssignment,
    required List<String> permissions,
    String status = 'active',
  });
}
