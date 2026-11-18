import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftexadmin/core/utils/app_logger.dart';
import 'package:shiftexadmin/features/scan_pos/domain/entities/pos_transaction_entity.dart';
import 'package:shiftexadmin/features/scan_pos/domain/entities/verified_pos_customer_entity.dart';
import 'package:shiftexadmin/features/scan_pos/domain/usecases/allocate_pos_points_usecase.dart';
import 'package:shiftexadmin/features/scan_pos/domain/usecases/get_pos_customer_wallet_usecase.dart';
import 'package:shiftexadmin/features/scan_pos/domain/usecases/get_pos_recent_transactions_usecase.dart';
import 'package:shiftexadmin/features/scan_pos/domain/usecases/redeem_customer_claim_qr_usecase.dart';
import 'package:shiftexadmin/features/scan_pos/domain/usecases/search_pos_customers_usecase.dart';
import 'package:shiftexadmin/features/scan_pos/domain/usecases/verify_customer_qr_usecase.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/bloc/scan_pos_event.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/bloc/scan_pos_state.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/entities/points_to_cash_config_entity.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/usecases/get_points_to_cash_config_usecase.dart';

class ScanPosBloc extends Bloc<ScanPosEvent, ScanPosState> {
  final VerifyCustomerQrUseCase verifyCustomerQrUseCase;
  final SearchPosCustomersUseCase searchPosCustomersUseCase;
  final GetPosCustomerWalletUseCase? getPosCustomerWalletUseCase;
  final AllocatePosPointsUseCase allocatePosPointsUseCase;
  final RedeemCustomerClaimQrUseCase redeemCustomerClaimQrUseCase;
  final GetPosRecentTransactionsUseCase getPosRecentTransactionsUseCase;
  final GetPointsToCashConfigUseCase? getPointsToCashConfigUseCase;

  static const int _pageSize = 15;

  String? _lastScannedPayload;
  DateTime? _lastScannedAt;
  int _requestSequence = 0;
  StreamSubscription<PointsToCashConfigEntity>? _rateSubscription;

  ScanPosBloc({
    required this.verifyCustomerQrUseCase,
    required this.searchPosCustomersUseCase,
    this.getPosCustomerWalletUseCase,
    required this.allocatePosPointsUseCase,
    required this.redeemCustomerClaimQrUseCase,
    required this.getPosRecentTransactionsUseCase,
    this.getPointsToCashConfigUseCase,
  }) : super(
         ScanPosState(activeRateConfig: getPointsToCashConfigUseCase?.cached),
       ) {
    on<InitializeScanPosRequested>(_onInitialize);
    on<RefreshPosRateConfigRequested>(_onRefreshRateConfig);
    on<RefreshSelectedCustomerWalletRequested>(_onRefreshCustomerWallet);
    on<CentralRateConfigUpdatedEvent>(_onCentralRateConfigUpdated);
    on<ScanPosModeChanged>(_onModeChanged);
    on<QrCodeDetectedEvent>(_onQrCodeDetected);
    on<ManualQrSubmittedEvent>(_onManualQrSubmitted);
    on<SearchCustomersQueryChanged>(_onSearchCustomers);
    on<ManualCustomerSelectedEvent>(_onManualCustomerSelected);
    on<InstantPointsChanged>(_onInstantPointsChanged);
    on<FuturePointsChanged>(_onFuturePointsChanged);
    on<RedeemPointsChanged>(_onRedeemPointsChanged);
    on<BillNumberChanged>(_onBillNumberChanged);
    on<BranchNameChanged>(_onBranchNameChanged);
    on<ConfirmAllocatePointsRequested>(_onConfirmAllocate);
    on<ConfirmRedeemClaimRequested>(_onConfirmRedeemClaim);
    on<LoadRecentTransactionsRequested>(_onLoadRecentTransactions);
    on<ClearSelectedCustomerRequested>(_onClearCustomer);

    _rateSubscription = getPointsToCashConfigUseCase?.stream.listen((config) {
      if (!isClosed) {
        add(CentralRateConfigUpdatedEvent(config));
      }
    });
  }

  @override
  Future<void> close() async {
    await _rateSubscription?.cancel();
    return super.close();
  }

  String _nextIdempotencyKey(String prefix) {
    _requestSequence++;
    return 'pos_${prefix}_${DateTime.now().microsecondsSinceEpoch}_$_requestSequence';
  }

