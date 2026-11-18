import 'package:shiftexadmin/features/dashboard/domain/entities/admin_identity_entity.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/dashboard_statistics_entity.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/master_ledger_entry_entity.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/pending_claim_item_entity.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/system_activity_item_entity.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/top_performing_user_entity.dart';
import 'package:shiftexadmin/features/user_management/domain/entities/customer_entity.dart';

enum DashboardStatus { initial, loading, loaded, refreshing, error }

class DashboardState {
  final DashboardStatus status;
  final AdminIdentityEntity adminProfile;
  final DashboardStatisticsEntity statistics;
  final int pendingVerificationsCount;
  final List<CustomerEntity> pendingVerifications;
  final int pendingClaimsCount;
  final List<PendingClaimItemEntity> pendingClaims;
  final List<MasterLedgerEntryEntity> masterLedger;
  final LedgerCategoryFilter selectedLedgerFilter;
  final bool isLedgerFilterLoading;
  final List<MasterLedgerEntryEntity> fullLedgerEntries;
  final bool isFullLedgerLoading;
  final bool hasMoreFullLedger;
  final String fullLedgerSearchQuery;
  final List<TopPerformingUserEntity> topPerformingUsers;
  final List<SystemActivityItemEntity> systemActivityLog;
  final String? approvingCustomerId;
  final String errorMessage;
  final String? actionErrorMessage;
  final String? successMessage;
  final bool hasLoadedOnce;

  const DashboardState({
    this.status = DashboardStatus.initial,
    this.adminProfile = const AdminIdentityEntity(
      id: '',
      fullName: 'Admin',
      email: '',
    ),
    this.statistics = const DashboardStatisticsEntity(),
    this.pendingVerificationsCount = 0,
    this.pendingVerifications = const [],
    this.pendingClaimsCount = 0,
    this.pendingClaims = const [],
    this.masterLedger = const [],
    this.selectedLedgerFilter = LedgerCategoryFilter.all,
    this.isLedgerFilterLoading = false,
    this.fullLedgerEntries = const [],
    this.isFullLedgerLoading = false,
    this.hasMoreFullLedger = false,
    this.fullLedgerSearchQuery = '',
    this.topPerformingUsers = const [],
    this.systemActivityLog = const [],
    this.approvingCustomerId,
    this.errorMessage = '',
    this.actionErrorMessage,
    this.successMessage,
    this.hasLoadedOnce = false,
  });

  List<PendingClaimItemEntity> activePendingClaims([DateTime? now]) {
    final ref = now ?? DateTime.now();
    return pendingClaims.where((c) => !c.isExpiredAt(ref)).toList();
  }

  DashboardState copyWith({
    DashboardStatus? status,
    AdminIdentityEntity? adminProfile,
    DashboardStatisticsEntity? statistics,
    int? pendingVerificationsCount,
    List<CustomerEntity>? pendingVerifications,
    int? pendingClaimsCount,
    List<PendingClaimItemEntity>? pendingClaims,
    List<MasterLedgerEntryEntity>? masterLedger,
    LedgerCategoryFilter? selectedLedgerFilter,
    bool? isLedgerFilterLoading,
    List<MasterLedgerEntryEntity>? fullLedgerEntries,
    bool? isFullLedgerLoading,
    bool? hasMoreFullLedger,
    String? fullLedgerSearchQuery,
    List<TopPerformingUserEntity>? topPerformingUsers,
    List<SystemActivityItemEntity>? systemActivityLog,
    String? approvingCustomerId,
    String? errorMessage,
    String? actionErrorMessage,
    String? successMessage,
    bool? hasLoadedOnce,
    bool clearApprovingCustomerId = false,
    bool clearActionErrorMessage = false,
    bool clearSuccessMessage = false,
  }) {
    return DashboardState(
      status: status ?? this.status,
      adminProfile: adminProfile ?? this.adminProfile,
      statistics: statistics ?? this.statistics,
      pendingVerificationsCount:
          pendingVerificationsCount ?? this.pendingVerificationsCount,
      pendingVerifications: pendingVerifications ?? this.pendingVerifications,
      pendingClaimsCount: pendingClaimsCount ?? this.pendingClaimsCount,
      pendingClaims: pendingClaims ?? this.pendingClaims,
      masterLedger: masterLedger ?? this.masterLedger,
      selectedLedgerFilter: selectedLedgerFilter ?? this.selectedLedgerFilter,
      isLedgerFilterLoading:
          isLedgerFilterLoading ?? this.isLedgerFilterLoading,
      fullLedgerEntries: fullLedgerEntries ?? this.fullLedgerEntries,
      isFullLedgerLoading: isFullLedgerLoading ?? this.isFullLedgerLoading,
      hasMoreFullLedger: hasMoreFullLedger ?? this.hasMoreFullLedger,
      fullLedgerSearchQuery:
          fullLedgerSearchQuery ?? this.fullLedgerSearchQuery,
      topPerformingUsers: topPerformingUsers ?? this.topPerformingUsers,
      systemActivityLog: systemActivityLog ?? this.systemActivityLog,
      approvingCustomerId: clearApprovingCustomerId
          ? null
          : (approvingCustomerId ?? this.approvingCustomerId),
      errorMessage: errorMessage ?? this.errorMessage,
      actionErrorMessage: clearActionErrorMessage
          ? null
          : (actionErrorMessage ?? this.actionErrorMessage),
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
    );
  }
}
