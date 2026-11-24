import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftexadmin/features/scan_pos/domain/entities/pos_allocation_result_entity.dart';
import 'package:shiftexadmin/features/scan_pos/domain/entities/pos_transaction_entity.dart';
import 'package:shiftexadmin/features/scan_pos/domain/entities/verified_pos_customer_entity.dart';
import 'package:shiftexadmin/features/scan_pos/domain/repositories/scan_pos_repository.dart';
import 'package:shiftexadmin/features/scan_pos/domain/usecases/allocate_pos_points_usecase.dart';
import 'package:shiftexadmin/features/scan_pos/domain/usecases/get_pos_customer_wallet_usecase.dart';
import 'package:shiftexadmin/features/scan_pos/domain/usecases/get_pos_recent_transactions_usecase.dart';
import 'package:shiftexadmin/features/scan_pos/domain/usecases/redeem_customer_claim_qr_usecase.dart';
import 'package:shiftexadmin/features/scan_pos/domain/usecases/reject_or_flag_claim_qr_usecase.dart';
import 'package:shiftexadmin/features/scan_pos/domain/usecases/search_pos_customers_usecase.dart';
import 'package:shiftexadmin/features/scan_pos/domain/usecases/verify_customer_qr_usecase.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/bloc/scan_pos_bloc.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/bloc/scan_pos_event.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/bloc/scan_pos_state.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/pages/scan_pos_page.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/widgets/claim_audit_checks_widget.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/widgets/recent_scan_history.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/widgets/verify_claim_card_widget.dart';

class FakeScanPosRepository implements ScanPosRepository {
  int verifyCallCount = 0;
  int allocateCallCount = 0;
  int getWalletCallCount = 0;
  int redeemCallCount = 0;
  int rejectOrFlagCallCount = 0;
  int searchCallCount = 0;
  int historyCallCount = 0;

  String? lastVerifyQrInput;
  ScanPosMode? lastVerifyMode;
  String? lastIdempotencyKey;
  int? lastInstantPoints;
  int? lastFuturePoints;
  String? lastRejectOrFlagAction;
  String? lastRejectOrFlagReason;

  Object? verifyError;
  Object? allocateError;
  Object? redeemError;
  Object? rejectOrFlagError;
  Object? historyError;

  Completer<PosAllocationResultEntity>? pendingAllocateCompleter;

  VerifiedPosCustomerEntity sampleCustomer = const VerifiedPosCustomerEntity(
    customerId: 'cust-1',
    fullName: 'Vishnu K.',
    email: 'vishnu@shiftex.in',
    mobileNumber: '+91 98765 43210',
    approvalStatus: 'approved',
    membershipId: 'SHFT-8921-VK',
    availablePoints: 2450,
    lockedPoints: 550,
    lifetimeEarnedPoints: 3200,
    lifetimeRedeemedPoints: 200,
    pointsToInrRate: 0.10,
    tokenId: 'tok-acc-1',
    tokenCode: 'ACC-1122-3344',
    qrPayload: 'SHIIFTEX:ACCRUAL:V1:ACC-1122-3344:AABBCCDD11223344',
    tokenPurpose: 'accrual',
    allowDeduction: false,
    verificationMethod: 'qr',
  );

  VerifiedPosCustomerEntity sampleClaimCustomer = VerifiedPosCustomerEntity(
    customerId: 'cust-2',
    fullName: 'Arjun S.',
    email: 'arjun@shiftex.in',
    mobileNumber: '+91 91234 56789',
    approvalStatus: 'approved',
    membershipId: 'SHFT-4455-AS',
    membershipTier: 'Gold Tier',
    availablePoints: 1200,
    reservedPoints: 200,
    lockedPoints: 300,
    pointsPerRupee: 10,
    pointsToInrRate: 0.10,
    tokenId: 'tok-clm-1',
    tokenCode: 'CLM-8812',
    qrPayload: 'SHIIFTEX:CLAIM:V1:CLM-8812:AABBCCDD1122',
    tokenPurpose: 'claim',
    allowDeduction: true,
    tokenCreatedAt: DateTime.now().subtract(const Duration(minutes: 1)),
    tokenExpiresAt: DateTime.now().add(const Duration(minutes: 4)),
    verificationMethod: 'qr',
    claimId: 'claim-uuid-8812',
    claimReference: 'CLM-8812',
    claimStatus: 'pending',
    claimAuditStatus: 'verified',
    claimPoints: 200,
    claimDiscountAmount: 20.0,
    rewardName: 'Instant POS Bill Discount',
    rewardCategory: 'POS Bill Discount',
    merchantName: 'ShiftEx Partner Store',
    orderReference: 'Bill #49022',
    auditChecks: const ClaimAuditChecksEntity(
      tokenSignatureValid: true,
      claimNotExpired: true,
      singleUsePassed: true,
      replayProtectionPassed: true,
      customerEligible: true,
      balanceReservationValid: true,
    ),
  );

