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
import 'package:shiftexadmin/features/scan_pos/domain/usecases/search_pos_customers_usecase.dart';
import 'package:shiftexadmin/features/scan_pos/domain/usecases/verify_customer_qr_usecase.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/bloc/scan_pos_bloc.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/bloc/scan_pos_event.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/pages/scan_pos_page.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/entities/daily_streak_settings_entity.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/data/models/points_to_cash_audit_log_model.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/data/models/points_to_cash_config_model.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/entities/points_to_cash_audit_log_entity.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/entities/points_to_cash_config_entity.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/repositories/points_to_cash_repository.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/usecases/get_points_to_cash_config_usecase.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/usecases/get_points_to_cash_history_usecase.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/usecases/update_points_to_cash_rate_usecase.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/presentation/bloc/points_to_cash_bloc.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/presentation/bloc/points_to_cash_event.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/presentation/bloc/points_to_cash_state.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/presentation/pages/points_to_cash_audit_page.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/presentation/widgets/update_points_to_cash_dialog_widget.dart';
import 'package:shiftexadmin/features/settings/presentation/widgets/points_to_cash_card_widget.dart';

class FakeCentralPointsToCashRepository implements PointsToCashRepository {
  final StreamController<PointsToCashConfigEntity> _controller =
      StreamController<PointsToCashConfigEntity>.broadcast();

  PointsToCashConfigEntity storedConfig = PointsToCashConfigEntity(
    id: 'global',
    pointsPerRupee: 10,
    pointsToInrRate: 0.10,
    currencyCode: 'INR',
    effectiveAt: DateTime(2026, 11, 17, 10, 0),
    updatedAt: DateTime(2026, 11, 17, 10, 0),
    updatedBy: 'admin-1',
    updatedByEmail: 'admin@shiftex.in',
  );

  List<PointsToCashAuditLogEntity> history = [
    PointsToCashAuditLogEntity(
      id: 'hist-1',
      versionNumber: 1,
      previousPointsPerRupee: null,
      newPointsPerRupee: 10,
      previousPointsToInrRate: null,
      newPointsToInrRate: 0.10,
      currencyCode: 'INR',
      changedBy: 'admin-1',
      changedByEmail: 'admin@shiftex.in',
      note: 'Initial baseline configuration',
      effectiveAt: DateTime(2026, 11, 17, 9, 0),
      createdAt: DateTime(2026, 11, 17, 9, 0),
    ),
  ];

  Object? getConfigError;
  Object? updateRateError;
  int updateCallCount = 0;

  @override
  Stream<PointsToCashConfigEntity> get configStream => _controller.stream;

  @override
  PointsToCashConfigEntity? get currentCachedConfig => storedConfig;

  @override
  void publishConfig(PointsToCashConfigEntity config) {
    storedConfig = config;
    if (!_controller.isClosed) {
      _controller.add(config);
    }
  }

  @override
  Future<PointsToCashConfigEntity> getActiveConfig() async {
    if (getConfigError != null) throw getConfigError!;
    return storedConfig;
  }

  @override
  Future<PointsToCashConfigEntity> updateConversionRate({
    required int pointsPerRupee,
    String? note,
  }) async {
    updateCallCount++;
    if (updateRateError != null) throw updateRateError!;

    final prevRate = storedConfig.pointsToInrRate;
    final newRate = ((1.0 / pointsPerRupee) * 1000000).round() / 1000000.0;
    final now = DateTime.now();

    history.insert(
      0,
      PointsToCashAuditLogEntity(
        id: 'hist-${history.length + 1}',
        versionNumber: history.length + 1,
        previousPointsPerRupee: storedConfig.pointsPerRupee,
        newPointsPerRupee: pointsPerRupee,
        previousPointsToInrRate: prevRate,
        newPointsToInrRate: newRate,
        currencyCode: 'INR',
        changedBy: 'admin-1',
        changedByEmail: 'admin@shiftex.in',
        note: note,
        effectiveAt: now,
        createdAt: now,
      ),
    );

    storedConfig = PointsToCashConfigEntity(
      id: 'global',
      pointsPerRupee: pointsPerRupee,
      pointsToInrRate: newRate,
      currencyCode: 'INR',
      effectiveAt: now,
      updatedAt: now,
      updatedBy: 'admin-1',
      updatedByEmail: 'admin@shiftex.in',
    );
    _controller.add(storedConfig);
    return storedConfig;
  }

