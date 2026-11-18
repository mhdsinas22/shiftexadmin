import 'package:shiftexadmin/features/scan_pos/domain/entities/pos_allocation_result_entity.dart';
import 'package:shiftexadmin/features/scan_pos/domain/entities/pos_transaction_entity.dart';
import 'package:shiftexadmin/features/scan_pos/domain/entities/verified_pos_customer_entity.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/entities/points_to_cash_config_entity.dart';

enum ScanPosStatus {
  initial,
  scanning,
  verifying,
  customerLoaded,
  allocating,
  success,
  error,
}

enum VerifyClaimStatus {
  initial,
  scanning,
  validating,
  claimLoaded,
  redeeming,
  redeemed,
  rejecting,
  rejected,
  flagged,
  expired,
  invalid,
  error,
}

class ScanPosState {
  final ScanPosStatus status;
  final VerifyClaimStatus verifyClaimStatus;
  final ScanPosMode mode;
  final PointsToCashConfigEntity? activeRateConfig;
  final VerifiedPosCustomerEntity? customer;
  final List<VerifiedPosCustomerEntity> searchResults;
  final bool isSearchingCustomers;
  final String instantPointsInput;
  final String futurePointsInput;
  final String redeemPointsInput;
  final String billNumberInput;
  final String branchName;
  final int unlockDays;
  final int expiryDays;
  final String? idempotencyKey;
  final PosAllocationResultEntity? lastAllocationResult;
  final PosClaimRedemptionResultEntity? lastClaimResult;
  final PosClaimRejectOrFlagResultEntity? lastRejectOrFlagResult;
  final List<PosTransactionEntity> recentTransactions;
  final bool isLoadingHistory;
  final bool isLoadingMoreHistory;
  final bool hasMoreHistory;
  final String errorMessage;
  final int errorNonce;
  final String? successMessage;

  const ScanPosState({
    this.status = ScanPosStatus.initial,
    this.verifyClaimStatus = VerifyClaimStatus.initial,
    this.mode = ScanPosMode.giveReward,
    this.activeRateConfig,
    this.customer,
    this.searchResults = const [],
    this.isSearchingCustomers = false,
    this.instantPointsInput = '250',
    this.futurePointsInput = '50',
    this.redeemPointsInput = '',
    this.billNumberInput = '',
    this.branchName = 'Counter #1 POS',
    this.unlockDays = 7,
    this.expiryDays = 365,
    this.idempotencyKey,
    this.lastAllocationResult,
    this.lastClaimResult,
    this.lastRejectOrFlagResult,
    this.recentTransactions = const [],
    this.isLoadingHistory = false,
    this.isLoadingMoreHistory = false,
    this.hasMoreHistory = true,
    this.errorMessage = '',
    this.errorNonce = 0,
    this.successMessage,
  });

  int get instantPoints => int.tryParse(instantPointsInput.trim()) ?? 0;
  int get futurePoints => int.tryParse(futurePointsInput.trim()) ?? 0;
  int get totalAllocationPoints => instantPoints + futurePoints;
  int get redeemPoints => int.tryParse(redeemPointsInput.trim()) ?? 0;

  int get pointsPerRupee =>
      activeRateConfig?.pointsPerRupee ?? customer?.pointsPerRupee ?? 10;

  double get pointsToInrRate =>
      PointsToCashConfigEntity.ratePerPoint(pointsPerRupee);

  double _cashFor(int points) => PointsToCashConfigEntity.inrFromPoints(
    points: points,
    pointsPerRupee: pointsPerRupee,
  );

  double get instantInr => _cashFor(instantPoints);
  double get futureInr => _cashFor(futurePoints);
  double get totalAllocationInr => _cashFor(totalAllocationPoints);

  double get redeemInr {
    final c = customer;
    if (c != null && c.hasClaimToken) {
      if (c.claimPoints == redeemPoints &&
          c.claimDiscountAmount != null &&
          c.claimDiscountAmount! > 0) {
        return c.claimDiscountAmount!;
      }
      return PointsToCashConfigEntity.inrFromPoints(
        points: redeemPoints,
        pointsPerRupee: c.pointsPerRupee,
      );
    }
    return _cashFor(redeemPoints);
  }

