enum AdminRoleType {
  superAdmin('super_admin', 'Super Admin'),
  storeManager('store_manager', 'Store Manager'),
  auditor('auditor', 'Auditor');

  final String dbValue;
  final String displayLabel;

  const AdminRoleType(this.dbValue, this.displayLabel);

  static AdminRoleType fromString(String? raw) {
    final clean = (raw ?? '').trim().toLowerCase();
    for (final role in AdminRoleType.values) {
      if (role.dbValue == clean) return role;
    }
    return AdminRoleType.storeManager;
  }

  List<String> get defaultPermissions {
    switch (this) {
      case AdminRoleType.superAdmin:
        return AdminPermission.allPermissions;
      case AdminRoleType.storeManager:
        return const [
          AdminPermission.dashboardView,
          AdminPermission.posView,
          AdminPermission.posVerifyClaim,
          AdminPermission.usersView,
        ];
      case AdminRoleType.auditor:
        return const [
          AdminPermission.dashboardView,
          AdminPermission.ledgerView,
          AdminPermission.auditView,
          AdminPermission.usersView,
          AdminPermission.usersApprove,
        ];
    }
  }

  String get defaultTerminal {
    switch (this) {
      case AdminRoleType.superAdmin:
        return 'ShiftEx Central Control';
      case AdminRoleType.storeManager:
        return 'Term #02';
      case AdminRoleType.auditor:
        return 'Read-only Ledger';
    }
  }
}

class AdminPermission {
  static const String dashboardView = 'dashboard.view';
  static const String usersView = 'users.view';
  static const String usersApprove = 'users.approve';
  static const String usersReject = 'users.reject';
  static const String posView = 'pos.view';
  static const String posGiveReward = 'pos.give_reward';
  static const String posVerifyClaim = 'pos.verify_claim';
  static const String ledgerView = 'ledger.view';
  static const String adsManage = 'ads.manage';
  static const String settingsView = 'settings.view';
  static const String settingsManage = 'settings.manage';
  static const String streakManage = 'streak.manage';
  static const String valuationManage = 'valuation.manage';
  static const String adminsView = 'admins.view';
  static const String adminsInvite = 'admins.invite';
  static const String adminsManage = 'admins.manage';
  static const String auditView = 'audit.view';

  static const List<String> allPermissions = [
    dashboardView,
    usersView,
    usersApprove,
    usersReject,
    posView,
    posGiveReward,
    posVerifyClaim,
    ledgerView,
    adsManage,
    settingsView,
    settingsManage,
    streakManage,
    valuationManage,
    adminsView,
    adminsInvite,
    adminsManage,
    auditView,
  ];

  static String labelFor(String permissionId) {
    switch (permissionId) {
      case dashboardView:
        return 'View Dashboard';
      case usersView:
        return 'View Users';
      case usersApprove:
        return 'Approve KYC';
      case usersReject:
        return 'Reject KYC';
      case posView:
        return 'Access POS Scanner';
      case posGiveReward:
        return 'Allocate POS Rewards';
      case posVerifyClaim:
        return 'Verify & Redeem Claims';
      case ledgerView:
        return 'View Master Ledger';
      case adsManage:
        return 'Manage Advertisements';
      case settingsView:
        return 'View Settings';
      case settingsManage:
        return 'Modify Platform Settings';
      case streakManage:
        return 'Configure Daily Streak';
      case valuationManage:
        return 'Update Points-to-Cash Rate';
      case adminsView:
        return 'View Admin Operators';
      case adminsInvite:
        return 'Invite Admin Credentials';
      case adminsManage:
        return 'Manage Admin Permissions';
      case auditView:
        return 'View Audit Logs';
      default:
        return permissionId;
    }
  }
}
