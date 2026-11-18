import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/core/di/injection_container.dart';
import 'package:shiftexadmin/core/routes/route_names.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/pending_claim_item_entity.dart';
import 'package:shiftexadmin/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:shiftexadmin/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:shiftexadmin/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:shiftexadmin/features/dashboard/presentation/widgets/dashboard_error_card_widget.dart';
import 'package:shiftexadmin/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:shiftexadmin/features/dashboard/presentation/widgets/dashboard_shimmer_widget.dart';
import 'package:shiftexadmin/features/dashboard/presentation/widgets/master_ledger_section.dart';
import 'package:shiftexadmin/features/dashboard/presentation/widgets/pending_claims_section.dart';
import 'package:shiftexadmin/features/dashboard/presentation/widgets/quick_action_cards.dart';
import 'package:shiftexadmin/features/dashboard/presentation/widgets/statistics_grid.dart';
import 'package:shiftexadmin/features/dashboard/presentation/widgets/system_activity_section.dart';
import 'package:shiftexadmin/features/dashboard/presentation/widgets/top_performing_users_section.dart';
import 'package:shiftexadmin/features/dashboard/presentation/widgets/user_verifications_section.dart';
import 'package:shiftexadmin/features/user_management/domain/entities/customer_entity.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/approval_confirmation_dialog_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/customer_details_sheet_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/rejection_reason_dialog_widget.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DashboardBloc>(
      create: (_) => getIt<DashboardBloc>()..add(const LoadDashboardRequested()),
      child: const AdminDashboardView(),
    );
  }
}

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  void _navigateToScanPos(
    BuildContext context, {
    required String mode,
    String? code,
  }) {
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    final queryParams = <String, String>{
      'mode': mode,
      'ts': DateTime.now().millisecondsSinceEpoch.toString(),
      if (code != null && code.trim().isNotEmpty) 'code': code.trim(),
    };
    final uri = Uri(
      path: RouteNames.scanPosRoute,
      queryParameters: queryParams,
    );
    router.go(uri.toString());
  }

  void _navigateToUserManagement(BuildContext context, {String? filter}) {
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    final queryParams = <String, String>{
      if (filter != null && filter.trim().isNotEmpty) 'filter': filter.trim(),
      'ts': DateTime.now().millisecondsSinceEpoch.toString(),
    };
    final uri = Uri(
      path: RouteNames.userManagementRoute,
      queryParameters: queryParams,
    );
    router.go(uri.toString());
  }

  void _navigateToFullMasterLedger(BuildContext context, DashboardState state) {
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    final uri = Uri(
      path: RouteNames.masterLedgerRoute,
      queryParameters: {'category': state.selectedLedgerFilter.queryKey},
    );
    router.push(uri.toString());
  }

  void _onApproveCustomer(BuildContext context, CustomerEntity customer) {
    final bloc = context.read<DashboardBloc>();
    ApprovalConfirmationDialogWidget.show(
      context,
      customer: customer,
      onConfirm: () {
        bloc.add(ApprovePendingCustomerFromDashboardRequested(customer.id));
      },
    );
  }

  void _onRejectCustomer(BuildContext context, CustomerEntity customer) {
    final bloc = context.read<DashboardBloc>();
    RejectionReasonDialogWidget.show(context, customer: customer).then((
      reason,
    ) {
      if (reason != null && reason.trim().isNotEmpty && context.mounted) {
        bloc.add(
          RejectPendingCustomerFromDashboardRequested(
            customerId: customer.id,
            reason: reason.trim(),
          ),
        );
      }
    });
  }

  void _onReviewCustomer(BuildContext context, CustomerEntity customer) {
    CustomerDetailsSheetWidget.show(
      context,
      customer: customer,
      onApprove: () => _onApproveCustomer(context, customer),
      onReject: () => _onRejectCustomer(context, customer),
    );
  }

  void _onQuickVerifyClaim(
    BuildContext context,
    PendingClaimItemEntity claim,
  ) {
    _navigateToScanPos(
      context,
      mode: 'verify_claim',
      code: claim.verificationCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<DashboardBloc, DashboardState>(
          listenWhen: (previous, current) {
            final successChanged =
                current.successMessage != null &&
                current.successMessage!.isNotEmpty &&
                previous.successMessage != current.successMessage;
            final actionErrorChanged =
                current.actionErrorMessage != null &&
                current.actionErrorMessage!.isNotEmpty &&
                previous.actionErrorMessage != current.actionErrorMessage;
            return successChanged || actionErrorChanged;
          },
          listener: (context, state) {
            final messenger = ScaffoldMessenger.of(context);
            messenger.hideCurrentSnackBar();
            if (state.actionErrorMessage != null &&
                state.actionErrorMessage!.isNotEmpty) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(state.actionErrorMessage!),
                  backgroundColor: AppColors.purered,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (state.successMessage != null &&
                state.successMessage!.isNotEmpty) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: AppColors.eifGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            final bloc = context.read<DashboardBloc>();

            if ((state.status == DashboardStatus.initial ||
                    state.status == DashboardStatus.loading) &&
                !state.hasLoadedOnce) {
              return const DashboardShimmerWidget();
            }

            if (state.status == DashboardStatus.error &&
                state.adminProfile.id.isEmpty &&
                state.masterLedger.isEmpty) {
              return DashboardErrorCardWidget(
                message: state.errorMessage,
                onRetry: () => bloc.add(const LoadDashboardRequested()),
              );
            }

            final hasUnread =
                state.pendingVerificationsCount > 0 ||
                state.pendingClaims.isNotEmpty;

            return RefreshIndicator(
              color: AppColors.linkBlue,
              onRefresh: () async {
                bloc.add(const RefreshDashboardRequested());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DashboardHeader(
                      adminProfile: state.adminProfile,
                      hasUnreadNotifications: hasUnread,
                      onNotificationPressed: () {
                        bloc.add(const RefreshDashboardRequested());
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Dashboard metrics & claims synced.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      onProfilePressed: () {
                        final router = GoRouter.maybeOf(context);
                        if (router != null) {
                          router.go(RouteNames.settingsRoute);
                        }
                      },
                    ),
                    const SizedBox(height: 18),
                    QuickActionCards(
                      onAddRewardPressed: () =>
                          _navigateToScanPos(context, mode: 'give_reward'),
                      onVerifyClaimPressed: () =>
                          _navigateToScanPos(context, mode: 'verify_claim'),
                    ),
                    const SizedBox(height: 16),
                    StatisticsGrid(statistics: state.statistics),
                    const SizedBox(height: 22),
                    UserVerificationsSection(
                      pendingCustomers: state.pendingVerifications,
                      totalPendingCount: state.pendingVerificationsCount,
                      approvingCustomerId: state.approvingCustomerId,
                      onViewAllPressed: () =>
                          _navigateToUserManagement(context, filter: 'pending'),
                      onApproveCustomer: (customer) =>
                          _onApproveCustomer(context, customer),
                      onReviewCustomer: (customer) =>
                          _onReviewCustomer(context, customer),
                    ),
                    const SizedBox(height: 22),
                    PendingClaimsSection(
                      pendingClaims: state.pendingClaims,
                      onQuickVerifyClaim: (claim) =>
                          _onQuickVerifyClaim(context, claim),
                      onClaimExpired: (claim) => bloc.add(
                        RemoveExpiredPendingClaimRequested(claim.id),
                      ),
                    ),
                    const SizedBox(height: 22),
                    MasterLedgerSection(
                      entries: state.masterLedger,
                      selectedFilter: state.selectedLedgerFilter,
                      isLoading: state.isLedgerFilterLoading,
                      onFilterChanged: (filter) => bloc.add(
                        ChangeLedgerCategoryFilterRequested(filter),
                      ),
                      onViewFullPressed: () =>
                          _navigateToFullMasterLedger(context, state),
                    ),
                    const SizedBox(height: 22),
                    TopPerformingUsersSection(users: state.topPerformingUsers),
                    const SizedBox(height: 22),
                    SystemActivitySection(activities: state.systemActivityLog),
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
