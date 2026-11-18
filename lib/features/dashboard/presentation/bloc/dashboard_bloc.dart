import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftexadmin/core/utils/app_logger.dart';
import 'package:shiftexadmin/features/dashboard/domain/usecases/get_dashboard_overview_usecase.dart';
import 'package:shiftexadmin/features/dashboard/domain/usecases/get_master_ledger_usecase.dart';
import 'package:shiftexadmin/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:shiftexadmin/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/entities/points_to_cash_config_entity.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/usecases/get_points_to_cash_config_usecase.dart';
import 'package:shiftexadmin/features/user_management/domain/usecases/approve_customer_usecase.dart';
import 'package:shiftexadmin/features/user_management/domain/usecases/reject_customer_usecase.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDashboardOverviewUseCase getDashboardOverviewUseCase;
  final GetMasterLedgerUseCase getMasterLedgerUseCase;
  final ApproveCustomerUseCase approveCustomerUseCase;
  final RejectCustomerUseCase? rejectCustomerUseCase;
  final GetPointsToCashConfigUseCase? getPointsToCashConfigUseCase;

  static const int _fullLedgerPageSize = 15;
  StreamSubscription<PointsToCashConfigEntity>? _rateSubscription;

  DashboardBloc({
    required this.getDashboardOverviewUseCase,
    required this.getMasterLedgerUseCase,
    required this.approveCustomerUseCase,
    this.rejectCustomerUseCase,
    this.getPointsToCashConfigUseCase,
  }) : super(const DashboardState()) {
    on<LoadDashboardRequested>(_onLoadDashboard);
    on<RefreshDashboardRequested>(_onRefreshDashboard);
    on<ChangeLedgerCategoryFilterRequested>(_onChangeLedgerFilter);
    on<ApprovePendingCustomerFromDashboardRequested>(_onApproveCustomer);
    on<RejectPendingCustomerFromDashboardRequested>(_onRejectCustomer);
    on<RemoveExpiredPendingClaimRequested>(_onRemoveExpiredClaim);
    on<LoadFullMasterLedgerRequested>(_onLoadFullMasterLedger);

    _rateSubscription = getPointsToCashConfigUseCase?.stream.listen((_) {
      if (!isClosed && state.hasLoadedOnce) {
        add(const RefreshDashboardRequested());
      }
    });
  }

  @override
  Future<void> close() async {
    await _rateSubscription?.cancel();
    return super.close();
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
  }

  Future<void> _onLoadDashboard(
    LoadDashboardRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(
      state.copyWith(
        status: state.hasLoadedOnce
            ? DashboardStatus.refreshing
            : DashboardStatus.loading,
        errorMessage: '',
        clearActionErrorMessage: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      final overview = await getDashboardOverviewUseCase(
        ledgerCategory: state.selectedLedgerFilter,
      );

      final now = DateTime.now();
      final activeClaims = overview.pendingClaims
          .where((c) => !c.isExpiredAt(now))
          .toList();

      emit(
        state.copyWith(
          status: DashboardStatus.loaded,
          adminProfile: overview.adminProfile,
          statistics: overview.statistics,
          pendingVerificationsCount: overview.pendingVerificationsCount,
          pendingVerifications: overview.pendingVerifications,
          pendingClaimsCount: activeClaims.length,
          pendingClaims: activeClaims,
          masterLedger: overview.masterLedger,
          topPerformingUsers: overview.topPerformingUsers,
          systemActivityLog: overview.systemActivityLog,
          errorMessage: '',
          hasLoadedOnce: true,
        ),
      );
    } catch (e) {
      AppLogger.error('Error loading Admin Dashboard: $e');
      emit(
        state.copyWith(
          status: DashboardStatus.error,
          errorMessage: _cleanError(e),
          hasLoadedOnce: true,
        ),
      );
    }
  }

  Future<void> _onRefreshDashboard(
    RefreshDashboardRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(
      state.copyWith(
        status: state.hasLoadedOnce
            ? DashboardStatus.refreshing
            : DashboardStatus.loading,
        clearActionErrorMessage: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      final overview = await getDashboardOverviewUseCase(
        ledgerCategory: state.selectedLedgerFilter,
      );

      final now = DateTime.now();
      final activeClaims = overview.pendingClaims
          .where((c) => !c.isExpiredAt(now))
          .toList();

      emit(
        state.copyWith(
          status: DashboardStatus.loaded,
          adminProfile: overview.adminProfile,
          statistics: overview.statistics,
          pendingVerificationsCount: overview.pendingVerificationsCount,
          pendingVerifications: overview.pendingVerifications,
          pendingClaimsCount: activeClaims.length,
          pendingClaims: activeClaims,
          masterLedger: overview.masterLedger,
          topPerformingUsers: overview.topPerformingUsers,
          systemActivityLog: overview.systemActivityLog,
          errorMessage: '',
          hasLoadedOnce: true,
        ),
      );
    } catch (e) {
      AppLogger.error('Error refreshing Admin Dashboard: $e');
      if (state.hasLoadedOnce) {
        emit(
          state.copyWith(
            status: DashboardStatus.loaded,
            actionErrorMessage: _cleanError(e),
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: DashboardStatus.error,
            errorMessage: _cleanError(e),
            hasLoadedOnce: true,
          ),
        );
      }
    }
  }

  Future<void> _onChangeLedgerFilter(
    ChangeLedgerCategoryFilterRequested event,
    Emitter<DashboardState> emit,
  ) async {
    if (state.selectedLedgerFilter == event.category &&
        !state.isLedgerFilterLoading) {
      return;
    }

    emit(
      state.copyWith(
        selectedLedgerFilter: event.category,
        isLedgerFilterLoading: true,
        clearActionErrorMessage: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      final entries = await getMasterLedgerUseCase(
        category: event.category,
        limit: 5,
        offset: 0,
      );

      emit(
        state.copyWith(masterLedger: entries, isLedgerFilterLoading: false),
      );
    } catch (e) {
      AppLogger.error('Error filtering Master Ledger on Dashboard: $e');
      emit(
        state.copyWith(
          isLedgerFilterLoading: false,
          actionErrorMessage: _cleanError(e),
        ),
      );
    }
  }

  Future<void> _onApproveCustomer(
    ApprovePendingCustomerFromDashboardRequested event,
    Emitter<DashboardState> emit,
  ) async {
    if (state.approvingCustomerId != null) return;

    emit(
      state.copyWith(
        approvingCustomerId: event.customerId,
        clearActionErrorMessage: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      await approveCustomerUseCase.execute(event.customerId);

      final updatedList = state.pendingVerifications
          .where((c) => c.id != event.customerId)
          .toList();
      final updatedCount = state.pendingVerificationsCount > 0
          ? state.pendingVerificationsCount - 1
          : 0;

      emit(
        state.copyWith(
          pendingVerifications: updatedList,
          pendingVerificationsCount: updatedCount,
          clearApprovingCustomerId: true,
          successMessage: 'Customer approved and wallet activated.',
        ),
      );

      // Refresh full dashboard overview in background so statistics & activity log reflect the approval
      final overview = await getDashboardOverviewUseCase(
        ledgerCategory: state.selectedLedgerFilter,
      );
      final now = DateTime.now();
      final activeClaims = overview.pendingClaims
          .where((c) => !c.isExpiredAt(now))
          .toList();

      emit(
        state.copyWith(
          status: DashboardStatus.loaded,
          adminProfile: overview.adminProfile,
          statistics: overview.statistics,
          pendingVerificationsCount: overview.pendingVerificationsCount,
          pendingVerifications: overview.pendingVerifications,
          pendingClaimsCount: activeClaims.length,
          pendingClaims: activeClaims,
          masterLedger: overview.masterLedger,
          topPerformingUsers: overview.topPerformingUsers,
          systemActivityLog: overview.systemActivityLog,
          clearApprovingCustomerId: true,
        ),
      );
    } catch (e) {
      AppLogger.error('Error approving customer from Dashboard: $e');
      emit(
        state.copyWith(
          clearApprovingCustomerId: true,
          actionErrorMessage: _cleanError(e),
        ),
      );
    }
  }

  Future<void> _onRejectCustomer(
    RejectPendingCustomerFromDashboardRequested event,
    Emitter<DashboardState> emit,
  ) async {
    final rejectUseCase = rejectCustomerUseCase;
    if (rejectUseCase == null || state.approvingCustomerId != null) return;

    emit(
      state.copyWith(
        approvingCustomerId: event.customerId,
        clearActionErrorMessage: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      await rejectUseCase.execute(event.customerId, event.reason);

      final updatedList = state.pendingVerifications
          .where((c) => c.id != event.customerId)
          .toList();
      final updatedCount = state.pendingVerificationsCount > 0
          ? state.pendingVerificationsCount - 1
          : 0;

      emit(
        state.copyWith(
          pendingVerifications: updatedList,
          pendingVerificationsCount: updatedCount,
          clearApprovingCustomerId: true,
          successMessage: 'Customer registration restricted.',
        ),
      );

      final overview = await getDashboardOverviewUseCase(
        ledgerCategory: state.selectedLedgerFilter,
      );
      final now = DateTime.now();
      final activeClaims = overview.pendingClaims
          .where((c) => !c.isExpiredAt(now))
          .toList();

      emit(
        state.copyWith(
          status: DashboardStatus.loaded,
          adminProfile: overview.adminProfile,
          statistics: overview.statistics,
          pendingVerificationsCount: overview.pendingVerificationsCount,
          pendingVerifications: overview.pendingVerifications,
          pendingClaimsCount: activeClaims.length,
          pendingClaims: activeClaims,
          masterLedger: overview.masterLedger,
          topPerformingUsers: overview.topPerformingUsers,
          systemActivityLog: overview.systemActivityLog,
          clearApprovingCustomerId: true,
        ),
      );
    } catch (e) {
      AppLogger.error('Error rejecting customer from Dashboard: $e');
      emit(
        state.copyWith(
          clearApprovingCustomerId: true,
          actionErrorMessage: _cleanError(e),
        ),
      );
    }
  }

  void _onRemoveExpiredClaim(
    RemoveExpiredPendingClaimRequested event,
    Emitter<DashboardState> emit,
  ) {
    final updated = state.pendingClaims
        .where((c) => c.id != event.claimId && !c.isExpiredAt())
        .toList();
    emit(
      state.copyWith(
        pendingClaims: updated,
        pendingClaimsCount: updated.length,
      ),
    );
  }

  Future<void> _onLoadFullMasterLedger(
    LoadFullMasterLedgerRequested event,
    Emitter<DashboardState> emit,
  ) async {
    final targetCategory = event.category ?? state.selectedLedgerFilter;
    final targetQuery = event.searchQuery ?? state.fullLedgerSearchQuery;
    final offset = event.loadMore ? state.fullLedgerEntries.length : 0;

    emit(
      state.copyWith(
        selectedLedgerFilter: targetCategory,
        fullLedgerSearchQuery: targetQuery,
        isFullLedgerLoading: true,
        clearActionErrorMessage: true,
      ),
    );

    try {
      final entries = await getMasterLedgerUseCase(
        category: targetCategory,
        searchQuery: targetQuery,
        limit: _fullLedgerPageSize,
        offset: offset,
      );

      final merged = event.loadMore
          ? [...state.fullLedgerEntries, ...entries]
          : entries;

      emit(
        state.copyWith(
          fullLedgerEntries: merged,
          isFullLedgerLoading: false,
          hasMoreFullLedger: entries.length >= _fullLedgerPageSize,
        ),
      );
    } catch (e) {
      AppLogger.error('Error loading full Master Ledger: $e');
      emit(
        state.copyWith(
          isFullLedgerLoading: false,
          actionErrorMessage: _cleanError(e),
        ),
      );
    }
  }
}