  List<PosTransactionEntity> storedHistory = [
    PosTransactionEntity(
      id: 'tx-1',
      customerId: 'cust-3',
      customerName: 'Priya N.',
      membershipId: 'SHFT-3104',
      tokenCode: 'SHFT-3104',
      transactionType: 'merchant_reward',
      title: 'POS Points Allocation',
      description: 'Allocated 180 pts • Bill #49020',
      pointsDelta: 180,
      isLockedAllocation: false,
      billNumber: 'Bill #49020',
      branchName: 'Counter #2 POS',
      inrEquivalent: 18.00,
      status: 'completed',
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
    PosTransactionEntity(
      id: 'tx-2',
      customerId: 'cust-2',
      customerName: 'Arjun S.',
      membershipId: 'SHFT-4455-AS',
      tokenCode: 'CLM-8812',
      transactionType: 'discount_redemption',
      title: 'Redeemed Free Cappuccino',
      description: 'Redeemed Free Cappuccino',
      pointsDelta: -200,
      isLockedAllocation: false,
      billNumber: 'Bill #49019',
      branchName: 'Counter #2 POS',
      inrEquivalent: 20.00,
      status: 'completed',
      createdAt: DateTime.now().subtract(const Duration(minutes: 7)),
    ),
  ];

  @override
  Future<VerifiedPosCustomerEntity> verifyCustomerQr({
    required String qrInput,
    required ScanPosMode mode,
  }) async {
    verifyCallCount++;
    lastVerifyQrInput = qrInput;
    lastVerifyMode = mode;
    if (verifyError != null) throw verifyError!;
    return mode == ScanPosMode.verifyClaim
        ? sampleClaimCustomer
        : sampleCustomer;
  }

  @override
  Future<List<VerifiedPosCustomerEntity>> searchCustomers({
    required String query,
    int limit = 10,
  }) async {
    searchCallCount++;
    return [sampleCustomer];
  }

  @override
  Future<VerifiedPosCustomerEntity> getCustomerWallet({
    required String customerId,
  }) async {
    getWalletCallCount++;
    if (customerId == sampleClaimCustomer.customerId) {
      return sampleClaimCustomer;
    }
    return sampleCustomer;
  }

  @override
  Future<PosAllocationResultEntity> allocatePoints({
    required String customerId,
    required int instantPoints,
    required int futurePoints,
    required String billNumber,
    required String branchName,
    String? tokenId,
    required String idempotencyKey,
    int unlockDays = 7,
    int expiryDays = 365,
  }) async {
    allocateCallCount++;
    lastInstantPoints = instantPoints;
    lastFuturePoints = futurePoints;
    lastIdempotencyKey = idempotencyKey;

    if (pendingAllocateCompleter != null) {
      return pendingAllocateCompleter!.future;
    }
    if (allocateError != null) throw allocateError!;

    final updatedAvailable = sampleCustomer.availablePoints + instantPoints;
    final updatedLocked = sampleCustomer.lockedPoints + futurePoints;
    sampleCustomer = sampleCustomer.copyWith(
      availablePoints: updatedAvailable,
      lockedPoints: updatedLocked,
      lifetimeEarnedPoints:
          sampleCustomer.lifetimeEarnedPoints + instantPoints + futurePoints,
    );

    return PosAllocationResultEntity(
      success: true,
      customerId: customerId,
      fullName: sampleCustomer.fullName,
      membershipId: sampleCustomer.membershipId,
      instantPointsAllocated: instantPoints,
      futurePointsAllocated: futurePoints,
      totalPointsAllocated: instantPoints + futurePoints,
      totalInrEquivalent: (instantPoints + futurePoints) * 0.10,
      billNumber: billNumber,
      branchName: branchName,
      availablePoints: updatedAvailable,
      lockedPoints: updatedLocked,
      lifetimeEarnedPoints: sampleCustomer.lifetimeEarnedPoints,
      lifetimeRedeemedPoints: sampleCustomer.lifetimeRedeemedPoints,
      instantTransactionId: instantPoints > 0 ? 'tx-inst-1' : null,
      futureTransactionId: futurePoints > 0 ? 'tx-fut-1' : null,
      futureAllocationId: futurePoints > 0 ? 'alloc-1' : null,
      unlockAt: futurePoints > 0
          ? DateTime.now().add(Duration(days: unlockDays))
          : null,
      allocatedAt: DateTime.now(),
    );
  }

  @override
  Future<PosClaimRedemptionResultEntity> redeemClaimQr({
    required String tokenId,
    required int redeemPoints,
    required String billNumber,
    required String branchName,
    required String idempotencyKey,
  }) async {
    redeemCallCount++;
    if (redeemError != null) throw redeemError!;

    final updatedAvailable = sampleClaimCustomer.availablePoints - redeemPoints;
    sampleClaimCustomer = sampleClaimCustomer.copyWith(
      availablePoints: updatedAvailable,
      reservedPoints: 0,
      lifetimeRedeemedPoints:
          sampleClaimCustomer.lifetimeRedeemedPoints + redeemPoints,
    );

    return PosClaimRedemptionResultEntity(
      success: true,
      customerId: sampleClaimCustomer.customerId,
      fullName: sampleClaimCustomer.fullName,
      membershipId: sampleClaimCustomer.membershipId,
      tokenCode: 'CLM-8812',
      redeemedPoints: redeemPoints,
      inrValue: redeemPoints * 0.10,
      billNumber: billNumber,
      branchName: branchName,
      availablePoints: updatedAvailable,
      lockedPoints: sampleClaimCustomer.lockedPoints,
      lifetimeRedeemedPoints: sampleClaimCustomer.lifetimeRedeemedPoints,
      transactionId: 'tx-redeem-1',
      redeemedAt: DateTime.now(),
    );
  }

  @override
  Future<PosClaimRejectOrFlagResultEntity> rejectOrFlagClaimQr({
    required String tokenId,
    required String action,
    required String reason,
    required String branchName,
  }) async {
    rejectOrFlagCallCount++;
    lastRejectOrFlagAction = action;
    lastRejectOrFlagReason = reason;
    if (rejectOrFlagError != null) throw rejectOrFlagError!;

    sampleClaimCustomer = sampleClaimCustomer.copyWith(
      reservedPoints: 0,
    );

    return PosClaimRejectOrFlagResultEntity(
      success: true,
      action: action,
      auditStatus: action == 'flag' ? 'flagged' : 'rejected',
      tokenId: tokenId,
      claimId: sampleClaimCustomer.claimId,
      claimReference: 'CLM-8812',
      reason: reason,
      branchName: branchName,
      availablePoints: sampleClaimCustomer.availablePoints,
      reservedPoints: 0,
      processedAt: DateTime.now(),
    );
  }

  @override
  Future<List<PosTransactionEntity>> getRecentTransactions({
    int limit = 15,
    int offset = 0,
  }) async {
    historyCallCount++;
    if (historyError != null) throw historyError!;
    if (offset >= storedHistory.length) return const [];
    final end = (offset + limit) > storedHistory.length
        ? storedHistory.length
        : offset + limit;
    return storedHistory.sublist(offset, end);
  }
}

ScanPosBloc _buildBloc(FakeScanPosRepository repo) {
  return ScanPosBloc(
    verifyCustomerQrUseCase: VerifyCustomerQrUseCase(repository: repo),
    searchPosCustomersUseCase: SearchPosCustomersUseCase(repository: repo),
    getPosCustomerWalletUseCase: GetPosCustomerWalletUseCase(repository: repo),
    allocatePosPointsUseCase: AllocatePosPointsUseCase(repository: repo),
    redeemCustomerClaimQrUseCase: RedeemCustomerClaimQrUseCase(repository: repo),
    rejectOrFlagClaimQrUseCase: RejectOrFlagClaimQrUseCase(repo),
    getPosRecentTransactionsUseCase:
        GetPosRecentTransactionsUseCase(repository: repo),
  );
}

void main() {
  group('Domain Use Cases Validation', () {
    late FakeScanPosRepository repo;

    setUp(() {
      repo = FakeScanPosRepository();
    });

    test('VerifyCustomerQrUseCase rejects empty QR and raw customer UUIDs', () async {
      final useCase = VerifyCustomerQrUseCase(repository: repo);

      expect(
        () => useCase(qrInput: '   ', mode: ScanPosMode.giveReward),
        throwsArgumentError,
      );
      expect(
        () => useCase(
          qrInput: '550e8400-e29b-41d4-a716-446655440000',
          mode: ScanPosMode.giveReward,
        ),
        throwsArgumentError,
      );

      final verified = await useCase(
        qrInput: '  SHIIFTEX:ACCRUAL:V1:ACC-1122-3344:AABBCCDD11223344  ',
        mode: ScanPosMode.giveReward,
      );
      expect(verified.membershipId, 'SHFT-8921-VK');
      expect(
        repo.lastVerifyQrInput,
        'SHIIFTEX:ACCRUAL:V1:ACC-1122-3344:AABBCCDD11223344',
      );
    });

    test('AllocatePosPointsUseCase enforces positive points and bill reference', () async {
      final useCase = AllocatePosPointsUseCase(repository: repo);

      expect(
        () => useCase(
          customerId: 'cust-1',
          instantPoints: 0,
          futurePoints: 0,
          billNumber: 'Bill #49021',
          branchName: 'Counter #1',
          idempotencyKey: 'key-1',
        ),
        throwsArgumentError,
      );

      expect(
        () => useCase(
          customerId: 'cust-1',
          instantPoints: -10,
          futurePoints: 50,
          billNumber: 'Bill #49021',
          branchName: 'Counter #1',
          idempotencyKey: 'key-1',
        ),
        throwsArgumentError,
      );

      expect(
        () => useCase(
          customerId: 'cust-1',
          instantPoints: 100,
          futurePoints: 50,
          billNumber: 'A',
          branchName: 'Counter #1',
          idempotencyKey: 'key-1',
        ),
        throwsArgumentError,
      );

      final res = await useCase(
        customerId: 'cust-1',
        instantPoints: 250,
        futurePoints: 50,
        billNumber: '  Bill #49021  ',
        branchName: 'Counter #2 POS',
        idempotencyKey: 'idem-1',
      );
      expect(res.totalPointsAllocated, 300);
      expect(res.billNumber, 'Bill #49021');
    });

    test('RedeemCustomerClaimQrUseCase validates token and redeem points', () async {
      final useCase = RedeemCustomerClaimQrUseCase(repository: repo);

      expect(
        () => useCase(
          tokenId: '',
          redeemPoints: 100,
          billNumber: 'Bill #49021',
          branchName: 'Counter #1 POS',
          idempotencyKey: 'idem-2',
        ),
        throwsArgumentError,
      );

      expect(
        () => useCase(
          tokenId: 'tok-clm-1',
          redeemPoints: 0,
          billNumber: 'Bill #49021',
          branchName: 'Counter #1 POS',
          idempotencyKey: 'idem-2',
        ),
        throwsArgumentError,
      );

      final res = await useCase(
        tokenId: 'tok-clm-1',
        redeemPoints: 200,
        billNumber: 'Bill #49021',
        branchName: 'Counter #2 POS',
        idempotencyKey: 'idem-2',
      );
      expect(res.redeemedPoints, 200);
      expect(res.availablePoints, 1000);
    });
  });

  group('ScanPosBloc State & Business Flows', () {
    late FakeScanPosRepository repo;
    late ScanPosBloc bloc;

    setUp(() {
      repo = FakeScanPosRepository();
      bloc = _buildBloc(repo);
    });

    tearDown(() async {
      await bloc.close();
    });

    test('QR scan verification loads customer wallet and debounces duplicate camera frames', () async {
      const payload = 'SHIIFTEX:ACCRUAL:V1:ACC-1122-3344:AABBCCDD11223344';
      bloc.add(const QrCodeDetectedEvent(payload));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.status, ScanPosStatus.customerLoaded);
      expect(bloc.state.customer?.fullName, 'Vishnu K.');
      expect(bloc.state.idempotencyKey, isNotNull);
      expect(repo.verifyCallCount, 1);

      // Immediate duplicate camera detection of the same payload is ignored
      bloc.add(const QrCodeDetectedEvent(payload));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(repo.verifyCallCount, 1);
    });

    test('Mixed Instant + Future allocation updates customer balances & rotates idempotencyKey', () async {
      bloc.add(const ManualQrSubmittedEvent('ACC-1122-3344'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final initialKey = bloc.state.idempotencyKey;
      bloc.add(const InstantPointsChanged('250'));
      bloc.add(const FuturePointsChanged('50'));
      bloc.add(const BillNumberChanged('Bill #49021'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state.canAllocate, isTrue);
      expect(bloc.state.totalAllocationPoints, 300);
      expect(bloc.state.totalAllocationInr, closeTo(30.0, 0.001));

      bloc.add(const ConfirmAllocatePointsRequested());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(repo.allocateCallCount, 1);
      expect(repo.getWalletCallCount, 1);
      expect(repo.lastInstantPoints, 250);
      expect(repo.lastFuturePoints, 50);
      expect(repo.lastIdempotencyKey, initialKey);
      expect(bloc.state.status, ScanPosStatus.success);
      expect(bloc.state.customer?.availablePoints, 2700);
      expect(bloc.state.customer?.lockedPoints, 600);
      expect(bloc.state.instantPointsInput, isEmpty);
      expect(bloc.state.futurePointsInput, isEmpty);
      expect(bloc.state.billNumberInput, isEmpty);
      expect(bloc.state.idempotencyKey, isNot(equals(initialKey)));
    });

    test('Failed allocation preserves entered inputs & idempotencyKey for safe retry', () async {
      bloc.add(const ManualQrSubmittedEvent('ACC-1122-3344'));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final initialKey = bloc.state.idempotencyKey;
      bloc.add(const InstantPointsChanged('250'));
      bloc.add(const FuturePointsChanged('50'));
      bloc.add(const BillNumberChanged('49021'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      repo.allocateError = Exception('Network timeout');
      bloc.add(const ConfirmAllocatePointsRequested());
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(bloc.state.status, ScanPosStatus.error);
      expect(bloc.state.errorMessage, contains('Network timeout'));
      expect(bloc.state.instantPointsInput, '250');
      expect(bloc.state.futurePointsInput, '50');
      expect(bloc.state.billNumberInput, '49021');
      expect(bloc.state.idempotencyKey, initialKey);
      expect(bloc.state.customer?.availablePoints, 2450);

      // Clear failure and safely retry with same idempotencyKey
      repo.allocateError = null;
      bloc.add(const ConfirmAllocatePointsRequested());
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(bloc.state.status, ScanPosStatus.success);
      expect(repo.lastIdempotencyKey, initialKey);
      expect(bloc.state.customer?.availablePoints, 2700);
      expect(bloc.state.customer?.lockedPoints, 600);
    });

    test('Duplicate ConfirmAllocatePointsRequested while allocating is prevented', () async {
      repo.pendingAllocateCompleter = Completer<PosAllocationResultEntity>();

      bloc.add(const ManualQrSubmittedEvent('ACC-1122-3344'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      bloc.add(const BillNumberChanged('Bill #55001'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      bloc.add(const ConfirmAllocatePointsRequested());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.status, ScanPosStatus.allocating);

      // Rapid double-tap while request is in-flight
      bloc.add(const ConfirmAllocatePointsRequested());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(repo.allocateCallCount, 1);

      repo.pendingAllocateCompleter!.complete(
        PosAllocationResultEntity(
          success: true,
          customerId: 'cust-1',
          fullName: 'Vishnu K.',
          membershipId: 'SHFT-8921-VK',
          instantPointsAllocated: 250,
          futurePointsAllocated: 50,
          totalPointsAllocated: 300,
          totalInrEquivalent: 30.0,
          billNumber: 'Bill #55001',
          branchName: 'Counter #1 POS',
          availablePoints: 2700,
          lockedPoints: 600,
          allocatedAt: DateTime.now(),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(bloc.state.status, ScanPosStatus.success);
    });

    test('Verify Claim mode loads claim details, pre-fills claim points & bill #, redeems claim QR, and refreshes customer wallet', () async {
      bloc.add(const ScanPosModeChanged(ScanPosMode.verifyClaim));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const ManualQrSubmittedEvent('CLM-8812'));
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(bloc.state.mode, ScanPosMode.verifyClaim);
      expect(bloc.state.verifyClaimStatus, VerifyClaimStatus.claimLoaded);
      expect(bloc.state.customer?.hasClaimToken, isTrue);
      // Pre-filled from claim entity without deducting points on scan
      expect(bloc.state.redeemPoints, 200);
      expect(bloc.state.redeemInr, 20.0);
      expect(bloc.state.billNumberInput, 'Bill #49022');
      expect(bloc.state.customer?.auditChecks.allChecksPassed, isTrue);
      expect(bloc.state.canRedeemClaim, isTrue);
      expect(repo.redeemCallCount, 0);

      bloc.add(const ConfirmRedeemClaimRequested());
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(repo.redeemCallCount, 1);
      expect(repo.getWalletCallCount, 1);
      expect(bloc.state.status, ScanPosStatus.success);
      expect(bloc.state.verifyClaimStatus, VerifyClaimStatus.redeemed);
      expect(bloc.state.customer, isNull);
      expect(bloc.state.lastClaimResult?.availablePoints, 1000);
      expect(bloc.state.lastClaimResult?.redeemedPoints, 200);
    });

    test('Verify Claim mode handles expired, already redeemed, wrong QR mode, and invalid QR errors cleanly', () async {
      bloc.add(const ScanPosModeChanged(ScanPosMode.verifyClaim));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // 1. Expired claim QR
      repo.verifyError = Exception('CLAIM_EXPIRED: Claim QR has expired.');
      bloc.add(const ManualQrSubmittedEvent('CLM-EXP-1'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(bloc.state.status, ScanPosStatus.error);
      expect(bloc.state.verifyClaimStatus, VerifyClaimStatus.expired);
      expect(bloc.state.errorMessage, contains('expired'));

      // 2. Already redeemed claim QR
      repo.verifyError =
          Exception('CLAIM_ALREADY_REDEEMED: Claim QR has already been redeemed.');
      bloc.add(const ManualQrSubmittedEvent('CLM-USED-1'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(bloc.state.status, ScanPosStatus.error);
      expect(bloc.state.verifyClaimStatus, VerifyClaimStatus.invalid);
      expect(bloc.state.errorMessage, contains('already been redeemed'));

      // 3. Wrong QR mode (Member accrual QR scanned in Verify Claim mode)
      repo.verifyError = Exception(
        'WRONG_QR_MODE: This is a Personal Member QR for earning points. Switch to Give Reward mode.',
      );
      bloc.add(const ManualQrSubmittedEvent('ACC-1122-3344'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(bloc.state.status, ScanPosStatus.error);
      expect(bloc.state.verifyClaimStatus, VerifyClaimStatus.invalid);
      expect(bloc.state.errorMessage, contains('Personal Member QR'));

      // 4. Token expiry mid-session transitions to VerifyClaimStatus.expired
      repo.verifyError = null;
      bloc.add(const ManualQrSubmittedEvent('CLM-8812'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(bloc.state.verifyClaimStatus, VerifyClaimStatus.claimLoaded);

      bloc.add(const ClaimTokenExpiredEvent());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.verifyClaimStatus, VerifyClaimStatus.expired);
      expect(bloc.state.status, ScanPosStatus.error);
    });

    test('Verify Claim mode blocks redemption when backend audit checks fail or balance is insufficient', () async {
      repo.sampleClaimCustomer = repo.sampleClaimCustomer.copyWith(
        auditChecks: const ClaimAuditChecksEntity(
          tokenSignatureValid: false,
          claimNotExpired: true,
          singleUsePassed: true,
          replayProtectionPassed: true,
          customerEligible: true,
          balanceReservationValid: true,
        ),
      );

      bloc.add(const ScanPosModeChanged(ScanPosMode.verifyClaim));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const ManualQrSubmittedEvent('CLM-8812'));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(bloc.state.customer?.auditChecks.allChecksPassed, isFalse);
      expect(bloc.state.canRedeemClaim, isFalse);
    });

    test('RejectOrFlagClaimQrRequested rejects or flags a claim token without deducting points', () async {
      bloc.add(const ScanPosModeChanged(ScanPosMode.verifyClaim));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const ManualQrSubmittedEvent('CLM-8812'));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Reject claim
      bloc.add(
        const RejectOrFlagClaimQrRequested(
          action: 'reject',
          reason: 'Customer cancelled discount at POS counter',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(repo.rejectOrFlagCallCount, 1);
      expect(repo.lastRejectOrFlagAction, 'reject');
      expect(bloc.state.verifyClaimStatus, VerifyClaimStatus.rejected);
      expect(bloc.state.lastRejectOrFlagResult?.availablePoints, 1200);
      expect(bloc.state.lastRejectOrFlagResult?.reservedPoints, 0);
      expect(bloc.state.customer, isNull);
      expect(repo.redeemCallCount, 0);

      // Re-scan a fresh claim and flag suspicious activity
      bloc.add(const ManualQrSubmittedEvent('CLM-8812'));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      bloc.add(
        const RejectOrFlagClaimQrRequested(
          action: 'flag',
          reason: 'Screenshot of another member QR presented',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(repo.rejectOrFlagCallCount, 2);
      expect(repo.lastRejectOrFlagAction, 'flag');
      expect(bloc.state.verifyClaimStatus, VerifyClaimStatus.flagged);
      expect(bloc.state.lastRejectOrFlagResult?.auditStatus, 'flagged');
    });

    test('RefreshClaimValidationRequested re-queries backend for live claim state', () async {
      bloc.add(const ScanPosModeChanged(ScanPosMode.verifyClaim));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const ManualQrSubmittedEvent('CLM-8812'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(repo.verifyCallCount, 1);

      bloc.add(const RefreshClaimValidationRequested());
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(repo.verifyCallCount, 2);
      expect(bloc.state.verifyClaimStatus, VerifyClaimStatus.claimLoaded);
    });

    test('Mode switch clears previous customer so claim and accrual QRs stay strictly separated', () async {
      bloc.add(const ManualQrSubmittedEvent('ACC-1122-3344'));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(bloc.state.customer, isNotNull);

      bloc.add(const ScanPosModeChanged(ScanPosMode.verifyClaim));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.mode, ScanPosMode.verifyClaim);
      expect(bloc.state.customer, isNull);
    });

    test('Verification error transitions state cleanly to error with descriptive message', () async {
      repo.verifyError = Exception('Unauthorized: Admin access required.');
      bloc.add(const ManualQrSubmittedEvent('ACC-1122-3344'));
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(bloc.state.status, ScanPosStatus.error);
      expect(bloc.state.errorMessage, contains('Unauthorized'));
      expect(bloc.state.customer, isNull);
    });

    test('Recent scan history supports loading initial page and pagination', () async {
      repo.storedHistory = List.generate(
        18,
        (i) => PosTransactionEntity(
          id: 'tx-$i',
          customerId: 'cust-$i',
          customerName: 'Customer $i',
          membershipId: 'SHFT-100$i',
          transactionType: 'merchant_reward',
          title: 'POS Points Allocation',
          description: 'Allocated 100 pts',
          pointsDelta: 100,
          isLockedAllocation: false,
          billNumber: 'Bill #$i',
          branchName: 'Counter #1 POS',
          inrEquivalent: 10.0,
          status: 'completed',
          createdAt: DateTime.now(),
        ),
      );

      bloc.add(const InitializeScanPosRequested());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.recentTransactions.length, 15);
      expect(bloc.state.hasMoreHistory, isTrue);

      bloc.add(const LoadRecentTransactionsRequested(loadMore: true));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.recentTransactions.length, 18);
      expect(bloc.state.hasMoreHistory, isFalse);
    });
  });

  group('Mobile Responsive UI & Widget Rendering', () {
    late FakeScanPosRepository repo;
    late ScanPosBloc bloc;

    setUp(() {
      repo = FakeScanPosRepository();
      bloc = _buildBloc(repo);
    });

    tearDown(() async {
      await bloc.close();
    });

    Future<void> pumpPosView(
      WidgetTester tester, {
      required Size screenSize,
    }) async {
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ScanPosBloc>.value(
            value: bloc,
            child: const ScanPosView(enableCamera: false),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('Renders Give Reward customer wallet & allocation card cleanly on 390px and 320px phones without overflow', (tester) async {
      // Standard mobile viewport (390px)
      await pumpPosView(tester, screenSize: const Size(390, 844));
      await tester.runAsync(() async {
        bloc.add(const InitializeScanPosRequested());
        await Future<void>.delayed(const Duration(milliseconds: 30));
        bloc.add(const ManualQrSubmittedEvent('ACC-1122-3344'));
        await Future<void>.delayed(const Duration(milliseconds: 40));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Give Reward'), findsOneWidget);
      expect(find.text('Verify Claim'), findsOneWidget);
      expect(find.text('Enter Code Manually'), findsOneWidget);
      expect(find.text('Phone / ID'), findsOneWidget);
      expect(find.text('Vishnu K.'), findsOneWidget);
      expect(find.text('Points Allocation'), findsOneWidget);
      expect(find.text('Recent Scan History'), findsOneWidget);
      expect(find.textContaining('+180 pts'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.textContaining('₹'), findsNothing);
      expect(tester.takeException(), isNull);

      // Compact mobile viewport (320px)
      await pumpPosView(tester, screenSize: const Size(320, 640));
      expect(find.text('Vishnu K.'), findsOneWidget);
      expect(find.text('Instant Pts'), findsOneWidget);
      expect(find.text('Future Pts'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Switches to Verify Claim UI and displays claim verification card, audit checks, and actions on 390px and 320px phones without overflow', (tester) async {
      await pumpPosView(tester, screenSize: const Size(390, 1200));
      await tester.runAsync(() async {
        bloc.add(const ScanPosModeChanged(ScanPosMode.verifyClaim));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const ManualQrSubmittedEvent('CLM-8812'));
        await Future<void>.delayed(const Duration(milliseconds: 40));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(VerifyClaimCardWidget), findsOneWidget);
      expect(find.byType(ClaimAuditChecksWidget), findsOneWidget);
      expect(find.text('Arjun S.'), findsOneWidget);
      expect(find.text('CLM-8812'), findsWidgets);
      expect(find.text('Instant POS Bill Discount'), findsOneWidget);
      expect(find.textContaining('ShiftEx Partner Store'), findsWidgets);
      expect(
        find.text('Security & Cryptographic Audit Checks'),
        findsOneWidget,
      );
      expect(find.text('Token signature valid'), findsOneWidget);
      expect(
        find.text('Confirm Redemption (200 pts)'),
        findsOneWidget,
      );
      expect(find.textContaining('₹'), findsNothing);
      expect(find.text('Reject or Flag Token'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Compact 320px viewport check
      await pumpPosView(tester, screenSize: const Size(320, 900));
      expect(find.text('Arjun S.'), findsOneWidget);
      expect(find.text('Reject or Flag Token'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('RecentScanHistory renders transactions and Load More button', (tester) async {
      bool loadMoreTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: RecentScanHistory(
                transactions: repo.storedHistory,
                branchName: 'Counter #2 POS',
                hasMore: true,
                onLoadMore: () => loadMoreTapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Priya N. (SHFT-3104)'), findsOneWidget);
      expect(find.text('Arjun S. (CLM-8812)'), findsOneWidget);
      expect(find.text('Load More History'), findsOneWidget);

      await tester.tap(find.text('Load More History'));
      await tester.pump();
      expect(loadMoreTapped, isTrue);
    });

    testWidgets(
        'Confirm & Allocate validates missing Bill # without silent failure, then allocates & updates wallet card',
        (tester) async {
      await pumpPosView(tester, screenSize: const Size(390, 1200));
      await tester.runAsync(() async {
        bloc.add(const InitializeScanPosRequested());
        await Future<void>.delayed(const Duration(milliseconds: 30));
        bloc.add(const ManualQrSubmittedEvent('ACC-1122-3344'));
        await Future<void>.delayed(const Duration(milliseconds: 40));
      });
      await tester.pumpAndSettle();

      // Tapping Confirm & Allocate when Bill # is empty must show validation feedback, not do nothing
      final confirmBtn = find.text('Confirm & Allocate 300 pts');
      expect(confirmBtn, findsOneWidget);
      await tester.ensureVisible(confirmBtn);
      await tester.pump();
      await tester.tap(confirmBtn);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();

      expect(bloc.state.status, ScanPosStatus.error);
      expect(
        bloc.state.errorMessage,
        'Please enter a valid Bill / Reference number.',
      );
      expect(
        find.text('Please enter a valid Bill / Reference number.'),
        findsWidgets,
      );
      expect(repo.allocateCallCount, 0);

      // Enter Bill # and submit through Confirmation Dialog
      bloc.add(const BillNumberChanged('49021'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(find.text('Confirm Point Allocation'), findsOneWidget);
      await tester.tap(find.text('Confirm & Credit'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();

      expect(repo.allocateCallCount, 1);
      expect(repo.getWalletCallCount, 1);
      // Refreshed wallet balances appear on card (WalletBalanceCard uses RichText)
      expect(find.textContaining('2,700', findRichText: true), findsOneWidget);
      expect(find.textContaining('600', findRichText: true), findsWidgets);
      // Form inputs cleared after commit
      expect(find.text('Confirm & Allocate 0 pts'), findsOneWidget);
      expect(
        find.textContaining('Allocated 300 pts to Vishnu K.'),
        findsWidgets,
      );
      expect(find.textContaining('₹'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