  @override
  Future<List<PointsToCashAuditLogEntity>> getRateHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    return history.skip(offset).take(limit).toList();
  }

  void dispose() {
    _controller.close();
  }
}

class FakeSyncedScanPosRepository implements ScanPosRepository {
  final FakeCentralPointsToCashRepository centralRepo;

  int walletInstant = 2450;
  int walletLocked = 550;
  final List<PosTransactionEntity> ledger = [];

  FakeSyncedScanPosRepository(this.centralRepo);

  @override
  Future<VerifiedPosCustomerEntity> verifyCustomerQr({
    required String qrInput,
    required ScanPosMode mode,
  }) async {
    final cfg = centralRepo.storedConfig;
    return VerifiedPosCustomerEntity(
      customerId: 'cust-1',
      fullName: 'Vishnu K.',
      email: 'vishnu@shiftex.in',
      mobileNumber: '+91 98765 43210',
      approvalStatus: 'approved',
      membershipId: 'SHFT-8921-VK',
      availablePoints: walletInstant,
      lockedPoints: walletLocked,
      lifetimeEarnedPoints: 3000,
      lifetimeRedeemedPoints: 0,
      pointsPerRupee: cfg.pointsPerRupee,
      pointsToInrRate: cfg.cashValuePerPoint,
      tokenId: mode == ScanPosMode.verifyClaim ? 'tok-clm-1' : 'tok-acc-1',
      tokenCode: mode == ScanPosMode.verifyClaim ? 'CLM-8812' : 'ACC-1122',
      qrPayload: qrInput,
      tokenPurpose: mode == ScanPosMode.verifyClaim ? 'claim' : 'accrual',
      allowDeduction: mode == ScanPosMode.verifyClaim,
    );
  }

  @override
  Future<List<VerifiedPosCustomerEntity>> searchCustomers({
    required String query,
    int limit = 10,
  }) async => const [];

