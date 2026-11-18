import 'package:shiftexadmin/features/dashboard/domain/entities/master_ledger_entry_entity.dart';

abstract class DashboardEvent {
  const DashboardEvent();
}

class LoadDashboardRequested extends DashboardEvent {
  const LoadDashboardRequested();
}

class RefreshDashboardRequested extends DashboardEvent {
  const RefreshDashboardRequested();
}

class ChangeLedgerCategoryFilterRequested extends DashboardEvent {
  final LedgerCategoryFilter category;

  const ChangeLedgerCategoryFilterRequested(this.category);
}

class ApprovePendingCustomerFromDashboardRequested extends DashboardEvent {
  final String customerId;

  const ApprovePendingCustomerFromDashboardRequested(this.customerId);
}

class RejectPendingCustomerFromDashboardRequested extends DashboardEvent {
  final String customerId;
  final String reason;

  const RejectPendingCustomerFromDashboardRequested({
    required this.customerId,
    required this.reason,
  });
}

class RemoveExpiredPendingClaimRequested extends DashboardEvent {
  final String claimId;

  const RemoveExpiredPendingClaimRequested(this.claimId);
}

class LoadFullMasterLedgerRequested extends DashboardEvent {
  final LedgerCategoryFilter? category;
  final String? searchQuery;
  final bool loadMore;

  const LoadFullMasterLedgerRequested({
    this.category,
    this.searchQuery,
    this.loadMore = false,
  });
}
