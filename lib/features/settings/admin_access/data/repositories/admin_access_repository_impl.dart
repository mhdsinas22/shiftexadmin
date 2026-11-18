import 'dart:async';
import 'package:shiftexadmin/features/settings/admin_access/data/datasources/admin_access_remote_datasource.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_access_overview_entity.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_operator_entity.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_permission.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/repositories/admin_access_repository.dart';

class AdminAccessRepositoryImpl implements AdminAccessRepository {
  final AdminAccessRemoteDataSource remoteDataSource;
  final StreamController<AdminOperatorEntity?> _currentAdminController =
      StreamController<AdminOperatorEntity?>.broadcast();

  AdminOperatorEntity? _cachedCurrentAdmin;

  AdminAccessRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<AdminOperatorEntity?> get currentAdminStream =>
      _currentAdminController.stream;

  @override
  AdminOperatorEntity? get cachedCurrentAdmin => _cachedCurrentAdmin;

  @override
  Future<AdminAccessOverviewEntity> getAdminAccessOverview() async {
    final overview = await remoteDataSource.getAdminAccessOverview();
    _cachedCurrentAdmin = overview.currentAdmin;
    _currentAdminController.add(overview.currentAdmin);
    return overview;
  }

  @override
  Future<AdminOperatorEntity> createAdminAccount({
    required String fullName,
    required String email,
    required String password,
    required AdminRoleType role,
    required String terminalAssignment,
    required List<String> permissions,
  }) {
    return remoteDataSource.createAdminAccount(
      fullName: fullName,
      email: email,
      password: password,
      role: role,
      terminalAssignment: terminalAssignment,
      permissions: permissions,
    );
  }

  @override
  Future<AdminOperatorEntity> updateOperatorPermissions({
    required String targetUserId,
    required AdminRoleType role,
    required String terminalAssignment,
    required List<String> permissions,
    String status = 'active',
  }) async {
    final updated = await remoteDataSource.updateOperatorPermissions(
      targetUserId: targetUserId,
      role: role,
      terminalAssignment: terminalAssignment,
      permissions: permissions,
      status: status,
    );
    if (_cachedCurrentAdmin?.userId == updated.userId) {
      _cachedCurrentAdmin = updated;
      _currentAdminController.add(updated);
    }
    return updated;
  }
}
