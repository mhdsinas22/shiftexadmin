import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/core/di/injection_container.dart';
import 'package:shiftexadmin/core/routes/route_names.dart';
import 'package:shiftexadmin/features/scan_pos/domain/entities/verified_pos_customer_entity.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/bloc/scan_pos_bloc.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/bloc/scan_pos_event.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/bloc/scan_pos_state.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/widgets/allocation_confirmation_dialog.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/widgets/customer_details_card.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/widgets/manual_qr_code_dialog.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/widgets/points_allocation_card.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/widgets/pos_camera_scanner.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/widgets/pos_customer_search_sheet.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/widgets/recent_scan_history.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/widgets/scan_pos_header_widget.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/widgets/scan_pos_prompt_card.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/widgets/scan_pos_shimmer_widget.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/widgets/verify_claim_card_widget.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/widgets/wallet_balance_card.dart';

class ScanPosPage extends StatelessWidget {
  final bool enableCamera;
  final ScanPosMode? initialMode;
  final String? initialQrCode;
  final String? navigationNonce;

  const ScanPosPage({
    super.key,
    this.enableCamera = true,
    this.initialMode,
    this.initialQrCode,
    this.navigationNonce,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ScanPosBloc>(
      create: (_) =>
          getIt<ScanPosBloc>()..add(const InitializeScanPosRequested()),
      child: ScanPosView(
        enableCamera: enableCamera,
        initialMode: initialMode,
        initialQrCode: initialQrCode,
        navigationNonce: navigationNonce,
      ),
    );
  }
}

class ScanPosView extends StatefulWidget {
  final bool enableCamera;
  final ScanPosMode? initialMode;
  final String? initialQrCode;
  final String? navigationNonce;

  const ScanPosView({
    super.key,
    this.enableCamera = true,
    this.initialMode,
    this.initialQrCode,
    this.navigationNonce,
  });

