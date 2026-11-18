import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftexadmin/core/utils/app_logger.dart';
import 'package:shiftexadmin/features/user_management/domain/entities/customer_entity.dart';
import 'package:shiftexadmin/features/user_management/domain/usecases/approve_customer_usecase.dart';
import 'package:shiftexadmin/features/user_management/domain/usecases/get_customer_details_usecase.dart';
import 'package:shiftexadmin/features/user_management/domain/usecases/get_customers_usecase.dart';
import 'package:shiftexadmin/features/user_management/domain/usecases/get_top_earners_usecase.dart';
import 'package:shiftexadmin/features/user_management/domain/usecases/get_user_statistics_usecase.dart';
import 'package:shiftexadmin/features/user_management/domain/usecases/reject_customer_usecase.dart';
import 'package:shiftexadmin/features/user_management/presentation/bloc/user_management_event.dart';
import 'package:shiftexadmin/features/user_management/presentation/bloc/user_management_state.dart';

class UserManagementBloc
    extends Bloc<UserManagementEvent, UserManagementState> {
  final GetCustomersUseCase getCustomersUseCase;
  final GetUserStatisticsUseCase getUserStatisticsUseCase;
  final ApproveCustomerUseCase approveCustomerUseCase;
  final RejectCustomerUseCase rejectCustomerUseCase;
  final GetCustomerDetailsUseCase getCustomerDetailsUseCase;
  final GetTopEarnersUseCase? getTopEarnersUseCase;

  Timer? _debounceTimer;

  UserManagementBloc({
    required this.getCustomersUseCase,
    required this.getUserStatisticsUseCase,
    required this.approveCustomerUseCase,
    required this.rejectCustomerUseCase,
    required this.getCustomerDetailsUseCase,
    this.getTopEarnersUseCase,
  }) : super(const UserManagementState()) {
    on<LoadUserManagementRequested>(_onLoadUserManagement);
    on<SearchCustomersRequested>(_onSearchCustomers);
    on<FilterCustomersRequested>(_onFilterCustomers);
    on<SortCustomersRequested>(_onSortCustomers);
    on<ChangeTopEarnersRangeRequested>(_onChangeTopEarnersRange);
    on<ApproveCustomerRequested>(_onApproveCustomer);
    on<RejectCustomerRequested>(_onRejectCustomer);
    on<RefreshUserManagementRequested>(_onRefreshUserManagement);
    on<LoadCustomerDetailsRequested>(_onLoadCustomerDetails);
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }

  Future<List<CustomerEntity>> _fetchTopEarners(
    String range,
    List<CustomerEntity> fallbackCustomers,
  ) async {
    if (getTopEarnersUseCase != null) {
      try {
        final earners = await getTopEarnersUseCase!.execute(
          range: range.toLowerCase(),
          limit: 3,
        );
        if (earners.isNotEmpty) {
          return earners;
        }
      } catch (e) {
        AppLogger.warning('Could not fetch top earners ($range): $e');
      }
    }
    final fromCustomers =
        fallbackCustomers
            .where((c) => c.isApproved && c.displayTopEarnerPoints > 0)
            .toList()
          ..sort(
            (a, b) =>
                b.displayTopEarnerPoints.compareTo(a.displayTopEarnerPoints),
          );
    return fromCustomers.take(3).toList();
  }

  Future<void> _onLoadUserManagement(
    LoadUserManagementRequested event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(
      state.copyWith(
        status: UserManagementStatus.loading,
        clearSuccessMessage: true,
      ),
    );

    try {
      final statistics = await getUserStatisticsUseCase.execute();
      final customers = await getCustomersUseCase.execute(
        status: state.selectedFilter,
        searchQuery: state.searchQuery,
        sortBy: state.sortBy,
      );
      final topEarners = await _fetchTopEarners(
        state.topEarnersRange,
        customers,
      );

      emit(
        state.copyWith(
          status: UserManagementStatus.loaded,
          statistics: statistics,
          customers: customers,
          topEarners: topEarners,
          errorMessage: '',
          hasLoadedOnce: true,
        ),
      );
    } catch (e) {
      AppLogger.error('Error loading user management: $e');
      emit(
        state.copyWith(
          status: UserManagementStatus.error,
          errorMessage: e.toString().replaceFirst(
            RegExp(r'^Exception:\s*'),
            '',
          ),
          hasLoadedOnce: true,
        ),
      );
    }
  }

  Future<void> _onSearchCustomers(
    SearchCustomersRequested event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(
      state.copyWith(
        searchQuery: event.query,
        status: UserManagementStatus.loading,
        clearSuccessMessage: true,
      ),
    );

    try {
      final customers = await getCustomersUseCase.execute(
        status: state.selectedFilter,
        searchQuery: event.query,
        sortBy: state.sortBy,
      );

      emit(
        state.copyWith(
          status: UserManagementStatus.loaded,
          customers: customers,
        ),
      );
    } catch (e) {
      AppLogger.error('Error searching customers: $e');
      emit(
        state.copyWith(
          status: UserManagementStatus.error,
          errorMessage: e.toString().replaceFirst(
            RegExp(r'^Exception:\s*'),
            '',
          ),
        ),
      );
    }
  }

  Future<void> _onFilterCustomers(
    FilterCustomersRequested event,
    Emitter<UserManagementState> emit,
  ) async {
    if (state.selectedFilter == event.filter) return;

    emit(
      state.copyWith(
        selectedFilter: event.filter,
        status: UserManagementStatus.loading,
        clearSuccessMessage: true,
      ),
    );

    try {
      final customers = await getCustomersUseCase.execute(
        status: event.filter,
        searchQuery: state.searchQuery,
        sortBy: state.sortBy,
      );

      emit(
        state.copyWith(
          status: UserManagementStatus.loaded,
          customers: customers,
        ),
      );
    } catch (e) {
      AppLogger.error('Error filtering customers: $e');
      emit(
        state.copyWith(
          status: UserManagementStatus.error,
          errorMessage: e.toString().replaceFirst(
            RegExp(r'^Exception:\s*'),
            '',
          ),
        ),
      );
    }
  }

  Future<void> _onSortCustomers(
    SortCustomersRequested event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(
      state.copyWith(
        sortBy: event.sortBy,
        status: UserManagementStatus.loading,
        clearSuccessMessage: true,
      ),
    );

    try {
      final customers = await getCustomersUseCase.execute(
        status: state.selectedFilter,
        searchQuery: state.searchQuery,
        sortBy: event.sortBy,
      );

      emit(
        state.copyWith(
          status: UserManagementStatus.loaded,
          customers: customers,
        ),
      );
    } catch (e) {
      AppLogger.error('Error sorting customers: $e');
      emit(
        state.copyWith(
          status: UserManagementStatus.error,
          errorMessage: e.toString().replaceFirst(
            RegExp(r'^Exception:\s*'),
            '',
          ),
        ),
      );
    }
  }

  Future<void> _onChangeTopEarnersRange(
    ChangeTopEarnersRangeRequested event,
    Emitter<UserManagementState> emit,
  ) async {
    if (state.topEarnersRange == event.range && !state.isLoadingTopEarners) {
      return;
    }

    emit(
      state.copyWith(
        topEarnersRange: event.range,
        isLoadingTopEarners: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      final topEarners = await _fetchTopEarners(event.range, state.customers);
      emit(state.copyWith(topEarners: topEarners, isLoadingTopEarners: false));
    } catch (e) {
      AppLogger.error('Error changing top earners range: $e');
      emit(state.copyWith(isLoadingTopEarners: false));
    }
  }

  Future<void> _onApproveCustomer(
    ApproveCustomerRequested event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(
      state.copyWith(
        status: UserManagementStatus.approving,
        clearSuccessMessage: true,
      ),
    );

    try {
      await approveCustomerUseCase.execute(event.customerId);

      // Refresh customers, statistics & top earners preserving filter & query
      final statistics = await getUserStatisticsUseCase.execute();
      final customers = await getCustomersUseCase.execute(
        status: state.selectedFilter,
        searchQuery: state.searchQuery,
        sortBy: state.sortBy,
      );
      final topEarners = await _fetchTopEarners(
        state.topEarnersRange,
        customers,
      );

      emit(
        state.copyWith(
          status: UserManagementStatus.loaded,
          statistics: statistics,
          customers: customers,
          topEarners: topEarners,
          successMessage: 'Customer approved successfully!',
          errorMessage: '',
        ),
      );
    } catch (e) {
      AppLogger.error('Error approving customer: $e');
      emit(
        state.copyWith(
          status: UserManagementStatus.error,
          errorMessage: e.toString().replaceFirst(
            RegExp(r'^Exception:\s*'),
            '',
          ),
        ),
      );
    }
  }

  Future<void> _onRejectCustomer(
    RejectCustomerRequested event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(
      state.copyWith(
        status: UserManagementStatus.rejecting,
        clearSuccessMessage: true,
      ),
    );

    try {
      await rejectCustomerUseCase.execute(event.customerId, event.reason);

      final statistics = await getUserStatisticsUseCase.execute();
      final customers = await getCustomersUseCase.execute(
        status: state.selectedFilter,
        searchQuery: state.searchQuery,
        sortBy: state.sortBy,
      );
      final topEarners = await _fetchTopEarners(
        state.topEarnersRange,
        customers,
      );

      emit(
        state.copyWith(
          status: UserManagementStatus.loaded,
          statistics: statistics,
          customers: customers,
          topEarners: topEarners,
          successMessage: 'Customer rejected successfully.',
          errorMessage: '',
        ),
      );
    } catch (e) {
      AppLogger.error('Error rejecting customer: $e');
      emit(
        state.copyWith(
          status: UserManagementStatus.error,
          errorMessage: e.toString().replaceFirst(
            RegExp(r'^Exception:\s*'),
            '',
          ),
        ),
      );
    }
  }

  Future<void> _onRefreshUserManagement(
    RefreshUserManagementRequested event,
    Emitter<UserManagementState> emit,
  ) async {
    try {
      final statistics = await getUserStatisticsUseCase.execute();
      final customers = await getCustomersUseCase.execute(
        status: state.selectedFilter,
        searchQuery: state.searchQuery,
        sortBy: state.sortBy,
      );
      final topEarners = await _fetchTopEarners(
        state.topEarnersRange,
        customers,
      );

      emit(
        state.copyWith(
          status: UserManagementStatus.loaded,
          statistics: statistics,
          customers: customers,
          topEarners: topEarners,
          errorMessage: '',
          hasLoadedOnce: true,
        ),
      );
    } catch (e) {
      AppLogger.error('Error refreshing user management: $e');
      emit(
        state.copyWith(
          status: UserManagementStatus.error,
          errorMessage: e.toString().replaceFirst(
            RegExp(r'^Exception:\s*'),
            '',
          ),
          hasLoadedOnce: true,
        ),
      );
    }
  }

  Future<void> _onLoadCustomerDetails(
    LoadCustomerDetailsRequested event,
    Emitter<UserManagementState> emit,
  ) async {
    try {
      final customer = await getCustomerDetailsUseCase.execute(
        event.customerId,
      );
      emit(state.copyWith(selectedCustomer: customer));
    } catch (e) {
      AppLogger.error('Error loading customer details: $e');
    }
  }
}
