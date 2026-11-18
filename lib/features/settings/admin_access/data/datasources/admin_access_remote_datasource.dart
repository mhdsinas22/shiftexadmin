import 'package:shiftexadmin/features/settings/admin_access/data/models/admin_access_overview_model.dart';
import 'package:shiftexadmin/features/settings/admin_access/data/models/admin_operator_model.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_permission.dart';

abstract class AdminAccessRemoteDataSource {
  Future<AdminAccessOverviewModel> getAdminAccessOverview();

  Future<AdminOperatorModel> createAdminAccount({
    required String fullName,
    required String email,
    required String password,
    required AdminRoleType role,
    required String terminalAssignment,
    required List<String> permissions,
  });

  Future<AdminOperatorModel> updateOperatorPermissions({
    required String targetUserId,
    required AdminRoleType role,
    required String terminalAssignment,
    required List<String> permissions,
    String status = 'active',
  });
}
