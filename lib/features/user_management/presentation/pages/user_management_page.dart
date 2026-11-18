import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/core/di/injection_container.dart';
import 'package:shiftexadmin/features/user_management/domain/entities/customer_entity.dart';
import 'package:shiftexadmin/features/user_management/presentation/bloc/user_management_bloc.dart';
import 'package:shiftexadmin/features/user_management/presentation/bloc/user_management_event.dart';
import 'package:shiftexadmin/features/user_management/presentation/bloc/user_management_state.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/approval_confirmation_dialog_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/customer_details_sheet_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/customer_directory_card_shimmer_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/customer_directory_card_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/customer_filter_chips_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/customer_search_bar_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/customer_sort_filter_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/pending_action_required_card_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/rejection_reason_dialog_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/top_earners_card_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/user_management_header_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/user_management_shimmer_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/user_statistics_grid_widget.dart';

class UserManagementPage extends StatelessWidget {
  final String? initialFilter;
  final String? navigationNonce;

  const UserManagementPage({
    super.key,
    this.initialFilter,
    this.navigationNonce,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UserManagementBloc>(
      create: (_) =>
          sl<UserManagementBloc>()..add(const LoadUserManagementRequested()),
      child: UserManagementView(
        initialFilter: initialFilter,
        navigationNonce: navigationNonce,
      ),
    );
  }
}

class UserManagementView extends StatefulWidget {
  final String? initialFilter;
  final String? navigationNonce;

  const UserManagementView({
    super.key,
    this.initialFilter,
    this.navigationNonce,
  });

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  String? _lastAppliedNonce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _applyInitialFilter();
      }
    });
  }

  @override
  void didUpdateWidget(covariant UserManagementView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFilter != oldWidget.initialFilter ||
        widget.navigationNonce != oldWidget.navigationNonce) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _applyInitialFilter();
        }
      });
    }
  }

  void _applyInitialFilter() {
    final filter = widget.initialFilter?.trim() ?? '';
    if (filter.isEmpty) return;
    final nonceKey = '$filter:${widget.navigationNonce ?? ''}';
    if (_lastAppliedNonce == nonceKey) return;
    _lastAppliedNonce = nonceKey;
    context.read<UserManagementBloc>().add(FilterCustomersRequested(filter));
  }

  void _onApprove(BuildContext context, CustomerEntity customer) {
    ApprovalConfirmationDialogWidget.show(
      context,
      customer: customer,
      onConfirm: () {
        context.read<UserManagementBloc>().add(
          ApproveCustomerRequested(customer.id),
        );
      },
    );
  }

  void _onReject(BuildContext context, CustomerEntity customer) {
    RejectionReasonDialogWidget.show(context, customer: customer).then((
      reason,
    ) {
      if (reason != null && reason.trim().isNotEmpty && context.mounted) {
        context.read<UserManagementBloc>().add(
          RejectCustomerRequested(
            customerId: customer.id,
            reason: reason.trim(),
          ),
        );
      }
    });
  }

  void _onReviewDetails(BuildContext context, CustomerEntity customer) {
    CustomerDetailsSheetWidget.show(
      context,
      customer: customer,
      onApprove: () => _onApprove(context, customer),
      onReject: () => _onReject(context, customer),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: BlocConsumer<UserManagementBloc, UserManagementState>(
          listener: (context, state) {
            if (state.successMessage != null &&
                state.successMessage!.isNotEmpty) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.eifGreen,
                  content: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.pureWhite,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.successMessage!,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            color: AppColors.pureWhite,
                          ),
                        ),
                      ),
                    ],
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            } else if (state.status == UserManagementStatus.error &&
                state.errorMessage.isNotEmpty) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.purered,
                  content: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.pureWhite,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.errorMessage,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            color: AppColors.pureWhite,
                          ),
                        ),
                      ),
                    ],
                  ),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
          builder: (context, state) {
            final topPending = state.topPendingCustomer;
            final isInitialShimmer =
                !state.hasLoadedOnce &&
                (state.status == UserManagementStatus.initial ||
                    state.status == UserManagementStatus.loading);

            return RefreshIndicator(
              color: AppColors.darkNavy,
              onRefresh: () async {
                context.read<UserManagementBloc>().add(
                  const RefreshUserManagementRequested(),
                );
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Bar
                    UserManagementHeaderWidget(
                      onNotificationPressed: () {},
                      onProfilePressed: () {},
                      onAddUserPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Customer registration is handled via the Customer app.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    if (isInitialShimmer)
                      const UserManagementShimmerWidget()
                    else ...[
                      // Statistics Grid (2x2)
                      UserStatisticsGridWidget(statistics: state.statistics),
                      const SizedBox(height: 16),

                      // Search Bar
                      CustomerSearchBarWidget(
                        initialValue: state.searchQuery,
                        onSearchChanged: (query) {
                          context.read<UserManagementBloc>().add(
                            SearchCustomersRequested(query),
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      // Filter Chips
                      CustomerFilterChipsWidget(
                        selectedFilter: state.selectedFilter,
                        pendingCount: state.statistics.pendingCount,
                        onFilterSelected: (filter) {
                          context.read<UserManagementBloc>().add(
                            FilterCustomersRequested(filter),
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      // Sort & Filter row
                      CustomerSortFilterWidget(
                        sortBy: state.sortBy,
                        onSortChanged: (newSort) {
                          context.read<UserManagementBloc>().add(
                            SortCustomersRequested(newSort),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Pending Action Required Card (if any pending customer exists)
                      if (topPending != null) ...[
                        PendingActionRequiredCardWidget(
                          customer: topPending,
                          onApprovePressed: () =>
                              _onApprove(context, topPending),
                          onReviewDetailsPressed: () =>
                              _onReviewDetails(context, topPending),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // User Directory Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'User Directory (${state.customers.length})',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Text(
                            'Showing recent',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Customer List States
                      if (state.status == UserManagementStatus.loading)
                        const CustomerDirectoryShimmerListWidget(itemCount: 3)
                      else if (state.customers.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 36,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.pureWhite,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.search_off_rounded,
                                size: 40,
                                color: AppColors.textHint,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'No customers found',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                state.searchQuery.isNotEmpty
                                    ? 'No results matching "${state.searchQuery}"'
                                    : 'No customer profiles in this category.',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        ...state.customers.map((customer) {
                          return CustomerDirectoryCardWidget(
                            customer: customer,
                            onTap: () => _onReviewDetails(context, customer),
                            onApprove: () => _onApprove(context, customer),
                            onReject: () => _onReject(context, customer),
                          );
                        }),

                      const SizedBox(height: 16),

                      // Top Earners Card
                      TopEarnersCardWidget(
                        customers:
                            state.topEarners.isNotEmpty || state.hasLoadedOnce
                            ? state.topEarners
                            : state.customers,
                        selectedRange: state.topEarnersRange,
                        isLoading: state.isLoadingTopEarners,
                        onRangeChanged: (range) {
                          context.read<UserManagementBloc>().add(
                            ChangeTopEarnersRangeRequested(range),
                          );
                        },
                        onCustomerTapped: (customer) =>
                            _onReviewDetails(context, customer),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
