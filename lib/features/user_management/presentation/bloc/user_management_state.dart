import 'package:shiftexadmin/features/user_management/domain/entities/customer_entity.dart';
import 'package:shiftexadmin/features/user_management/domain/entities/user_statistics_entity.dart';

enum UserManagementStatus {
  initial,
  loading,
  loaded,
  creating,
  approving,
  rejecting,
  error,
}

class UserManagementState {
  final UserManagementStatus status;
  final List<CustomerEntity> customers;
  final List<CustomerEntity> topEarners;
  final String topEarnersRange;
  final bool isLoadingTopEarners;
  final UserStatisticsEntity statistics;
  final String selectedFilter;
  final String searchQuery;
  final String sortBy;
  final CustomerEntity? selectedCustomer;
  final String errorMessage;
  final String? successMessage;
  final bool hasLoadedOnce;

  const UserManagementState({
    this.status = UserManagementStatus.initial,
    this.customers = const [],
    this.topEarners = const [],
    this.topEarnersRange = 'Weekly',
    this.isLoadingTopEarners = false,
    this.statistics = const UserStatisticsEntity(
      registeredCount: 0,
      pendingCount: 0,
      activeCount: 0,
      restrictedCount: 0,
    ),
    this.selectedFilter = 'all',
    this.searchQuery = '',
    this.sortBy = 'newest',
    this.selectedCustomer,
    this.errorMessage = '',
    this.successMessage,
    this.hasLoadedOnce = false,
  });

  CustomerEntity? get topPendingCustomer {
    try {
      return customers.firstWhere((c) => c.isPending);
    } catch (_) {
      return null;
    }
  }

  UserManagementState copyWith({
    UserManagementStatus? status,
    List<CustomerEntity>? customers,
    List<CustomerEntity>? topEarners,
    String? topEarnersRange,
    bool? isLoadingTopEarners,
    UserStatisticsEntity? statistics,
    String? selectedFilter,
    String? searchQuery,
    String? sortBy,
    CustomerEntity? selectedCustomer,
    String? errorMessage,
    String? successMessage,
    bool? hasLoadedOnce,
    bool clearSelectedCustomer = false,
    bool clearSuccessMessage = false,
  }) {
    return UserManagementState(
      status: status ?? this.status,
      customers: customers ?? this.customers,
      topEarners: topEarners ?? this.topEarners,
      topEarnersRange: topEarnersRange ?? this.topEarnersRange,
      isLoadingTopEarners: isLoadingTopEarners ?? this.isLoadingTopEarners,
      statistics: statistics ?? this.statistics,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      selectedCustomer: clearSelectedCustomer
          ? null
          : (selectedCustomer ?? this.selectedCustomer),
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
    );
  }
}
