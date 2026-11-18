import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftexadmin/core/utils/app_logger.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/usecases/create_admin_account_usecase.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/usecases/get_admin_access_overview_usecase.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/usecases/update_admin_operator_permissions_usecase.dart';
import 'package:shiftexadmin/features/settings/admin_access/presentation/bloc/admin_access_event.dart';
import 'package:shiftexadmin/features/settings/admin_access/presentation/bloc/admin_access_state.dart';

class AdminAccessBloc extends Bloc<AdminAccessEvent, AdminAccessState> {
  final GetAdminAccessOverviewUseCase getAdminAccessOverviewUseCase;
  final CreateAdminAccountUseCase createAdminAccountUseCase;
  final UpdateAdminOperatorPermissionsUseCase
  updateAdminOperatorPermissionsUseCase;

  AdminAccessBloc({
    required this.getAdminAccessOverviewUseCase,
    required this.createAdminAccountUseCase,
    required this.updateAdminOperatorPermissionsUseCase,
  }) : super(const AdminAccessState()) {
    on<LoadAdminAccessRequested>(_onLoadAdminAccess);
    on<RefreshAdminAccessRequested>(_onRefreshAdminAccess);
    on<CreateAdminAccountRequested>(_onCreateAdminAccount);
    on<UpdateAdminOperatorPermissionsRequested>(_onUpdateOperatorPermissions);
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
  }

  Future<void> _onLoadAdminAccess(
    LoadAdminAccessRequested event,
    Emitter<AdminAccessState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AdminAccessStatus.loading,
        errorMessage: '',
        clearSuccessMessage: true,
      ),
    );

    try {
      final overview = await getAdminAccessOverviewUseCase();
      emit(
        state.copyWith(
          status: AdminAccessStatus.loaded,
          currentAdmin: overview.currentAdmin,
          operatorsCount: overview.operatorsCount,
          operators: overview.operators,
          auditLogs: overview.auditLogs,
          errorMessage: '',
          hasLoadedOnce: true,
        ),
      );
    } catch (e) {
      AppLogger.error('Error loading Admin Access: $e');
      emit(
        state.copyWith(
          status: AdminAccessStatus.error,
          errorMessage: _cleanError(e),
          hasLoadedOnce: true,
        ),
      );
    }
  }

  Future<void> _onRefreshAdminAccess(
    RefreshAdminAccessRequested event,
    Emitter<AdminAccessState> emit,
  ) async {
    try {
      final overview = await getAdminAccessOverviewUseCase();
      emit(
        state.copyWith(
          status: AdminAccessStatus.loaded,
          currentAdmin: overview.currentAdmin,
          operatorsCount: overview.operatorsCount,
          operators: overview.operators,
          auditLogs: overview.auditLogs,
          errorMessage: '',
          hasLoadedOnce: true,
        ),
      );
    } catch (e) {
      AppLogger.error('Error refreshing Admin Access: $e');
      emit(
        state.copyWith(
          status: AdminAccessStatus.error,
          errorMessage: _cleanError(e),
        ),
      );
    }
  }

  Future<void> _onCreateAdminAccount(
    CreateAdminAccountRequested event,
    Emitter<AdminAccessState> emit,
  ) async {
    if (!state.canCreateAdminAccount) {
      emit(
        state.copyWith(
          status: AdminAccessStatus.error,
          errorMessage:
              'Unauthorized: Only authorized Super Admins can create Admin accounts.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: AdminAccessStatus.submitting,
        errorMessage: '',
        clearSuccessMessage: true,
      ),
    );

    try {
      final created = await createAdminAccountUseCase(
        fullName: event.fullName,
        email: event.email,
        password: event.password,
        confirmPassword: event.confirmPassword,
        role: event.role,
        terminalAssignment: event.terminalAssignment,
        permissions: event.permissions,
      );

      final overview = await getAdminAccessOverviewUseCase();
      emit(
        state.copyWith(
          status: AdminAccessStatus.loaded,
          currentAdmin: overview.currentAdmin,
          operatorsCount: overview.operatorsCount,
          operators: overview.operators,
          auditLogs: overview.auditLogs,
          errorMessage: '',
          successMessage:
              'Admin account created for ${created.fullName} (${created.email}). Ready for immediate login.',
        ),
      );
    } catch (e) {
      AppLogger.error('Error creating admin account: $e');
      emit(
        state.copyWith(
          status: AdminAccessStatus.error,
          errorMessage: _cleanError(e),
        ),
      );
    }
  }

  Future<void> _onUpdateOperatorPermissions(
    UpdateAdminOperatorPermissionsRequested event,
    Emitter<AdminAccessState> emit,
  ) async {
    if (!state.canManageAdmins) {
      emit(
        state.copyWith(
          status: AdminAccessStatus.error,
          errorMessage:
              'Unauthorized: Only Super Admins can modify operator permissions.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: AdminAccessStatus.submitting,
        errorMessage: '',
        clearSuccessMessage: true,
      ),
    );

    try {
      final updated = await updateAdminOperatorPermissionsUseCase(
        targetUserId: event.targetUserId,
        role: event.role,
        terminalAssignment: event.terminalAssignment,
        permissions: event.permissions,
        status: event.status,
      );

      final overview = await getAdminAccessOverviewUseCase();
      emit(
        state.copyWith(
          status: AdminAccessStatus.loaded,
          currentAdmin: overview.currentAdmin,
          operatorsCount: overview.operatorsCount,
          operators: overview.operators,
          auditLogs: overview.auditLogs,
          errorMessage: '',
          successMessage:
              'Updated permissions for ${updated.fullName} (${updated.role.displayLabel}).',
        ),
      );
    } catch (e) {
      AppLogger.error('Error updating operator permissions: $e');
      emit(
        state.copyWith(
          status: AdminAccessStatus.error,
          errorMessage: _cleanError(e),
        ),
      );
    }
  }
}
