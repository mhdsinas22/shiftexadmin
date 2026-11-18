import 'package:shiftexadmin/features/dashboard/domain/entities/admin_identity_entity.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/dashboard_statistics_entity.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/master_ledger_entry_entity.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/pending_claim_item_entity.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/system_activity_item_entity.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/top_performing_user_entity.dart';
import 'package:shiftexadmin/features/user_management/domain/entities/customer_entity.dart';

class DashboardOverviewEntity {
  final AdminIdentityEntity adminProfile;
  final DashboardStatisticsEntity statistics;
  final int pendingVerificationsCount;
  final List<CustomerEntity> pendingVerifications;
  final int pendingClaimsCount;
  final List<PendingClaimItemEntity> pendingClaims;
  final List<MasterLedgerEntryEntity> masterLedger;
  final List<TopPerformingUserEntity> topPerformingUsers;
  final List<SystemActivityItemEntity> systemActivityLog;
  final DateTime fetchedAt;

  const DashboardOverviewEntity({
    required this.adminProfile,
    required this.statistics,
    this.pendingVerificationsCount = 0,
    this.pendingVerifications = const [],
    this.pendingClaimsCount = 0,
    this.pendingClaims = const [],
    this.masterLedger = const [],
    this.topPerformingUsers = const [],
    this.systemActivityLog = const [],
    required this.fetchedAt,
  });

  DashboardOverviewEntity copyWith({
    AdminIdentityEntity? adminProfile,
    DashboardStatisticsEntity? statistics,
    int? pendingVerificationsCount,
    List<CustomerEntity>? pendingVerifications,
    int? pendingClaimsCount,
    List<PendingClaimItemEntity>? pendingClaims,
    List<MasterLedgerEntryEntity>? masterLedger,
    List<TopPerformingUserEntity>? topPerformingUsers,
    List<SystemActivityItemEntity>? systemActivityLog,
    DateTime? fetchedAt,
  }) {
    return DashboardOverviewEntity(
      adminProfile: adminProfile ?? this.adminProfile,
      statistics: statistics ?? this.statistics,
      pendingVerificationsCount:
          pendingVerificationsCount ?? this.pendingVerificationsCount,
      pendingVerifications: pendingVerifications ?? this.pendingVerifications,
      pendingClaimsCount: pendingClaimsCount ?? this.pendingClaimsCount,
      pendingClaims: pendingClaims ?? this.pendingClaims,
      masterLedger: masterLedger ?? this.masterLedger,
      topPerformingUsers: topPerformingUsers ?? this.topPerformingUsers,
      systemActivityLog: systemActivityLog ?? this.systemActivityLog,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }
}
