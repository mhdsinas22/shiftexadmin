import 'package:shiftexadmin/features/dashboard/data/models/admin_identity_model.dart';
import 'package:shiftexadmin/features/dashboard/data/models/dashboard_statistics_model.dart';
import 'package:shiftexadmin/features/dashboard/data/models/master_ledger_entry_model.dart';
import 'package:shiftexadmin/features/dashboard/data/models/pending_claim_item_model.dart';
import 'package:shiftexadmin/features/dashboard/data/models/system_activity_item_model.dart';
import 'package:shiftexadmin/features/dashboard/data/models/top_performing_user_model.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/dashboard_overview_entity.dart';
import 'package:shiftexadmin/features/user_management/data/models/customer_model.dart';

class DashboardOverviewModel extends DashboardOverviewEntity {
  const DashboardOverviewModel({
    required super.adminProfile,
    required super.statistics,
    super.pendingVerificationsCount,
    super.pendingVerifications,
    super.pendingClaimsCount,
    super.pendingClaims,
    super.masterLedger,
    super.topPerformingUsers,
    super.systemActivityLog,
    required super.fetchedAt,
  });

  factory DashboardOverviewModel.fromJson(Map<String, dynamic> json) {
    final adminRaw = json['admin_profile'];
    final adminProfile = adminRaw is Map
        ? AdminIdentityModel.fromJson(Map<String, dynamic>.from(adminRaw))
        : const AdminIdentityModel(id: '', fullName: 'Admin', email: '');

    final statsRaw = json['statistics'];
    final statistics = statsRaw is Map
        ? DashboardStatisticsModel.fromJson(Map<String, dynamic>.from(statsRaw))
        : const DashboardStatisticsModel();

    final pendingVerificationsRaw = json['pending_verifications'];
    final pendingVerifications = pendingVerificationsRaw is List
        ? pendingVerificationsRaw
              .whereType<Map>()
              .map(
                (row) => CustomerModel.fromJson(Map<String, dynamic>.from(row)),
              )
              .toList()
        : const <CustomerModel>[];

    final pendingClaimsRaw = json['pending_claims'];
    final pendingClaims = pendingClaimsRaw is List
        ? pendingClaimsRaw
              .whereType<Map>()
              .map(
                (row) => PendingClaimItemModel.fromJson(
                  Map<String, dynamic>.from(row),
                ),
              )
              .toList()
        : const <PendingClaimItemModel>[];

    final ledgerRaw = json['master_ledger'];
    final masterLedger = ledgerRaw is List
        ? ledgerRaw
              .whereType<Map>()
              .map(
                (row) => MasterLedgerEntryModel.fromJson(
                  Map<String, dynamic>.from(row),
                ),
              )
              .toList()
        : const <MasterLedgerEntryModel>[];

    final topUsersRaw = json['top_performing_users'];
    final topUsers = topUsersRaw is List
        ? topUsersRaw
              .whereType<Map>()
              .map(
                (row) => TopPerformingUserModel.fromJson(
                  Map<String, dynamic>.from(row),
                ),
              )
              .toList()
        : const <TopPerformingUserModel>[];

    final activityRaw = json['system_activity_log'];
    final activityLog = activityRaw is List
        ? activityRaw
              .whereType<Map>()
              .map(
                (row) => SystemActivityItemModel.fromJson(
                  Map<String, dynamic>.from(row),
                ),
              )
              .toList()
        : const <SystemActivityItemModel>[];

    final fetchedAt = json['fetched_at'] != null
        ? (DateTime.tryParse(json['fetched_at'].toString())?.toLocal() ??
              DateTime.now())
        : DateTime.now();

    return DashboardOverviewModel(
      adminProfile: adminProfile,
      statistics: statistics,
      pendingVerificationsCount:
          (json['pending_verifications_count'] as num?)?.toInt() ??
          pendingVerifications.length,
      pendingVerifications: pendingVerifications,
      pendingClaimsCount:
          (json['pending_claims_count'] as num?)?.toInt() ??
          pendingClaims.length,
      pendingClaims: pendingClaims,
      masterLedger: masterLedger,
      topPerformingUsers: topUsers,
      systemActivityLog: activityLog,
      fetchedAt: fetchedAt,
    );
  }
}