  @override
  State<ScanPosView> createState() => _ScanPosViewState();
}

class _ScanPosViewState extends State<ScanPosView> {
  bool _isConfirmDialogOpen = false;
  String? _lastAppliedNonce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _applyNavigationIntent();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ScanPosView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialMode != oldWidget.initialMode ||
        widget.initialQrCode != oldWidget.initialQrCode ||
        widget.navigationNonce != oldWidget.navigationNonce) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _applyNavigationIntent();
        }
      });
    }
  }

  void _applyNavigationIntent() {
    final nonceKey =
        '${widget.initialMode?.name ?? ''}:${widget.initialQrCode ?? ''}:${widget.navigationNonce ?? ''}';
    if (nonceKey == '::' || _lastAppliedNonce == nonceKey) return;
    _lastAppliedNonce = nonceKey;

    final bloc = context.read<ScanPosBloc>();
    if (widget.initialMode != null) {
      bloc.add(ScanPosModeChanged(widget.initialMode!));
    }
    final code = widget.initialQrCode?.trim() ?? '';
    if (code.isNotEmpty) {
      bloc.add(ManualQrSubmittedEvent(code));
    }
  }

  Future<void> _openManualQrDialog(
    BuildContext context,
    ScanPosMode mode,
  ) async {
    final bloc = context.read<ScanPosBloc>();
    final code = await ManualQrCodeDialog.show(context, mode: mode);
    if (code != null && code.trim().isNotEmpty && context.mounted) {
      bloc.add(ManualQrSubmittedEvent(code));
    }
  }

  Future<void> _confirmAllocation(
    BuildContext context,
    ScanPosState state,
  ) async {
    if (state.status == ScanPosStatus.allocating || _isConfirmDialogOpen) {
      return;
    }

    final customer = state.customer;
    final bloc = context.read<ScanPosBloc>();
    if (customer == null) return;

    // Surface clear validation feedback rather than silently ignoring missing Bill # or 0 pts
    if (!state.canAllocate) {
      FocusScope.of(context).unfocus();
      bloc.add(const ConfirmAllocatePointsRequested());
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isConfirmDialogOpen = true);
    try {
      await AllocationConfirmationDialog.show(
        context,
        customer: customer,
        instantPoints: state.instantPoints,
        futurePoints: state.futurePoints,
        totalInr: state.totalAllocationInr,
        billNumber: state.billNumberInput.trim(),
        branchName: state.branchName,
        onConfirm: () {
          bloc.add(const ConfirmAllocatePointsRequested());
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isConfirmDialogOpen = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<ScanPosBloc, ScanPosState>(
          listenWhen: (previous, current) {
            final errorChanged =
                current.status == ScanPosStatus.error &&
                current.errorMessage.isNotEmpty &&
                (previous.errorNonce != current.errorNonce ||
                    previous.status != current.status ||
                    previous.errorMessage != current.errorMessage);
            final successChanged =
                current.status == ScanPosStatus.success &&
                current.successMessage != null &&
                (previous.status != current.status ||
                    previous.successMessage != current.successMessage);
            return errorChanged || successChanged;
          },
          listener: (context, state) {
            final messenger = ScaffoldMessenger.of(context);
            messenger.hideCurrentSnackBar();
            if (state.status == ScanPosStatus.error &&
                state.errorMessage.isNotEmpty) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage),
                  backgroundColor: AppColors.purered,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (state.status == ScanPosStatus.success &&
                state.successMessage != null) {
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
            final bloc = context.read<ScanPosBloc>();

            return RefreshIndicator(
              color: AppColors.linkBlue,
              onRefresh: () async {
                bloc.add(const RefreshPosRateConfigRequested());
                bloc.add(const LoadRecentTransactionsRequested());
                if (state.customer != null) {
                  bloc.add(const RefreshSelectedCustomerWalletRequested());
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ScanPosHeaderWidget(
                      selectedMode: state.mode,
                      onModeChanged: (mode) =>
                          bloc.add(ScanPosModeChanged(mode)),
                      onNotificationPressed: () {
                        bloc.add(const RefreshPosRateConfigRequested());
                        bloc.add(const LoadRecentTransactionsRequested());
                        if (state.customer != null) {
                          bloc.add(
                            const RefreshSelectedCustomerWalletRequested(),
                          );
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'POS rate & terminal ledger refreshed.',
                            ),
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
                    const SizedBox(height: 16),
                    PosCameraScanner(
                      mode: state.mode,
                      isVerifying: state.status == ScanPosStatus.verifying,
                      enableCamera: widget.enableCamera,
                      onQrDetected: (raw) => bloc.add(QrCodeDetectedEvent(raw)),
                      onEnterCodeManuallyPressed: () =>
                          _openManualQrDialog(context, state.mode),
                      onPhoneOrIdSearchPressed: () =>
                          PosCustomerSearchSheet.show(context, bloc: bloc),
                    ),
                    const SizedBox(height: 16),
                    if (state.status == ScanPosStatus.verifying &&
                        state.customer == null)
                      const ScanPosCustomerShimmerWidget()
                    else if (state.customer != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.pureWhite,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.cardShadow,
                              blurRadius: 14,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CustomerDetailsCard(
                              customer: state.customer!,
                              onClearPressed: () => bloc.add(
                                const ClearSelectedCustomerRequested(),
                              ),
                            ),
                            const SizedBox(height: 14),
                            WalletBalanceCard(customer: state.customer!),
                            const SizedBox(height: 16),
                            if (state.mode == ScanPosMode.giveReward)
                              PointsAllocationCard(
                                state: state,
                                onInstantPointsChanged: (val) =>
                                    bloc.add(InstantPointsChanged(val)),
                                onFuturePointsChanged: (val) =>
                                    bloc.add(FuturePointsChanged(val)),
                                onBillNumberChanged: (val) =>
                                    bloc.add(BillNumberChanged(val)),
                                onConfirmPressed: () =>
                                    _confirmAllocation(context, state),
                              )
                            else
                              VerifyClaimCardWidget(
                                state: state,
                                onRedeemPointsChanged: (val) =>
                                    bloc.add(RedeemPointsChanged(val)),
                                onBillNumberChanged: (val) =>
                                    bloc.add(BillNumberChanged(val)),
                                onConfirmRedeemPressed: () => bloc.add(
                                  const ConfirmRedeemClaimRequested(),
                                ),
                              ),
                          ],
                        ),
                      )
                    else
                      ScanPosPromptCard(
                        mode: state.mode,
                        onEnterCodePressed: () =>
                            _openManualQrDialog(context, state.mode),
                        onSearchPressed: () =>
                            PosCustomerSearchSheet.show(context, bloc: bloc),
                      ),
                    const SizedBox(height: 20),
                    RecentScanHistory(
                      transactions: state.recentTransactions,
                      branchName: state.branchName,
                      isLoading: state.isLoadingHistory,
                      isLoadingMore: state.isLoadingMoreHistory,
                      hasMore: state.hasMoreHistory,
                      onLoadMore: state.hasMoreHistory
                          ? () => bloc.add(
                              const LoadRecentTransactionsRequested(
                                loadMore: true,
                              ),
                            )
                          : null,
                    ),
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
