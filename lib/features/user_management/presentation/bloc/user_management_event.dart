abstract class UserManagementEvent {
  const UserManagementEvent();
}

class LoadUserManagementRequested extends UserManagementEvent {
  const LoadUserManagementRequested();
}

class SearchCustomersRequested extends UserManagementEvent {
  final String query;
  const SearchCustomersRequested(this.query);
}

class FilterCustomersRequested extends UserManagementEvent {
  final String filter;
  const FilterCustomersRequested(this.filter);
}

class SortCustomersRequested extends UserManagementEvent {
  final String sortBy;
  const SortCustomersRequested(this.sortBy);
}

class ChangeTopEarnersRangeRequested extends UserManagementEvent {
  final String range;
  const ChangeTopEarnersRangeRequested(this.range);
}

class ApproveCustomerRequested extends UserManagementEvent {
  final String customerId;
  const ApproveCustomerRequested(this.customerId);
}

class RejectCustomerRequested extends UserManagementEvent {
  final String customerId;
  final String reason;
  const RejectCustomerRequested({
    required this.customerId,
    required this.reason,
  });
}

class RefreshUserManagementRequested extends UserManagementEvent {
  const RefreshUserManagementRequested();
}

class LoadCustomerDetailsRequested extends UserManagementEvent {
  final String customerId;
  const LoadCustomerDetailsRequested(this.customerId);
}