  @override
  Future<VerifiedPosCustomerEntity> getCustomerWallet({
    required String customerId,
  }) async {
    final cfg = centralRepo.storedConfig;
    return VerifiedPosCustomerEntity(
      customerId: customerId,
      fullName: 'Vishnu K.',
      email: 'vishnu@shiftex.in',
      mobileNumber: '+91 98765 43210',
      approvalStatus: 'approved',
      membershipId: 'SHFT-8921-VK',
      availablePoints: walletInstant,
      lockedPoints: walletLocked,
      pointsPerRupee: cfg.pointsPerRupee,
      pointsToInrRate: cfg.cashValuePerPoint,
    );
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
    final cfg = centralRepo.storedConfig;
    final totalPts = instantPoints + futurePoints;
    final instantCash = cfg.inrValueFor(instantPoints);
    final futureCash = cfg.inrValueFor(futurePoints);
    final totalCash = cfg.inrValueFor(totalPts);

    walletInstant += instantPoints;
    walletLocked += futurePoints;

    final now = DateTime.now();
    ledger.insert(
      0,
      PosTransactionEntity(
        id: 'tx-${ledger.length + 1}',
        customerId: customerId,
        customerName: 'Vishnu K.',
        membershipId: 'SHFT-8921-VK',
        tokenCode: 'SHFT-8921-VK',
        transactionType: 'merchant_reward',
        title: 'POS Points Allocation',
        description: 'Allocated $totalPts pts • $billNumber',
        pointsDelta: totalPts,
        isLockedAllocation: futurePoints > 0 && instantPoints == 0,
        billNumber: billNumber,
        branchName: branchName,
        adminId: 'admin-1',
        pointsPerRupee: cfg.pointsPerRupee,
        pointsToInrRate: cfg.cashValuePerPoint,
        currencyCode: 'INR',
        inrEquivalent: totalCash,
        status: 'completed',
        createdAt: now,
      ),
    );

    return PosAllocationResultEntity(
      success: true,
      customerId: customerId,
      fullName: 'Vishnu K.',
      membershipId: 'SHFT-8921-VK',
      instantPointsAllocated: instantPoints,
      futurePointsAllocated: futurePoints,
      totalPointsAllocated: totalPts,
      instantInrEquivalent: instantCash,
      futureInrEquivalent: futureCash,
      totalInrEquivalent: totalCash,
      pointsPerRupee: cfg.pointsPerRupee,
      pointsToInrRate: cfg.cashValuePerPoint,
      currencyCode: 'INR',
      billNumber: billNumber,
      branchName: branchName,
      availablePoints: walletInstant,
      lockedPoints: walletLocked,
      allocatedAt: now,
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
    final cfg = centralRepo.storedConfig;
    walletInstant -= redeemPoints;
    return PosClaimRedemptionResultEntity(
      success: true,
      customerId: 'cust-1',
      fullName: 'Vishnu K.',
      membershipId: 'SHFT-8921-VK',
      tokenCode: 'CLM-8812',
      redeemedPoints: redeemPoints,
      inrValue: cfg.inrValueFor(redeemPoints),
      pointsPerRupee: cfg.pointsPerRupee,
      pointsToInrRate: cfg.cashValuePerPoint,
      billNumber: billNumber,
      branchName: branchName,
      availablePoints: walletInstant,
      lockedPoints: walletLocked,
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
    return PosClaimRejectOrFlagResultEntity(
      success: true,
      action: action,
      auditStatus: action == 'flag' ? 'flagged' : 'rejected',
      tokenId: tokenId,
      claimReference: 'CLM-8812',
      reason: reason,
      branchName: branchName,
      availablePoints: walletInstant,
      reservedPoints: 0,
      processedAt: DateTime.now(),
    );
  }

  @override
  Future<List<PosTransactionEntity>> getRecentTransactions({
    int limit = 15,
    int offset = 0,
  }) async {
    return ledger.skip(offset).take(limit).toList();
  }
}

PointsToCashBloc _createRateBloc(FakeCentralPointsToCashRepository repo) {
  return PointsToCashBloc(
    getPointsToCashConfigUseCase: GetPointsToCashConfigUseCase(
      repository: repo,
    ),
    updatePointsToCashRateUseCase: UpdatePointsToCashRateUseCase(
      repository: repo,
    ),
    getPointsToCashHistoryUseCase: GetPointsToCashHistoryUseCase(
      repository: repo,
    ),
  );
}

ScanPosBloc _createPosBloc(
  FakeSyncedScanPosRepository posRepo,
  FakeCentralPointsToCashRepository centralRepo,
) {
  return ScanPosBloc(
    verifyCustomerQrUseCase: VerifyCustomerQrUseCase(repository: posRepo),
    getPosCustomerWalletUseCase: GetPosCustomerWalletUseCase(
      repository: posRepo,
    ),
    allocatePosPointsUseCase: AllocatePosPointsUseCase(repository: posRepo),
    redeemCustomerClaimQrUseCase: RedeemCustomerClaimQrUseCase(
      repository: posRepo,
    ),
    searchPosCustomersUseCase: SearchPosCustomersUseCase(repository: posRepo),
    getPosRecentTransactionsUseCase: GetPosRecentTransactionsUseCase(
      repository: posRepo,
    ),
    getPointsToCashConfigUseCase: GetPointsToCashConfigUseCase(
      repository: centralRepo,
    ),
  );
}

void main() {
  group('Central Points-to-Cash Domain & Validation Tests (No 2FA)', () {
    test(
      'PointsToCashConfigModel parses integer rate and calculates INR accurately',
      () {
        final model = PointsToCashConfigModel.fromJson({
          'id': 'global',
          'points_per_rupee': 10,
          'points_to_inr_rate': '0.100000',
          'currency_code': 'INR',
          'effective_at': '2026-11-17T06:00:00Z',
          'updated_at': '2026-11-17T06:00:00Z',
          'updated_by_email': 'vishnu.k@shiftex.in',
        });

        expect(model.pointsPerRupee, 10);
        expect(model.cashValuePerPoint, closeTo(0.10, 0.0001));
        expect(model.formattedLiabilityPerPoint, '0.10');
        expect(model.inrValueFor(100), closeTo(10.0, 0.001));
        expect(model.inrValueFor(1000), closeTo(100.0, 0.001));
        expect(model.inrValueFor(5000), closeTo(500.0, 0.001));

        expect(
          PointsToCashConfigEntity.inrFromPoints(
            points: 250,
            pointsPerRupee: 20,
          ),
          closeTo(12.50, 0.001),
        );
        expect(
          PointsToCashConfigEntity.pointsFromInr(
            inrAmount: 12.50,
            pointsPerRupee: 20,
          ),
          250,
        );
        expect(
          PointsToCashConfigEntity.inrFromPoints(
            points: 5000,
            pointsPerRupee: 50,
          ),
          closeTo(100.0, 0.001),
        );
      },
    );

    test(
      'UpdatePointsToCashRateUseCase enforces integer range without 2FA',
      () async {
        final repo = FakeCentralPointsToCashRepository();
        final useCase = UpdatePointsToCashRateUseCase(repository: repo);

        await expectLater(
          () => useCase(pointsPerRupee: 0),
          throwsArgumentError,
        );
        await expectLater(
          () => useCase(pointsPerRupee: -10),
          throwsArgumentError,
        );
        await expectLater(
          () => useCase(pointsPerRupee: 10001),
          throwsArgumentError,
        );

        final updated = await useCase(
          pointsPerRupee: 20,
          note: 'Seasonal rate update',
        );
        expect(updated.pointsPerRupee, 20);
        expect(repo.updateCallCount, 1);

        repo.dispose();
      },
    );

    test(
      'DailyStreakSettingsEntity delegates conversion via PointsToCashConfigEntity',
      () {
        final entity = DailyStreakSettingsEntity(
          id: 'global',
          dailyLoginEnabled: true,
          dailyLoginPoints: 25,
          pointsPerRupee: 20,
          pointsToInrRate: 0.05,
          updatedAt: DateTime(2026, 11, 17),
        );
        expect(entity.equivalentInrFor(25), closeTo(1.25, 0.001));
        expect(entity.equivalentInrFor(100), closeTo(5.0, 0.001));
      },
    );
  });

  group('PointsToCashBloc & Audit Flow Tests (No 2FA)', () {
    late FakeCentralPointsToCashRepository repo;
    late PointsToCashBloc bloc;

    setUp(() {
      repo = FakeCentralPointsToCashRepository();
      bloc = _createRateBloc(repo);
    });

    tearDown(() async {
      await bloc.close();
      repo.dispose();
    });

    test(
      'loads baseline config, validates integer drafts, saves without 2FA, and logs audit history',
      () async {
        bloc.add(const LoadPointsToCashConfigRequested());
        await Future.delayed(const Duration(milliseconds: 20));

        expect(bloc.state.status, PointsToCashStatus.loaded);
        expect(bloc.state.activePointsPerRupee, 10);
        expect(bloc.state.activePointsToInrRate, closeTo(0.10, 0.0001));

        bloc.add(const PrepareRateUpdateModalRequested());
        await Future.delayed(const Duration(milliseconds: 20));

        // Reject decimal & out-of-range values
        bloc.add(const DraftPointsPerRupeeChanged('12.5'));
        await Future.delayed(const Duration(milliseconds: 10));
        expect(bloc.state.validationError, isNotNull);
        expect(bloc.state.isProposedRateValid, isFalse);

        bloc.add(const DraftPointsPerRupeeChanged('0'));
        await Future.delayed(const Duration(milliseconds: 10));
        expect(bloc.state.validationError, isNotNull);

        // Valid integer change: 20 pts = ₹1.00
        bloc.add(const DraftPointsPerRupeeChanged('20'));
        bloc.add(const DraftRateNoteChanged('Revised rate to 20 pts per INR'));
        await Future.delayed(const Duration(milliseconds: 10));
        expect(bloc.state.validationError, isNull);
        expect(bloc.state.isProposedRateValid, isTrue);
        expect(bloc.state.canSubmitRateUpdate, isTrue);
        expect(bloc.state.proposedInrFor(100), closeTo(5.0, 0.001));
        expect(bloc.state.proposedInrFor(1000), closeTo(50.0, 0.001));
        expect(bloc.state.proposedInrFor(5000), closeTo(250.0, 0.001));

        bloc.add(const SubmitPointsToCashRateUpdateRequested());
        await Future.delayed(const Duration(milliseconds: 30));

        expect(bloc.state.status, PointsToCashStatus.loaded);
        expect(bloc.state.activePointsPerRupee, 20);
        expect(bloc.state.successMessage, contains('20 pts = ₹1.00'));
        expect(bloc.state.config?.inrValueFor(100), closeTo(5.0, 0.001));
        expect(bloc.state.config?.inrValueFor(1000), closeTo(50.0, 0.001));
        expect(bloc.state.config?.inrValueFor(5000), closeTo(250.0, 0.001));

        bloc.add(const LoadPointsToCashAuditLogsRequested());
        await Future.delayed(const Duration(milliseconds: 20));
        expect(bloc.state.auditLogs.length, 2);
        expect(bloc.state.auditLogs.first.previousPointsPerRupee, 10);
        expect(bloc.state.auditLogs.first.newPointsPerRupee, 20);
        expect(
          bloc.state.auditLogs.first.note,
          'Revised rate to 20 pts per INR',
        );
      },
    );

    test('maps unauthorized server rejection cleanly to error state', () async {
      bloc.add(const LoadPointsToCashConfigRequested());
      await Future.delayed(const Duration(milliseconds: 20));

      repo.updateRateError = Exception('UNAUTHORIZED: Admin access required');
      bloc.add(const DraftPointsPerRupeeChanged('25'));
      bloc.add(const SubmitPointsToCashRateUpdateRequested());
      await Future.delayed(const Duration(milliseconds: 20));

      expect(bloc.state.status, PointsToCashStatus.error);
      expect(bloc.state.errorMessage, contains('Admin permissions'));
      expect(bloc.state.activePointsPerRupee, 10);
    });

    test('PointsToCashAuditLogModel parses integer audit JSON accurately', () {
      final model = PointsToCashAuditLogModel.fromJson({
        'id': 'log-2',
        'version_number': 2,
        'previous_points_per_rupee': 10,
        'new_points_per_rupee': 50,
        'previous_points_to_inr_rate': '0.100000',
        'new_points_to_inr_rate': '0.020000',
        'currency_code': 'INR',
        'changed_by_email': 'owner@shiftex.in',
        'note': 'Loyalty tier rebalancing',
        'effective_at': '2026-11-17T12:00:00Z',
        'created_at': '2026-11-17T12:00:00Z',
      });

      expect(model.previousPointsPerRupee, 10);
      expect(model.newPointsPerRupee, 50);
      expect(model.newPointsToInrRate, closeTo(0.02, 0.0001));
    });
  });

  group(
    'Central Sync (Settings -> Scan POS) & Historical Snapshot Immutability',
    () {
      late FakeCentralPointsToCashRepository centralRepo;
      late FakeSyncedScanPosRepository posRepo;
      late PointsToCashBloc rateBloc;
      late ScanPosBloc posBloc;

      setUp(() {
        centralRepo = FakeCentralPointsToCashRepository();
        posRepo = FakeSyncedScanPosRepository(centralRepo);
        rateBloc = _createRateBloc(centralRepo);
        posBloc = _createPosBloc(posRepo, centralRepo);
      });

      tearDown(() async {
        await rateBloc.close();
        await posBloc.close();
        centralRepo.dispose();
      });

      test(
        'updating rate in Settings immediately syncs Scan POS & preserves past transaction snapshots',
        () async {
          rateBloc.add(const LoadPointsToCashConfigRequested());
          posBloc.add(const InitializeScanPosRequested());
          await Future.delayed(const Duration(milliseconds: 30));

          expect(posBloc.state.pointsPerRupee, 10);

          // Scan customer & allocate 300 pts @ 10 pts = ₹1 => ₹30.00
          posBloc.add(const ManualQrSubmittedEvent('ACC-1122'));
          await Future.delayed(const Duration(milliseconds: 20));
          posBloc.add(const InstantPointsChanged('250'));
          posBloc.add(const FuturePointsChanged('50'));
          posBloc.add(const BillNumberChanged('Bill #101'));
          await Future.delayed(const Duration(milliseconds: 10));

          expect(posBloc.state.instantInr, closeTo(25.00, 0.001));
          expect(posBloc.state.futureInr, closeTo(5.00, 0.001));
          expect(posBloc.state.totalAllocationPoints, 300);
          expect(posBloc.state.totalAllocationInr, closeTo(30.00, 0.001));

          posBloc.add(const ConfirmAllocatePointsRequested());
          await Future.delayed(const Duration(milliseconds: 25));

          final txA = posRepo.ledger.first;
          expect(txA.inrEquivalent, closeTo(30.00, 0.001));
          expect(txA.pointsPerRupee, 10);

          // Admin updates central rate to 20 pts = ₹1.00
          rateBloc.add(const DraftPointsPerRupeeChanged('20'));
          rateBloc.add(const SubmitPointsToCashRateUpdateRequested());
          await Future.delayed(const Duration(milliseconds: 30));

          // Re-enter 250 + 50 for the next allocation; Scan POS BLoC syncs automatically
          posBloc.add(const InstantPointsChanged('250'));
          posBloc.add(const FuturePointsChanged('50'));
          await Future.delayed(const Duration(milliseconds: 10));
          expect(posBloc.state.pointsPerRupee, 20);
          expect(posBloc.state.pointsToInrRate, closeTo(0.05, 0.0001));
          expect(posBloc.state.instantInr, closeTo(12.50, 0.001));
          expect(posBloc.state.futureInr, closeTo(2.50, 0.001));
          expect(posBloc.state.totalAllocationInr, closeTo(15.00, 0.001));

          // VerifyClaim mode also uses updated rate
          posBloc.add(const ScanPosModeChanged(ScanPosMode.verifyClaim));
          await Future.delayed(const Duration(milliseconds: 10));
          posBloc.add(const RedeemPointsChanged('200'));
          await Future.delayed(const Duration(milliseconds: 10));
          expect(posBloc.state.redeemInr, closeTo(10.00, 0.001));

          // Allocate another 300 pts @ 20 pts = ₹1 => ₹15.00
          posBloc.add(const ScanPosModeChanged(ScanPosMode.giveReward));
          posBloc.add(const ManualQrSubmittedEvent('ACC-1122'));
          await Future.delayed(const Duration(milliseconds: 20));
          posBloc.add(const InstantPointsChanged('250'));
          posBloc.add(const FuturePointsChanged('50'));
          posBloc.add(const BillNumberChanged('Bill #102'));
          posBloc.add(const ConfirmAllocatePointsRequested());
          await Future.delayed(const Duration(milliseconds: 25));

          final history = posBloc.state.recentTransactions;
          expect(history.length, 2);
          final fetchedTxB = history.firstWhere(
            (t) => t.billNumber == 'Bill #102',
          );
          final fetchedTxA = history.firstWhere(
            (t) => t.billNumber == 'Bill #101',
          );

          expect(fetchedTxB.pointsDelta, 300);
          expect(fetchedTxB.inrEquivalent, closeTo(15.00, 0.001));
          expect(fetchedTxB.pointsPerRupee, 20);

          // Historical snapshot remains completely immutable
          expect(fetchedTxA.pointsDelta, 300);
          expect(fetchedTxA.inrEquivalent, closeTo(30.00, 0.001));
          expect(fetchedTxA.pointsPerRupee, 10);
        },
      );
    },
  );

  group('Points-to-Cash UI & Scan POS Mobile Widget Tests', () {
    testWidgets(
      'PointsToCashCardWidget renders active rate without 2FA & modal updates rate cleanly on 390px and 320px phones',
      (tester) async {
        final centralRepo = FakeCentralPointsToCashRepository();
        final rateBloc = _createRateBloc(centralRepo);
        await tester.runAsync(() async {
          rateBloc.add(const LoadPointsToCashConfigRequested());
          await Future.delayed(const Duration(milliseconds: 30));
        });

        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<PointsToCashBloc>.value(
              value: rateBloc,
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: BlocBuilder<PointsToCashBloc, PointsToCashState>(
                    builder: (context, state) {
                      return PointsToCashCardWidget(
                        state: state,
                        onUpdateRatePressed: () {
                          UpdatePointsToCashDialogWidget.show(
                            context,
                            bloc: rateBloc,
                          );
                        },
                        onViewAuditHistory: () {},
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Baseline display checks (no 2FA text)
        expect(find.text('Points-to-Cash Valuation'), findsOneWidget);
        expect(find.text('10 PTS = ₹1.00'), findsOneWidget);
        expect(find.text('(₹0.10 liability / pt)'), findsOneWidget);
        expect(find.text('₹10.00'), findsOneWidget);
        expect(find.text('₹100.00'), findsOneWidget);
        expect(find.text('₹500.00'), findsOneWidget);
        expect(find.text('Strict Audit Protection'), findsOneWidget);
        expect(find.text('Update Rate'), findsOneWidget);
        expect(find.textContaining('2FA'), findsNothing);
        expect(tester.takeException(), isNull, reason: 'before modal');

        // Open Update Rate modal sheet
        await tester.tap(find.text('Update Rate'));
        await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'modal opened');

        expect(find.text('Update Conversion Rate'), findsOneWidget);
        expect(find.text('10 pts = ₹1.00'), findsWidgets);

        // Tap preset 50 pts and check live preview updates (100 pts = ₹2.00, 1000 = ₹20.00, 5000 = ₹100.00)
        await tester.tap(find.text('50 pts'));
        await tester.pumpAndSettle();
        expect(find.text('50 pts = ₹1.00'), findsOneWidget);
        expect(find.text('₹2.00'), findsOneWidget);
        expect(find.text('₹20.00'), findsOneWidget);
        expect(find.text('₹100.00'), findsWidgets);
        expect(tester.takeException(), isNull, reason: 'preset tapped');

        // Save rate without 2FA
        await tester.tap(find.text('Save Conversion Rate'));
        await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pumpAndSettle();

        // Card now displays 50 PTS = ₹1.00 and updated dynamic matrix
        expect(find.text('50 PTS = ₹1.00'), findsOneWidget);
        expect(find.text('(₹0.02 liability / pt)'), findsOneWidget);
        expect(find.text('₹2.00'), findsOneWidget);
        expect(find.text('₹20.00'), findsOneWidget);
        expect(find.text('₹100.00'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'after save at 390px');

        // Also verify narrow 320px viewport has zero layout overflow
        tester.view.physicalSize = const Size(320, 640);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'at 320px');

        await tester.runAsync(() async {
          await rateBloc.close();
          centralRepo.dispose();
        });
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );

    testWidgets(
      'ScanPosView reflects central rate dynamically & keeps historical ledger snapshot',
      (tester) async {
        final centralRepo = FakeCentralPointsToCashRepository();
        final posRepo = FakeSyncedScanPosRepository(centralRepo);
        posRepo.ledger.add(
          PosTransactionEntity(
            id: 'hist-tx-1',
            customerId: 'cust-old',
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
            pointsPerRupee: 10,
            pointsToInrRate: 0.10,
            inrEquivalent: 18.00,
            status: 'completed',
            createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
        );

        final posBloc = _createPosBloc(posRepo, centralRepo);

        await tester.runAsync(() async {
          await centralRepo.updateConversionRate(pointsPerRupee: 20);
          posBloc.add(const InitializeScanPosRequested());
          await Future.delayed(const Duration(milliseconds: 30));
          posBloc.add(const ManualQrSubmittedEvent('ACC-1122'));
          await Future.delayed(const Duration(milliseconds: 30));
        });

        tester.view.physicalSize = const Size(390, 1200);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<ScanPosBloc>.value(
              value: posBloc,
              child: const ScanPosView(enableCamera: false),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Instant & Future Pts'), findsOneWidget);
        expect(find.text('Immediate credit'), findsOneWidget);
        expect(find.text('Locked until unlock'), findsOneWidget);
        expect(find.text('Confirm & Allocate 300 pts'), findsOneWidget);

        // Historical item shows points-only without currency symbol
        expect(find.text('+180 pts'), findsOneWidget);
        expect(find.textContaining('₹'), findsNothing);
        expect(tester.takeException(), isNull);

        await tester.runAsync(() async {
          await posBloc.close();
          centralRepo.dispose();
        });
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );

    testWidgets(
      'PointsToCashAuditPage displays immutable rate change history without 2FA strings',
      (tester) async {
        final centralRepo = FakeCentralPointsToCashRepository();
        await centralRepo.updateConversionRate(
          pointsPerRupee: 20,
          note: 'Mid-season exchange revision',
        );
        final rateBloc = _createRateBloc(centralRepo);

        await tester.runAsync(() async {
          rateBloc.add(const LoadPointsToCashAuditLogsRequested());
          await Future.delayed(const Duration(milliseconds: 30));
        });

        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<PointsToCashBloc>.value(
              value: rateBloc,
              child: const PointsToCashAuditView(),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Points-to-Cash Rate History'), findsOneWidget);
        expect(
          find.text('Rate updated: 10 pts = ₹1 → 20 pts = ₹1.00'),
          findsOneWidget,
        );
        expect(find.text('Mid-season exchange revision'), findsOneWidget);
        expect(find.textContaining('2FA'), findsNothing);
        expect(tester.takeException(), isNull);

        await tester.runAsync(() async {
          await rateBloc.close();
          centralRepo.dispose();
        });
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );
  });
}
