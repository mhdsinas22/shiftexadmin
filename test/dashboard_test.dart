import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftexadmin/core/routes/route_names.dart';
import 'package:shiftexadmin/features/dashboard/data/models/dashboard_overview_model.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/admin_identity_entity.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/dashboard_overview_entity.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/dashboard_statistics_entity.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/master_ledger_entry_entity.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/pending_claim_item_entity.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/system_activity_item_entity.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/top_performing_user_entity.dart';
import 'package:shiftexadmin/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:shiftexadmin/features/dashboard/domain/usecases/get_dashboard_overview_usecase.dart';
import 'package:shiftexadmin/features/dashboard/domain/usecases/get_master_ledger_usecase.dart';
import 'package:shiftexadmin/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:shiftexadmin/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:shiftexadmin/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:shiftexadmin/features/dashboard/presentation/pages/admin_dashboard_page.dart';
import 'package:shiftexadmin/features/dashboard/presentation/pages/master_ledger_page.dart';
import 'package:shiftexadmin/features/user_management/domain/entities/customer_entity.dart';
import 'package:shiftexadmin/features/user_management/domain/entities/user_statistics_entity.dart';
import 'package:shiftexadmin/features/user_management/domain/repositories/user_management_repository.dart';
import 'package:shiftexadmin/features/user_management/domain/usecases/approve_customer_usecase.dart';
import 'package:shiftexadmin/features/user_management/domain/usecases/reject_customer_usecase.dart';

class _FakeDashboardRepository implements DashboardRepository {
  bool shouldFail = false;
  String failureMessage = 'Unauthorized: Only authorized admins can view the Admin Dashboard.';
  int overviewCallCount = 0;
  int ledgerCallCount = 0;
  LedgerCategoryFilter? lastRequestedCategory;

  List<CustomerEntity> pendingVerifications = [
    CustomerEntity(
      id: '9102aaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      fullName: 'Rahul Verma',
      email: 'rahul@shiftex.in',
      mobileNumber: '+91 98765 43210',
      approvalStatus: 'pending',
      createdAt: DateTime(2026, 11, 18, 9, 0),
      updatedAt: DateTime(2026, 11, 18, 9, 0),
    ),
    CustomerEntity(
      id: '9104aaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      fullName: 'Priya Nair',
      email: 'priya@shiftex.in',
      mobileNumber: '+91 97412 88201',
      approvalStatus: 'pending',
      createdAt: DateTime(2026, 11, 18, 8, 30),
      updatedAt: DateTime(2026, 11, 18, 8, 30),
    ),
  ];

  late List<PendingClaimItemEntity> pendingClaims;
  late List<MasterLedgerEntryEntity> allLedgerEntries;