  bool get canAllocate =>
      customer != null &&
      customer!.isApproved &&
      totalAllocationPoints > 0 &&
      billNumberInput.trim().length >= 2 &&
      status != ScanPosStatus.allocating;

  bool get canRedeemClaim =>
      customer != null &&
      customer!.isApproved &&
      customer!.hasClaimToken &&
      customer!.auditChecks.allChecksPassed &&
      !customer!.isClaimExpiredAt() &&
      redeemPoints > 0 &&
      redeemPoints <= customer!.availablePoints &&
      billNumberInput.trim().length >= 2 &&
      status != ScanPosStatus.allocating &&
      verifyClaimStatus != VerifyClaimStatus.redeeming &&
      verifyClaimStatus != VerifyClaimStatus.rejecting &&
      verifyClaimStatus != VerifyClaimStatus.expired;

  ScanPosState copyWith({
    ScanPosStatus? status,
    VerifyClaimStatus? verifyClaimStatus,
    ScanPosMode? mode,
    PointsToCashConfigEntity? activeRateConfig,
    VerifiedPosCustomerEntity? customer,
    List<VerifiedPosCustomerEntity>? searchResults,
    bool? isSearchingCustomers,
    String? instantPointsInput,
    String? futurePointsInput,
    String? redeemPointsInput,
    String? billNumberInput,
    String? branchName,
    int? unlockDays,
    int? expiryDays,
    String? idempotencyKey,
    PosAllocationResultEntity? lastAllocationResult,
    PosClaimRedemptionResultEntity? lastClaimResult,
    PosClaimRejectOrFlagResultEntity? lastRejectOrFlagResult,
    List<PosTransactionEntity>? recentTransactions,
    bool? isLoadingHistory,
    bool? isLoadingMoreHistory,
    bool? hasMoreHistory,
    String? errorMessage,
    int? errorNonce,
    String? successMessage,
    bool clearCustomer = false,
    bool clearIdempotencyKey = false,
    bool clearSuccessMessage = false,
    bool clearLastResults = false,
  }) {
    return ScanPosState(
      status: status ?? this.status,
      verifyClaimStatus: verifyClaimStatus ?? this.verifyClaimStatus,
      mode: mode ?? this.mode,
      activeRateConfig: activeRateConfig ?? this.activeRateConfig,
      customer: clearCustomer ? null : (customer ?? this.customer),
      searchResults: searchResults ?? this.searchResults,
      isSearchingCustomers: isSearchingCustomers ?? this.isSearchingCustomers,
      instantPointsInput: instantPointsInput ?? this.instantPointsInput,
      futurePointsInput: futurePointsInput ?? this.futurePointsInput,
      redeemPointsInput: redeemPointsInput ?? this.redeemPointsInput,
      billNumberInput: billNumberInput ?? this.billNumberInput,
      branchName: branchName ?? this.branchName,
      unlockDays: unlockDays ?? this.unlockDays,
      expiryDays: expiryDays ?? this.expiryDays,
      idempotencyKey: clearIdempotencyKey
          ? null
          : (idempotencyKey ?? this.idempotencyKey),
      lastAllocationResult: clearLastResults
          ? null
          : (lastAllocationResult ?? this.lastAllocationResult),
      lastClaimResult: clearLastResults
          ? null
          : (lastClaimResult ?? this.lastClaimResult),
      lastRejectOrFlagResult: clearLastResults
          ? null
          : (lastRejectOrFlagResult ?? this.lastRejectOrFlagResult),
      recentTransactions: recentTransactions ?? this.recentTransactions,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      isLoadingMoreHistory: isLoadingMoreHistory ?? this.isLoadingMoreHistory,
      hasMoreHistory: hasMoreHistory ?? this.hasMoreHistory,
      errorMessage: errorMessage ?? this.errorMessage,
      errorNonce: errorNonce ?? this.errorNonce,
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}