  Future<void> _onInitialize(
    InitializeScanPosRequested event,
    Emitter<ScanPosState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ScanPosStatus.scanning,
        isLoadingHistory: true,
        errorMessage: '',
        clearSuccessMessage: true,
      ),
    );

    PointsToCashConfigEntity? centralConfig = state.activeRateConfig;
    if (getPointsToCashConfigUseCase != null) {
      try {
        centralConfig = await getPointsToCashConfigUseCase!.call();
      } catch (e) {
        AppLogger.warning('Could not load central conversion rate on init: $e');
      }
    }

    try {
      final history = await getPosRecentTransactionsUseCase(
        limit: _pageSize,
        offset: 0,
      );
      final updatedCustomer = centralConfig != null && state.customer != null
          ? state.customer!.copyWith(
              pointsPerRupee: centralConfig.pointsPerRupee,
              pointsToInrRate: centralConfig.cashValuePerPoint,
              currencyCode: centralConfig.currencyCode,
            )
          : state.customer;

      emit(
        state.copyWith(
          status: updatedCustomer != null
              ? ScanPosStatus.customerLoaded
              : ScanPosStatus.scanning,
          activeRateConfig: centralConfig,
          customer: updatedCustomer,
          recentTransactions: history,
          isLoadingHistory: false,
          hasMoreHistory: history.length >= _pageSize,
        ),
      );
    } catch (e) {
      AppLogger.warning('Could not load initial POS history: $e');
      emit(
        state.copyWith(
          status: state.customer != null
              ? ScanPosStatus.customerLoaded
              : ScanPosStatus.scanning,
          activeRateConfig: centralConfig,
          isLoadingHistory: false,
        ),
      );
    }
  }

  Future<void> _onRefreshRateConfig(
    RefreshPosRateConfigRequested event,
    Emitter<ScanPosState> emit,
  ) async {
    if (getPointsToCashConfigUseCase == null) return;
    try {
      final config = await getPointsToCashConfigUseCase!.call();
      _applyCentralRateConfig(config, emit);
    } catch (e) {
      AppLogger.warning('Could not refresh central POS conversion rate: $e');
    }
  }

  Future<void> _onRefreshCustomerWallet(
    RefreshSelectedCustomerWalletRequested event,
    Emitter<ScanPosState> emit,
  ) async {
    final customer = state.customer;
    if (customer == null || getPosCustomerWalletUseCase == null) return;
    try {
      final fresh = await getPosCustomerWalletUseCase!.call(
        customerId: customer.customerId,
      );
      emit(
        state.copyWith(
          customer: customer.copyWith(
            availablePoints: fresh.availablePoints,
            lockedPoints: fresh.lockedPoints,
            lifetimeEarnedPoints: fresh.lifetimeEarnedPoints,
            lifetimeRedeemedPoints: fresh.lifetimeRedeemedPoints,
            pointsPerRupee: fresh.pointsPerRupee,
            pointsToInrRate: fresh.pointsToInrRate,
            currencyCode: fresh.currencyCode,
          ),
        ),
      );
    } catch (e) {
      AppLogger.warning('Could not refresh customer wallet: $e');
    }
  }

  void _onCentralRateConfigUpdated(
    CentralRateConfigUpdatedEvent event,
    Emitter<ScanPosState> emit,
  ) {
    _applyCentralRateConfig(event.config, emit);
  }

  void _applyCentralRateConfig(
    PointsToCashConfigEntity config,
    Emitter<ScanPosState> emit,
  ) {
    final updatedCustomer = state.customer?.copyWith(
      pointsPerRupee: config.pointsPerRupee,
      pointsToInrRate: config.cashValuePerPoint,
      currencyCode: config.currencyCode,
    );
    emit(state.copyWith(activeRateConfig: config, customer: updatedCustomer));
  }

  void _onModeChanged(ScanPosModeChanged event, Emitter<ScanPosState> emit) {
    if (state.mode == event.mode) return;

    final current = state.customer;
    final bool keepCustomer =
        current != null &&
        ((event.mode == ScanPosMode.giveReward &&
                current.tokenPurpose != 'claim') ||
            (event.mode == ScanPosMode.verifyClaim && current.hasClaimToken));

    _lastScannedPayload = null;
    _lastScannedAt = null;

    emit(
      state.copyWith(
        mode: event.mode,
        status: keepCustomer
            ? ScanPosStatus.customerLoaded
            : ScanPosStatus.scanning,
        clearCustomer: !keepCustomer,
        clearIdempotencyKey: true,
        clearSuccessMessage: true,
        clearLastResults: true,
        errorMessage: '',
      ),
    );
  }

  Future<void> _onQrCodeDetected(
    QrCodeDetectedEvent event,
    Emitter<ScanPosState> emit,
  ) async {
    final trimmed = event.rawValue.trim();
    if (trimmed.isEmpty) return;

    // Debounce identical rapid camera scans and prevent re-entry during verification/allocation
    if (state.status == ScanPosStatus.verifying ||
        state.status == ScanPosStatus.allocating) {
      return;
    }

    final now = DateTime.now();
    if (_lastScannedPayload == trimmed &&
        _lastScannedAt != null &&
        now.difference(_lastScannedAt!) < const Duration(seconds: 4)) {
      return;
    }

    _lastScannedPayload = trimmed;
    _lastScannedAt = now;

    await _verifyQrInput(trimmed, emit);
  }

  Future<void> _onManualQrSubmitted(
    ManualQrSubmittedEvent event,
    Emitter<ScanPosState> emit,
  ) async {
    await _verifyQrInput(event.code.trim(), emit);
  }

  Future<void> _verifyQrInput(
    String rawInput,
    Emitter<ScanPosState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ScanPosStatus.verifying,
        errorMessage: '',
        clearSuccessMessage: true,
        clearLastResults: true,
      ),
    );

    try {
      final verified = await verifyCustomerQrUseCase(
        qrInput: rawInput,
        mode: state.mode,
      );

      final now = DateTime.now();
      final syncedRate =
          state.activeRateConfig?.copyWith(
            pointsPerRupee: verified.pointsPerRupee,
            pointsToInrRate: verified.pointsToInrRate,
            currencyCode: verified.currencyCode,
          ) ??
          PointsToCashConfigEntity(
            id: 'global',
            pointsPerRupee: verified.pointsPerRupee,
            pointsToInrRate: verified.pointsToInrRate,
            currencyCode: verified.currencyCode,
            effectiveAt: now,
            updatedAt: now,
          );

      emit(
        state.copyWith(
          status: ScanPosStatus.customerLoaded,
          activeRateConfig: syncedRate,
          customer: verified,
          idempotencyKey: _nextIdempotencyKey(verified.customerId),
          redeemPointsInput:
              verified.hasClaimToken && verified.availablePoints > 0
              ? (verified.claimPoints != null && verified.claimPoints! > 0
                    ? verified.claimPoints.toString()
                    : (verified.availablePoints >= 100
                          ? '100'
                          : verified.availablePoints.toString()))
              : '',
          errorMessage: '',
        ),
      );
    } catch (e) {
      AppLogger.warning('POS QR verification failed: $e');
      emit(
        state.copyWith(
          status: ScanPosStatus.error,
          errorNonce: state.errorNonce + 1,
          errorMessage: _cleanError(e),
        ),
      );
    }
  }

  Future<void> _onSearchCustomers(
    SearchCustomersQueryChanged event,
    Emitter<ScanPosState> emit,
  ) async {
    final query = event.query.trim();
    if (query.length < 2) {
      emit(
        state.copyWith(searchResults: const [], isSearchingCustomers: false),
      );
      return;
    }

    emit(state.copyWith(isSearchingCustomers: true, errorMessage: ''));

    try {
      final results = await searchPosCustomersUseCase(query: query);
      emit(state.copyWith(searchResults: results, isSearchingCustomers: false));
    } catch (e) {
      AppLogger.error('Customer search error: $e');
      emit(
        state.copyWith(
          isSearchingCustomers: false,
          errorMessage: _cleanError(e),
        ),
      );
    }
  }

  void _onManualCustomerSelected(
    ManualCustomerSelectedEvent event,
    Emitter<ScanPosState> emit,
  ) {
    if (!event.customer.isApproved) {
      emit(
        state.copyWith(
          status: ScanPosStatus.error,
          errorMessage:
              'Customer "${event.customer.fullName}" is ${event.customer.approvalStatus} and cannot receive POS rewards.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: ScanPosStatus.customerLoaded,
        customer: event.customer,
        searchResults: const [],
        idempotencyKey: _nextIdempotencyKey(event.customer.customerId),
        errorMessage: '',
        clearSuccessMessage: true,
        clearLastResults: true,
      ),
    );
  }

  void _onInstantPointsChanged(
    InstantPointsChanged event,
    Emitter<ScanPosState> emit,
  ) {
    final nextStatus =
        (state.status == ScanPosStatus.error ||
            state.status == ScanPosStatus.success)
        ? (state.customer != null
              ? ScanPosStatus.customerLoaded
              : ScanPosStatus.scanning)
        : state.status;
    final nextIdemKey =
        (state.status == ScanPosStatus.error && state.customer != null)
        ? _nextIdempotencyKey(state.customer!.customerId)
        : state.idempotencyKey;

    emit(
      state.copyWith(
        status: nextStatus,
        instantPointsInput: event.rawValue,
        idempotencyKey: nextIdemKey,
        errorMessage: '',
        clearSuccessMessage: true,
      ),
    );
  }

  void _onFuturePointsChanged(
    FuturePointsChanged event,
    Emitter<ScanPosState> emit,
  ) {
    final nextStatus =
        (state.status == ScanPosStatus.error ||
            state.status == ScanPosStatus.success)
        ? (state.customer != null
              ? ScanPosStatus.customerLoaded
              : ScanPosStatus.scanning)
        : state.status;
    final nextIdemKey =
        (state.status == ScanPosStatus.error && state.customer != null)
        ? _nextIdempotencyKey(state.customer!.customerId)
        : state.idempotencyKey;

    emit(
      state.copyWith(
        status: nextStatus,
        futurePointsInput: event.rawValue,
        idempotencyKey: nextIdemKey,
        errorMessage: '',
        clearSuccessMessage: true,
      ),
    );
  }

  void _onRedeemPointsChanged(
    RedeemPointsChanged event,
    Emitter<ScanPosState> emit,
  ) {
    final nextStatus =
        (state.status == ScanPosStatus.error ||
            state.status == ScanPosStatus.success)
        ? (state.customer != null
              ? ScanPosStatus.customerLoaded
              : ScanPosStatus.scanning)
        : state.status;

    emit(
      state.copyWith(
        status: nextStatus,
        redeemPointsInput: event.rawValue,
        errorMessage: '',
        clearSuccessMessage: true,
      ),
    );
  }

  void _onBillNumberChanged(
    BillNumberChanged event,
    Emitter<ScanPosState> emit,
  ) {
    final nextStatus =
        (state.status == ScanPosStatus.error ||
            state.status == ScanPosStatus.success)
        ? (state.customer != null
              ? ScanPosStatus.customerLoaded
              : ScanPosStatus.scanning)
        : state.status;
    final nextIdemKey =
        (state.status == ScanPosStatus.error && state.customer != null)
        ? _nextIdempotencyKey(state.customer!.customerId)
        : state.idempotencyKey;

    emit(
      state.copyWith(
        status: nextStatus,
        billNumberInput: event.billNumber,
        idempotencyKey: nextIdemKey,
        errorMessage: '',
        clearSuccessMessage: true,
      ),
    );
  }

  void _onBranchNameChanged(
    BranchNameChanged event,
    Emitter<ScanPosState> emit,
  ) {
    emit(state.copyWith(branchName: event.branchName));
  }

  Future<void> _onConfirmAllocate(
    ConfirmAllocatePointsRequested event,
    Emitter<ScanPosState> emit,
  ) async {
    // Prevent duplicate concurrent dispatch if user taps twice quickly
    if (state.status == ScanPosStatus.allocating) return;

    final customer = state.customer;
    if (customer == null) {
      emit(
        state.copyWith(
          status: ScanPosStatus.error,
          errorNonce: state.errorNonce + 1,
          errorMessage: 'Scan or select an approved customer first.',
        ),
      );
      return;
    }

    if (!customer.isApproved) {
      emit(
        state.copyWith(
          status: ScanPosStatus.error,
          errorNonce: state.errorNonce + 1,
          errorMessage: 'Customer account is not approved for rewards.',
        ),
      );
      return;
    }

    if (state.totalAllocationPoints <= 0) {
      emit(
        state.copyWith(
          status: ScanPosStatus.error,
          errorNonce: state.errorNonce + 1,
          errorMessage: 'Enter at least 1 Instant or Future point to allocate.',
        ),
      );
      return;
    }

    if (state.billNumberInput.trim().length < 2) {
      emit(
        state.copyWith(
          status: ScanPosStatus.error,
          errorNonce: state.errorNonce + 1,
          errorMessage: 'Please enter a valid Bill / Reference number.',
        ),
      );
      return;
    }

    final idemKey =
        state.idempotencyKey ?? _nextIdempotencyKey(customer.customerId);

    emit(
      state.copyWith(
        status: ScanPosStatus.allocating,
        idempotencyKey: idemKey,
        errorMessage: '',
        clearSuccessMessage: true,
      ),
    );

    try {
      final result = await allocatePosPointsUseCase(
        customerId: customer.customerId,
        instantPoints: state.instantPoints,
        futurePoints: state.futurePoints,
        billNumber: state.billNumberInput.trim(),
        branchName: state.branchName,
        tokenId: customer.tokenId,
        idempotencyKey: idemKey,
        unlockDays: state.unlockDays,
        expiryDays: state.expiryDays,
      );

      // Re-query authoritative customer wallet from Supabase to confirm persistence
      VerifiedPosCustomerEntity? verifiedWallet;
      if (getPosCustomerWalletUseCase != null) {
        try {
          verifiedWallet = await getPosCustomerWalletUseCase!(
            customerId: customer.customerId,
          );
        } catch (e) {
          AppLogger.warning(
            'Post-allocation wallet re-fetch warning (using authoritative RPC return): $e',
          );
        }
      }

      final refreshedCustomer = customer.copyWith(
        availablePoints:
            verifiedWallet?.availablePoints ?? result.availablePoints,
        lockedPoints: verifiedWallet?.lockedPoints ?? result.lockedPoints,
        lifetimeEarnedPoints:
            verifiedWallet?.lifetimeEarnedPoints ?? result.lifetimeEarnedPoints,
        lifetimeRedeemedPoints:
            verifiedWallet?.lifetimeRedeemedPoints ??
            result.lifetimeRedeemedPoints,
        pointsPerRupee: verifiedWallet?.pointsPerRupee ?? result.pointsPerRupee,
        pointsToInrRate:
            verifiedWallet?.pointsToInrRate ?? result.pointsToInrRate,
        currencyCode: verifiedWallet?.currencyCode ?? result.currencyCode,
      );

      final syncedRate =
          state.activeRateConfig?.copyWith(
            pointsPerRupee: result.pointsPerRupee,
            pointsToInrRate: result.pointsToInrRate,
            currencyCode: result.currencyCode,
          ) ??
          PointsToCashConfigEntity(
            id: 'global',
            pointsPerRupee: result.pointsPerRupee,
            pointsToInrRate: result.pointsToInrRate,
            currencyCode: result.currencyCode,
            effectiveAt: result.allocatedAt,
            updatedAt: result.allocatedAt,
          );

      List<PosTransactionEntity> history = state.recentTransactions;
      bool hasMoreHistory = state.hasMoreHistory;
      try {
        history = await getPosRecentTransactionsUseCase(
          limit: _pageSize,
          offset: 0,
        );
        hasMoreHistory = history.length >= _pageSize;
      } catch (e) {
        AppLogger.warning('Post-allocation history refresh warning: $e');
      }

      emit(
        state.copyWith(
          status: ScanPosStatus.success,
          activeRateConfig: syncedRate,
          customer: refreshedCustomer,
          lastAllocationResult: result,
          recentTransactions: history,
          hasMoreHistory: hasMoreHistory,
          // Rotate idempotency key and clear previous allocation form after verified commit
          idempotencyKey: _nextIdempotencyKey(customer.customerId),
          instantPointsInput: '',
          futurePointsInput: '',
          billNumberInput: '',
          errorMessage: '',
          successMessage:
              'Allocated ${result.totalPointsAllocated} pts (₹${result.totalInrEquivalent.toStringAsFixed(2)}) to ${result.fullName} • Bill #${result.billNumber}',
        ),
      );
    } catch (e) {
      AppLogger.error('Error allocating points: $e');
      emit(
        state.copyWith(
          status: ScanPosStatus.error,
          errorNonce: state.errorNonce + 1,
          errorMessage: _cleanError(e),
        ),
      );
    }
  }

  Future<void> _onConfirmRedeemClaim(
    ConfirmRedeemClaimRequested event,
    Emitter<ScanPosState> emit,
  ) async {
    if (state.status == ScanPosStatus.allocating) return;

    final customer = state.customer;
    if (customer == null || !customer.hasClaimToken) {
      emit(
        state.copyWith(
          status: ScanPosStatus.error,
          errorNonce: state.errorNonce + 1,
          errorMessage:
              'Scan a valid Customer Claim QR before verifying redemption.',
        ),
      );
      return;
    }

    if (state.redeemPoints <= 0) {
      emit(
        state.copyWith(
          status: ScanPosStatus.error,
          errorNonce: state.errorNonce + 1,
          errorMessage: 'Enter points to redeem (> 0).',
        ),
      );
      return;
    }

    if (state.redeemPoints > customer.availablePoints) {
      emit(
        state.copyWith(
          status: ScanPosStatus.error,
          errorNonce: state.errorNonce + 1,
          errorMessage:
              'Insufficient instant wallet balance (${customer.availablePoints} pts available).',
        ),
      );
      return;
    }

    if (state.billNumberInput.trim().length < 2) {
      emit(
        state.copyWith(
          status: ScanPosStatus.error,
          errorNonce: state.errorNonce + 1,
          errorMessage: 'Please enter a valid Bill / Reference number.',
        ),
      );
      return;
    }

    final idemKey =
        state.idempotencyKey ??
        _nextIdempotencyKey('claim_${customer.tokenId}');

    emit(
      state.copyWith(
        status: ScanPosStatus.allocating,
        idempotencyKey: idemKey,
        errorMessage: '',
        clearSuccessMessage: true,
      ),
    );

    try {
      final result = await redeemCustomerClaimQrUseCase(
        tokenId: customer.tokenId!,
        redeemPoints: state.redeemPoints,
        billNumber: state.billNumberInput.trim(),
        branchName: state.branchName,
        idempotencyKey: idemKey,
      );

      List<PosTransactionEntity> history = state.recentTransactions;
      bool hasMoreHistory = state.hasMoreHistory;
      try {
        history = await getPosRecentTransactionsUseCase(
          limit: _pageSize,
          offset: 0,
        );
        hasMoreHistory = history.length >= _pageSize;
      } catch (e) {
        AppLogger.warning('Post-claim history refresh warning: $e');
      }

      // Claim QR is single-use: clear consumed token after completion
      emit(
        state.copyWith(
          status: ScanPosStatus.success,
          clearCustomer: true,
          lastClaimResult: result,
          recentTransactions: history,
          hasMoreHistory: hasMoreHistory,
          clearIdempotencyKey: true,
          redeemPointsInput: '',
          billNumberInput: '',
          successMessage:
              'Claim verified! Redeemed ${result.redeemedPoints} pts (₹${result.inrValue.toStringAsFixed(2)}) for ${result.fullName}.',
        ),
      );
    } catch (e) {
      AppLogger.error('Error redeeming claim QR: $e');
      emit(
        state.copyWith(
          status: ScanPosStatus.error,
          errorNonce: state.errorNonce + 1,
          errorMessage: _cleanError(e),
        ),
      );
    }
  }

  Future<void> _onLoadRecentTransactions(
    LoadRecentTransactionsRequested event,
    Emitter<ScanPosState> emit,
  ) async {
    if (event.loadMore &&
        (!state.hasMoreHistory || state.isLoadingMoreHistory)) {
      return;
    }

    final offset = event.loadMore ? state.recentTransactions.length : 0;

    emit(
      state.copyWith(
        isLoadingHistory: !event.loadMore,
        isLoadingMoreHistory: event.loadMore,
      ),
    );

    try {
      final page = await getPosRecentTransactionsUseCase(
        limit: _pageSize,
        offset: offset,
      );

      final combined = event.loadMore
          ? [...state.recentTransactions, ...page]
          : page;

      emit(
        state.copyWith(
          recentTransactions: combined,
          isLoadingHistory: false,
          isLoadingMoreHistory: false,
          hasMoreHistory: page.length >= _pageSize,
        ),
      );
    } catch (e) {
      AppLogger.error('Error loading recent POS transactions: $e');
      emit(
        state.copyWith(
          isLoadingHistory: false,
          isLoadingMoreHistory: false,
          errorMessage: _cleanError(e),
        ),
      );
    }
  }

  void _onClearCustomer(
    ClearSelectedCustomerRequested event,
    Emitter<ScanPosState> emit,
  ) {
    _lastScannedPayload = null;
    _lastScannedAt = null;
    emit(
      state.copyWith(
        status: ScanPosStatus.scanning,
        clearCustomer: true,
        clearIdempotencyKey: true,
        clearSuccessMessage: true,
        clearLastResults: true,
        errorMessage: '',
      ),
    );
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceFirst(RegExp(r'^Invalid argument\(s\):\s*'), '');
  }
}