  _FakeDashboardRepository() {
    final now = DateTime.now();
    pendingClaims = [
      PendingClaimItemEntity(
        id: 'claim-1',
        qrTokenId: 'token-1',
        claimReference: 'CLM-9942-X7B',
        qrPayload: 'SHIIFTEX:CLAIM:V1:CLM-9942-X7B:ABCD12345678',
        userId: 'user-1',
        customerName: 'Vishnu K.',
        membershipId: 'SHFT-8921',
        merchantCounter: 'Blue Tokai Counter',
        statusSubtitle: 'Point deduction verified',
        points: 250,
        pointsToInrRate: 0.10,
        discountAmount: 25.00,
        status: 'pending',
        expiresAt: now.add(const Duration(minutes: 3, seconds: 41)),
        createdAt: now.subtract(const Duration(minutes: 1)),
      ),
      PendingClaimItemEntity(
        id: 'claim-expired',
        qrTokenId: 'token-expired',
        claimReference: 'CLM-0000-EXP',
        qrPayload: 'SHIIFTEX:CLAIM:V1:CLM-0000-EXP:000000000000',
        userId: 'user-2',
        customerName: 'Expired User',
        membershipId: 'SHFT-0000',
        merchantCounter: 'Expired Counter',
        points: 100,
        discountAmount: 10.00,
        status: 'pending',
        expiresAt: now.subtract(const Duration(minutes: 2)),
        createdAt: now.subtract(const Duration(minutes: 7)),
      ),
    ];

    allLedgerEntries = [
      MasterLedgerEntryEntity(
        id: '49021aaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        shortTxCode: 'TXN-49021',
        userId: 'user-1',
        customerName: 'Vishnu K.',
        membershipId: 'SHFT-8921',
        transactionType: 'merchant_reward',
        category: 'purchases',
        title: 'Organic Harvest Cafe',
        description: 'Allocated 80 pts • Bill #49021',
        billNumber: '49021',
        branchName: 'Organic Harvest Cafe',
        pointsDelta: 80,
        pointsPerRupee: 10,
        pointsToInrRate: 0.10,
        inrValue: 8.00, // historical snapshot at 10 pts = ₹1
        isAutoBonus: false,
        createdAt: now.subtract(const Duration(minutes: 20)),
      ),
      MasterLedgerEntryEntity(
        id: '49018aaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        shortTxCode: 'TXN-49018',
        userId: 'user-2',
        customerName: 'Sneha Rao',
        membershipId: 'SHFT-8812',
        transactionType: 'discount_redemption',
        category: 'redemptions',
        title: 'Blue Tokai Roastery',
        description: 'Redeemed 250 pts • Bill #49018',
        billNumber: '49018',
        branchName: 'Blue Tokai Roastery',
        pointsDelta: -250,
        pointsPerRupee: 10,
        pointsToInrRate: 0.10,
        inrValue: 25.00, // historical snapshot at 10 pts = ₹1
        isAutoBonus: false,
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      MasterLedgerEntryEntity(
        id: '48995aaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        shortTxCode: 'TXN-48995',
        userId: 'user-1',
        customerName: 'Vishnu K.',
        membershipId: 'SHFT-8921',
        transactionType: 'daily_streak',
        category: 'streak',
        title: '7-Day Shift Streak Bonus',
        description: 'Day 7 check-in bonus',
        pointsDelta: 15,
        pointsPerRupee: 10,
        pointsToInrRate: 0.10,
        inrValue: 1.50,
        isAutoBonus: true,
        createdAt: now.subtract(const Duration(hours: 14)),
      ),
    ];
  }

  @override
  Future<DashboardOverviewEntity> getDashboardOverview({
    LedgerCategoryFilter ledgerCategory = LedgerCategoryFilter.all,
  }) async {
    overviewCallCount++;
    lastRequestedCategory = ledgerCategory;
    if (shouldFail) {
      throw Exception(failureMessage);
    }

    final filteredLedger = await getMasterLedger(category: ledgerCategory);

    return DashboardOverviewEntity(
      adminProfile: const AdminIdentityEntity(
        id: 'admin-uuid-1',
        fullName: 'Mohamed Sinas',
        email: 'mohamedsinaasp@gmail.com',
        roleLabel: 'Super Admin',
        organizationLabel: 'ShiftEx Central Control',
      ),
      statistics: const DashboardStatisticsEntity(
        totalClaimsProcessed: 4892,
        claimsCurrent30d: 562,
        claimsPrev30d: 500,
        claimsGrowthPct: 12.4,
        netValueInr: 148250,
        totalPointsGiven: 1482500,
        activePointsPerRupee: 10,
        activePointsToInrRate: 0.10,
        liquidPoints: 842190,
        liquidPoolInr: 84219,
        lockedPoints: 218400,
        lockedPoolInr: 21840,
      ),
      pendingVerificationsCount: pendingVerifications.length,
      pendingVerifications: List.unmodifiable(pendingVerifications),
      pendingClaimsCount: pendingClaims.length,
      pendingClaims: List.unmodifiable(pendingClaims),
      masterLedger: filteredLedger,
      topPerformingUsers: const [
        TopPerformingUserEntity(
          rank: 1,
          customerId: 'user-1',
          fullName: 'Vishnu K.',
          membershipId: 'SHFT-8921',
          tierBadge: 'Elite Tier',
          hubName: 'Koramangala Hub',
          totalPointsEarned: 3450,
          posScanCount: 44,
        ),
        TopPerformingUserEntity(
          rank: 2,
          customerId: 'user-2',
          fullName: 'Devika R.',
          membershipId: 'SHFT-8810',
          tierBadge: 'Gold Tier',
          hubName: 'Indiranagar Hub',
          totalPointsEarned: 2890,
          posScanCount: 38,
        ),
        TopPerformingUserEntity(
          rank: 3,
          customerId: 'user-3',
          fullName: 'Rohan Mathew',
          membershipId: 'SHFT-8432',
          tierBadge: 'Gold Tier',
          hubName: 'Whitefield Hub',
          totalPointsEarned: 2410,
          posScanCount: 31,
        ),
      ],
      systemActivityLog: [
        SystemActivityItemEntity(
          id: 'act-1',
          activityType: 'terminal_pos',
          title: 'Terminal #04 Handshake Verified',
          subtitle: 'Gate POS 4 • Encryption OK',
          occurredAt: DateTime.now().subtract(const Duration(minutes: 12)),
        ),
        SystemActivityItemEntity(
          id: 'act-2',
          activityType: 'batch_unlock',
          title: 'Batch settlement auto-released 1,200 pts',
          subtitle: 'Routine Vault Scheduled Sweep',
          occurredAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ],
      fetchedAt: DateTime.now(),
    );
  }

  @override
  Future<List<MasterLedgerEntryEntity>> getMasterLedger({
    LedgerCategoryFilter category = LedgerCategoryFilter.all,
    String searchQuery = '',
    int limit = 15,
    int offset = 0,
  }) async {
    ledgerCallCount++;
    lastRequestedCategory = category;
    if (shouldFail) {
      throw Exception(failureMessage);
    }

    return allLedgerEntries.where((entry) {
      final matchesCategory =
          category == LedgerCategoryFilter.all ||
          entry.category == category.queryKey;
      final q = searchQuery.trim().toLowerCase();
      final matchesSearch =
          q.isEmpty ||
          entry.title.toLowerCase().contains(q) ||
          entry.shortTxCode.toLowerCase().contains(q) ||
          entry.customerName.toLowerCase().contains(q);
      return matchesCategory && matchesSearch;
    }).toList();
  }
}

class _FakeUserManagementRepository implements UserManagementRepository {
  final _FakeDashboardRepository dashboardRepository;
  final List<String> approvedCustomerIds = [];
  final Map<String, String> rejectedCustomerIds = {};

  _FakeUserManagementRepository(this.dashboardRepository);

  @override
  Future<void> approveCustomer(String customerId) async {
    approvedCustomerIds.add(customerId);
    dashboardRepository.pendingVerifications = dashboardRepository
        .pendingVerifications
        .where((c) => c.id != customerId)
        .toList();
  }

  @override
  Future<void> rejectCustomer(String customerId, String reason) async {
    rejectedCustomerIds[customerId] = reason;
    dashboardRepository.pendingVerifications = dashboardRepository
        .pendingVerifications
        .where((c) => c.id != customerId)
        .toList();
  }

  @override
  Future<List<CustomerEntity>> getCustomers({
    String? status,
    String? searchQuery,
    String? sortBy,
    int limit = 50,
    int offset = 0,
  }) async => const [];

  @override
  Future<List<CustomerEntity>> getTopEarners({
    String range = 'weekly',
    int limit = 3,
  }) async => const [];

  @override
  Future<UserStatisticsEntity> getUserStatistics() async =>
      const UserStatisticsEntity(
        registeredCount: 0,
        pendingCount: 0,
        activeCount: 0,
        restrictedCount: 0,
      );

  @override
  Future<CustomerEntity> getCustomerDetails(String customerId) async =>
      dashboardRepository.pendingVerifications.first;
}

void main() {
  late _FakeDashboardRepository fakeDashboardRepo;
  late _FakeUserManagementRepository fakeUserRepo;
  late DashboardBloc dashboardBloc;

  setUp(() {
    fakeDashboardRepo = _FakeDashboardRepository();
    fakeUserRepo = _FakeUserManagementRepository(fakeDashboardRepo);
    dashboardBloc = DashboardBloc(
      getDashboardOverviewUseCase: GetDashboardOverviewUseCase(
        fakeDashboardRepo,
      ),
      getMasterLedgerUseCase: GetMasterLedgerUseCase(fakeDashboardRepo),
      approveCustomerUseCase: ApproveCustomerUseCase(repository: fakeUserRepo),
      rejectCustomerUseCase: RejectCustomerUseCase(repository: fakeUserRepo),
    );
  });

  tearDown(() async {
    await dashboardBloc.close();
  });

  group('Dashboard Domain & Data Models Verification', () {
    test(
      '1. Statistics formatting & growth badge only shown when historical comparison exists',
      () {
        const statsWithGrowth = DashboardStatisticsEntity(
          totalClaimsProcessed: 4892,
          claimsGrowthPct: 12.4,
          netValueInr: 148250,
          totalPointsGiven: 1482500,
          liquidPoints: 842190,
          liquidPoolInr: 84219,
          lockedPoints: 218400,
          lockedPoolInr: 21840,
        );

        expect(statsWithGrowth.hasGrowthComparison, isTrue);
        expect(statsWithGrowth.formattedGrowthBadge, '+12.4%');
        expect(statsWithGrowth.formattedTotalClaims, '4,892');
        expect(statsWithGrowth.formattedNetValueInr, '₹1,48,250');
        expect(
          statsWithGrowth.formattedPointsGivenSubtitle,
          '≈ 14.8L pts given',
        );
        expect(statsWithGrowth.formattedLiquidPoints, '8,42,190 pts');
        expect(statsWithGrowth.formattedLiquidPoolSubtitle, '≈ ₹84,219 pool');
        expect(statsWithGrowth.formattedLockedPoints, '2,18,400 pts');
        expect(statsWithGrowth.formattedLockedPoolSubtitle, '≈ ₹21,840 locked');

        const statsWithoutPriorComparison = DashboardStatisticsEntity(
          totalClaimsProcessed: 3,
          claimsGrowthPct: null,
        );
        expect(statsWithoutPriorComparison.hasGrowthComparison, isFalse);
        expect(statsWithoutPriorComparison.formattedGrowthBadge, isNull);
      },
    );

    test(
      '2. DashboardOverviewModel parses RPC JSON and preserves historical ledger conversion snapshots',
      () {
        final model = DashboardOverviewModel.fromJson({
          'admin_profile': {
            'id': 'admin-1',
            'full_name': 'Mohamed Sinas',
            'email': 'mohamedsinaasp@gmail.com',
            'role_label': 'Super Admin',
            'organization_label': 'ShiftEx Central Control',
          },
          'statistics': {
            'total_claims_processed': 12,
            'claims_growth_pct': null,
            'net_value_inr': 20.0,
            'total_points_given': 350,
            'active_points_per_rupee': 20,
            'active_points_to_inr_rate': 0.05,
            'liquid_points': 260,
            'liquid_pool_inr': 13.0,
            'locked_points': 60,
            'locked_pool_inr': 3.0,
          },
          'master_ledger': [
            {
              'id': 'bb541136-24c9-44ee-a06c-df728b5c5002',
              'short_tx_code': 'TXN-BB541',
              'user_id': 'u-1',
              'customer_name': 'mhd sinas p',
              'membership_id': 'SHFT-81F6',
              'transaction_type': 'merchant_reward',
              'category': 'purchases',
              'title': 'Counter #1 POS',
              'points_delta': 250,
              'points_per_rupee': 10, // historical rate was 10 pts = ₹1 even though active rate is 20
              'points_to_inr_rate': 0.10,
              'inr_value': 25.00, // historical ₹25.00 preserved!
              'is_auto_bonus': false,
              'created_at': '2026-11-17T13:23:08.092787+00:00',
            },
          ],
        });

        expect(model.adminProfile.firstName, 'Mohamed');
        expect(model.statistics.activePointsPerRupee, 20);
        expect(model.statistics.liquidPoints, 260);
        expect(model.statistics.liquidPoolInr, 13.0);
        // Historical ledger entry retains its original snapshot & shows points-only subvalue
        expect(model.masterLedger.single.pointsPerRupee, 10);
        expect(model.masterLedger.single.inrValue, 25.00);
        expect(model.masterLedger.single.formattedSubValue, 'Points Credited');
      },
    );
  });

  group('DashboardBloc State & Workflow Verification', () {
    test(
      '3. LoadDashboardRequested loads real data and filters out expired pending claims',
      () async {
        dashboardBloc.add(const LoadDashboardRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(dashboardBloc.state.status, DashboardStatus.loaded);
        expect(dashboardBloc.state.adminProfile.firstName, 'Mohamed');
        expect(dashboardBloc.state.statistics.totalClaimsProcessed, 4892);
        expect(dashboardBloc.state.pendingVerifications.length, 2);
        // Expired claim (claim-expired) is filtered out automatically
        expect(dashboardBloc.state.pendingClaims.length, 1);
        expect(
          dashboardBloc.state.pendingClaims.single.claimReference,
          'CLM-9942-X7B',
        );
        expect(dashboardBloc.state.topPerformingUsers.length, 3);
        expect(dashboardBloc.state.systemActivityLog.length, 2);
      },
    );

    test(
      '4. ChangeLedgerCategoryFilterRequested filters Master Ledger by Purchases, Redemptions, Streak, and All',
      () async {
        dashboardBloc.add(const LoadDashboardRequested());
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(dashboardBloc.state.masterLedger.length, 3);

        dashboardBloc.add(
          const ChangeLedgerCategoryFilterRequested(
            LedgerCategoryFilter.purchases,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(
          dashboardBloc.state.selectedLedgerFilter,
          LedgerCategoryFilter.purchases,
        );
        expect(dashboardBloc.state.masterLedger.length, 1);
        expect(
          dashboardBloc.state.masterLedger.single.title,
          'Organic Harvest Cafe',
        );

        dashboardBloc.add(
          const ChangeLedgerCategoryFilterRequested(
            LedgerCategoryFilter.redemptions,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(dashboardBloc.state.masterLedger.length, 1);
        expect(
          dashboardBloc.state.masterLedger.single.title,
          'Blue Tokai Roastery',
        );

        dashboardBloc.add(
          const ChangeLedgerCategoryFilterRequested(
            LedgerCategoryFilter.streak,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(dashboardBloc.state.masterLedger.length, 1);
        expect(
          dashboardBloc.state.masterLedger.single.formattedSubValue,
          'Auto-Bonus',
        );
      },
    );

    test(
      '5. ApprovePendingCustomerFromDashboardRequested reuses ApproveCustomerUseCase and updates pending list',
      () async {
        dashboardBloc.add(const LoadDashboardRequested());
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(dashboardBloc.state.pendingVerifications.length, 2);

        dashboardBloc.add(
          const ApprovePendingCustomerFromDashboardRequested(
            '9102aaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(
          fakeUserRepo.approvedCustomerIds,
          contains('9102aaaa-bbbb-cccc-dddd-eeeeeeeeeeee'),
        );
        expect(dashboardBloc.state.pendingVerifications.length, 1);
        expect(
          dashboardBloc.state.pendingVerifications.single.fullName,
          'Priya Nair',
        );
        expect(
          dashboardBloc.state.successMessage,
          'Customer approved and wallet activated.',
        );
      },
    );

    test(
      '6. Unauthorized / failure state emits DashboardStatus.error and recovers on retry',
      () async {
        fakeDashboardRepo.shouldFail = true;
        dashboardBloc.add(const LoadDashboardRequested());
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(dashboardBloc.state.status, DashboardStatus.error);
        expect(
          dashboardBloc.state.errorMessage,
          contains('Only authorized admins'),
        );

        fakeDashboardRepo.shouldFail = false;
        dashboardBloc.add(const LoadDashboardRequested());
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(dashboardBloc.state.status, DashboardStatus.loaded);
        expect(dashboardBloc.state.errorMessage, isEmpty);
      },
    );
  });

  group('AdminDashboardView UI & Navigation Verification', () {
    testWidgets(
      '7. Renders all dashboard sections, statistics, live claim countdown, and executes actions without overflow on 390px and 320px viewports',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        String? lastNavigatedUri;
        final router = GoRouter(
          initialLocation: RouteNames.dashboardRoute,
          routes: [
            GoRoute(
              path: RouteNames.dashboardRoute,
              builder: (context, state) => BlocProvider<DashboardBloc>.value(
                value: dashboardBloc,
                child: const AdminDashboardView(),
              ),
            ),
            GoRoute(
              path: RouteNames.scanPosRoute,
              builder: (context, state) {
                lastNavigatedUri = state.uri.toString();
                return Scaffold(
                  body: Center(child: Text('ScanPOS: ${state.uri}')),
                );
              },
            ),
            GoRoute(
              path: RouteNames.userManagementRoute,
              builder: (context, state) {
                lastNavigatedUri = state.uri.toString();
                return Scaffold(
                  body: Center(child: Text('Users: ${state.uri}')),
                );
              },
            ),
            GoRoute(
              path: RouteNames.masterLedgerRoute,
              builder: (context, state) {
                lastNavigatedUri = state.uri.toString();
                return BlocProvider<DashboardBloc>.value(
                  value: dashboardBloc,
                  child: const MasterLedgerView(),
                );
              },
            ),
          ],
        );

        await tester.runAsync(() async {
          dashboardBloc.add(const LoadDashboardRequested());
          await Future<void>.delayed(const Duration(milliseconds: 60));
        });

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pump();

        // 1) Header & Greeting
        expect(find.byKey(const Key('dashboard_greeting_text')), findsOneWidget);
        expect(find.textContaining('Mohamed'), findsOneWidget);
        expect(
          find.text('Super Admin • ShiftEx Central Control'),
          findsOneWidget,
        );

        // 2) Quick Actions
        expect(
          find.byKey(const Key('quick_action_add_reward_card')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('quick_action_verify_claim_card')),
          findsOneWidget,
        );

        // 3) 4 Statistics Cards (Points-only, zero currency)
        expect(find.text('4,892'), findsOneWidget);
        expect(find.text('+12.4%'), findsOneWidget);
        expect(find.text('Points Given'), findsOneWidget);
        expect(find.text('14.8L pts'), findsOneWidget);
        expect(find.text('8,42,190 pts'), findsOneWidget);
        expect(find.text('2,18,400 pts'), findsOneWidget);
        expect(find.textContaining('₹'), findsNothing);

        // 4) User Verifications
        expect(find.text('User Verifications'), findsOneWidget);
        expect(find.text('Rahul Verma'), findsOneWidget);
        expect(find.text('Priya Nair'), findsOneWidget);

        // 5) Pending Claims & live countdown
        expect(find.text('Pending Claims'), findsOneWidget);
        expect(find.text('CLM-9942-X7B'), findsOneWidget);
        expect(find.text('Blue Tokai Counter'), findsOneWidget);
        expect(find.text('Quick Verify'), findsOneWidget);

        // 6) Master Ledger & Category Tabs
        expect(find.text('Master Ledger'), findsOneWidget);
        expect(find.text('Organic Harvest Cafe'), findsOneWidget);
        expect(find.text('Blue Tokai Roastery'), findsOneWidget);
        expect(find.text('7-Day Shift Streak Bonus'), findsOneWidget);
        expect(find.text('Auto-Bonus'), findsOneWidget);

        // 7) Top Performing Users
        expect(find.text('Top Performing Users'), findsOneWidget);
        expect(find.text('3,450 pts'), findsOneWidget);
        expect(find.text('Top Earner'), findsOneWidget);
        expect(find.text('Devika R.'), findsOneWidget);
        expect(find.text('Rohan Mathew'), findsOneWidget);

        // 8) System Activity Log
        expect(find.text('System Activity Log'), findsOneWidget);
        expect(find.text('Terminal #04 Handshake Verified'), findsOneWidget);
        expect(
          find.text('Batch settlement auto-released 1,200 pts'),
          findsOneWidget,
        );

        // Test narrow 320px viewport for zero overflow
        await tester.binding.setSurfaceSize(const Size(320, 740));
        await tester.pump();
        expect(tester.takeException(), isNull);

        // Restore 390px viewport and test Quick Verify navigation
        await tester.binding.setSurfaceSize(const Size(390, 844));
        await tester.pump();

        final quickVerifyBtn = find.byKey(
          const Key('quick_verify_claim_claim-1'),
        );
        await tester.ensureVisible(quickVerifyBtn);
        await tester.tap(quickVerifyBtn);
        await tester.pumpAndSettle();

        expect(lastNavigatedUri, isNotNull);
        expect(lastNavigatedUri, contains('/scan-pos'));
        expect(lastNavigatedUri, contains('mode=verify_claim'));
        expect(lastNavigatedUri, contains('CLM-9942-X7B'));
      },
    );
  });
}
