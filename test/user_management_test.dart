import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftexadmin/features/user_management/domain/entities/customer_entity.dart';
import 'package:shiftexadmin/features/user_management/domain/entities/user_statistics_entity.dart';
import 'package:shiftexadmin/features/user_management/domain/repositories/user_management_repository.dart';
import 'package:shiftexadmin/features/user_management/domain/usecases/approve_customer_usecase.dart';
import 'package:shiftexadmin/features/user_management/domain/usecases/create_customer_usecase.dart';
import 'package:shiftexadmin/features/user_management/domain/usecases/get_customer_details_usecase.dart';
import 'package:shiftexadmin/features/user_management/domain/usecases/get_customers_usecase.dart';
import 'package:shiftexadmin/features/user_management/domain/usecases/get_top_earners_usecase.dart';
import 'package:shiftexadmin/features/user_management/domain/usecases/get_user_statistics_usecase.dart';
import 'package:shiftexadmin/features/user_management/domain/usecases/reject_customer_usecase.dart';
import 'package:shiftexadmin/features/user_management/presentation/bloc/user_management_bloc.dart';
import 'package:shiftexadmin/features/user_management/presentation/bloc/user_management_event.dart';
import 'package:shiftexadmin/features/user_management/presentation/bloc/user_management_state.dart';
import 'package:shiftexadmin/features/user_management/presentation/pages/user_management_page.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/admin_bottom_nav_bar_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/approval_confirmation_dialog_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/create_customer_sheet_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/customer_directory_card_shimmer_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/customer_search_bar_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/rejection_reason_dialog_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/top_earners_card_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/user_management_shimmer_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/user_statistics_grid_widget.dart';

class _FakeUserManagementRepo implements UserManagementRepository {
  final List<CustomerEntity> customers = [];
  String? errorToThrow;
  int createCallCount = 0;

  @override
  Future<List<CustomerEntity>> getCustomers({
    String? status,
    String? searchQuery,
    String? sortBy,
    int limit = 50,
    int offset = 0,
  }) async {
    return List<CustomerEntity>.from(customers);
  }

  @override
  Future<List<CustomerEntity>> getTopEarners({
    String range = 'weekly',
    int limit = 3,
  }) async {
    return customers.where((c) => c.instantPoints > 0).take(limit).toList();
  }

  @override
  Future<UserStatisticsEntity> getUserStatistics() async {
    final approved = customers.where((c) => c.isApproved).length;
    final pending = customers.where((c) => c.isPending).length;
    return UserStatisticsEntity(
      registeredCount: customers.length,
      pendingCount: pending,
      activeCount: approved,
      restrictedCount: 0,
    );
  }

  @override
  Future<CustomerEntity> getCustomerDetails(String customerId) async {
    return customers.firstWhere((c) => c.id == customerId);
  }

  @override
  Future<void> approveCustomer(String customerId) async {}

  @override
  Future<void> rejectCustomer(String customerId, String reason) async {}

  @override
  Future<CustomerEntity> createCustomer({
    required String fullName,
    required String email,
    required String mobileNumber,
    required String password,
    String approvalStatus = 'approved',
    String membershipTier = 'Pebble Black Member',
    int initialPoints = 0,
  }) async {
    createCallCount++;
    if (errorToThrow != null) {
      throw Exception(errorToThrow);
    }
    final now = DateTime.now();
    final created = CustomerEntity(
      id: 'cust-new-$createCallCount',
      fullName: fullName,
      email: email,
      mobileNumber: mobileNumber,
      approvalStatus: approvalStatus,
      customerCode: 'SHFT-NEW$createCallCount',
      membershipTier: membershipTier,
      instantPoints: initialPoints,
      earnedPoints: initialPoints,
      createdAt: now,
      updatedAt: now,
    );
    customers.insert(0, created);
    return created;
  }
}

void main() {
  group('CustomerEntity Tests', () {
    final now = DateTime.now();

    test('CustomerEntity computes correct initials and formatted ID', () {
      final customer = CustomerEntity(
        id: '12345678-abcd-ef01-2345-6789abcdef01',
        fullName: 'Rahul Verma',
        email: 'rahul@example.com',
        mobileNumber: '+919876543210',
        approvalStatus: 'pending',
        createdAt: now,
        updatedAt: now,
      );

      expect(customer.initials, 'RV');
      expect(customer.formattedCustomerId, 'SHFT-1234');
      expect(customer.isPending, true);
      expect(customer.isApproved, false);
      expect(customer.isRestricted, false);
    });

    test('CustomerEntity handles single word names and approved status', () {
      final customer = CustomerEntity(
        id: 'abcd1234',
        fullName: 'Devika',
        email: 'devika@example.com',
        mobileNumber: '+919811122334',
        approvalStatus: 'approved',
        createdAt: now,
        updatedAt: now,
      );

      expect(customer.initials, 'DE');
      expect(customer.isApproved, true);
      expect(customer.isPending, false);
    });
  });

  group('UserManagementState Tests', () {
    test('topPendingCustomer returns the first pending customer', () {
      final now = DateTime.now();
      final customer1 = CustomerEntity(
        id: '1',
        fullName: 'Approved User',
        email: 'app@example.com',
        mobileNumber: '111',
        approvalStatus: 'approved',
        createdAt: now,
        updatedAt: now,
      );
      final customer2 = CustomerEntity(
        id: '2',
        fullName: 'Pending User',
        email: 'pen@example.com',
        mobileNumber: '222',
        approvalStatus: 'pending',
        createdAt: now,
        updatedAt: now,
      );

      final state = UserManagementState(customers: [customer1, customer2]);

      expect(state.topPendingCustomer, customer2);
      expect(state.topPendingCustomer?.fullName, 'Pending User');
    });
  });

  group('User Management Widget Tests', () {
    testWidgets('UserStatisticsGridWidget renders correct data', (
      WidgetTester tester,
    ) async {
      const stats = UserStatisticsEntity(
        registeredCount: 12480,
        pendingCount: 3,
        activeCount: 11850,
        restrictedCount: 24,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: UserStatisticsGridWidget(statistics: stats)),
        ),
      );

      expect(find.text('Registered'), findsOneWidget);
      expect(find.text('12,480'), findsOneWidget);
      expect(find.text('3 Users'), findsOneWidget);
      expect(find.text('11,850'), findsOneWidget);
      expect(find.text('24 Users'), findsOneWidget);
    });

    testWidgets('CustomerSearchBarWidget renders with hint and clear button', (
      WidgetTester tester,
    ) async {
      String searched = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomerSearchBarWidget(
              initialValue: 'Rahul',
              onSearchChanged: (val) {
                searched = val;
              },
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.cancel_outlined));
      await tester.pump();

      expect(searched, '');
    });

    testWidgets('ApprovalConfirmationDialogWidget triggers confirmation', (
      WidgetTester tester,
    ) async {
      bool approved = false;
      final now = DateTime.now();
      final customer = CustomerEntity(
        id: '1234',
        fullName: 'Rahul Verma',
        email: 'rahul@example.com',
        mobileNumber: '+919876543210',
        approvalStatus: 'pending',
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ApprovalConfirmationDialogWidget.show(
                    context,
                    customer: customer,
                    onConfirm: () {
                      approved = true;
                    },
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Approve Customer'), findsOneWidget);
      expect(find.text('Confirm Approval'), findsOneWidget);

      await tester.tap(find.text('Confirm Approval'));
      await tester.pumpAndSettle();

      expect(approved, true);
    });

    testWidgets('RejectionReasonDialogWidget validates empty reason', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();
      final customer = CustomerEntity(
        id: '1234',
        fullName: 'Rahul Verma',
        email: 'rahul@example.com',
        mobileNumber: '+919876543210',
        approvalStatus: 'pending',
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  RejectionReasonDialogWidget.show(context, customer: customer);
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Reject Customer'), findsNWidgets(2)); // Title & button

      // Tap Reject Customer button without typing
      await tester.tap(find.widgetWithText(ElevatedButton, 'Reject Customer'));
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter or select a rejection reason'),
        findsOneWidget,
      );
    });

    testWidgets('AdminBottomNavBarWidget renders and triggers tab selections', (
      WidgetTester tester,
    ) async {
      int selectedTab = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AdminBottomNavBarWidget(
              currentIndex: 0,
              onTabSelected: (index) {
                selectedTab = index;
              },
            ),
          ),
        ),
      );

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Users'), findsOneWidget);
      expect(find.text('Scan POS'), findsOneWidget);
      expect(find.text('Ads'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Tap Users tab
      await tester.tap(find.text('Users'));
      expect(selectedTab, 1);

      // Tap Scan POS center action
      await tester.tap(find.text('Scan POS'));
      expect(selectedTab, 99);

      // Tap Ads tab
      await tester.tap(find.text('Ads'));
      expect(selectedTab, 2);

      // Tap Settings tab
      await tester.tap(find.text('Settings'));
      expect(selectedTab, 3);
    });

    testWidgets(
      'UserManagementShimmerWidget and directory shimmer render without overflow',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: UserManagementShimmerWidget(),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(UserManagementShimmerWidget), findsOneWidget);
        expect(
          find.byType(CustomerDirectoryCardShimmerWidget),
          findsNWidgets(3),
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CustomerDirectoryShimmerListWidget(itemCount: 2),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 500));
        expect(
          find.byType(CustomerDirectoryCardShimmerWidget),
          findsNWidgets(2),
        );
      },
    );

    testWidgets(
      'TopEarnersCardWidget renders dynamic earned points and INR values and switches range tabs',
      (WidgetTester tester) async {
        final now = DateTime.now();
        String selectedRange = 'Weekly';

        final customers = [
          CustomerEntity(
            id: '81f63aaf-51d7-44f3-9cf2-77a1c35d5793',
            fullName: 'mhd sinas p',
            email: 'sinas@shiftex.in',
            mobileNumber: '+919048551457',
            approvalStatus: 'approved',
            customerCode: 'SHFT-81F6',
            earnedPoints: 355,
            earnedRupees: 19.50,
            earnedTxCount: 5,
            instantPoints: 260,
            instantRupees: 13.00,
            createdAt: now,
            updatedAt: now,
          ),
          CustomerEntity(
            id: 'd15cb2e2-240c-46f7-bd5d-024058d9dea1',
            fullName: 'haptic done',
            email: 'haptic@shiftex.in',
            mobileNumber: '+917034266250',
            approvalStatus: 'approved',
            customerCode: 'SHFT-D15C',
            earnedPoints: 15,
            earnedRupees: 1.50,
            earnedTxCount: 1,
            createdAt: now,
            updatedAt: now,
          ),
          CustomerEntity(
            id: '00000000-0000-0000-0000-000000000000',
            fullName: 'Zero Points User',
            email: 'zero@shiftex.in',
            mobileNumber: '+910000000000',
            approvalStatus: 'approved',
            earnedPoints: 0,
            instantPoints: 0,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TopEarnersCardWidget(
                customers: customers,
                selectedRange: selectedRange,
                onRangeChanged: (range) {
                  selectedRange = range;
                },
              ),
            ),
          ),
        );

        expect(find.text('Top Earners'), findsOneWidget);
        expect(find.text('mhd sinas p'), findsOneWidget);
        expect(find.text('355 pts'), findsOneWidget);
        expect(find.text('Top Earner'), findsOneWidget);
        expect(find.text('haptic done'), findsOneWidget);
        expect(find.text('15 pts'), findsOneWidget);
        expect(find.text('Total Earned'), findsOneWidget);
        expect(find.textContaining('₹'), findsNothing);
        // Zero-point user is not shown with fake 2200/1900 fallback points
        expect(find.text('Zero Points User'), findsNothing);
        expect(find.text('2200 pts'), findsNothing);

        await tester.tap(find.byKey(const Key('top_earners_range_monthly')));
        await tester.pump();
        expect(selectedRange, 'Monthly');

        await tester.tap(find.byKey(const Key('top_earners_range_all')));
        await tester.pump();
        expect(selectedRange, 'All');
      },
    );
  });

  group('Add User (Create Customer Account) End-to-End Flow', () {
    late _FakeUserManagementRepo fakeRepo;
    late UserManagementBloc bloc;

    setUp(() {
      fakeRepo = _FakeUserManagementRepo();
      bloc = UserManagementBloc(
        getCustomersUseCase: GetCustomersUseCase(repository: fakeRepo),
        getUserStatisticsUseCase: GetUserStatisticsUseCase(repository: fakeRepo),
        approveCustomerUseCase: ApproveCustomerUseCase(repository: fakeRepo),
        rejectCustomerUseCase: RejectCustomerUseCase(repository: fakeRepo),
        getCustomerDetailsUseCase: GetCustomerDetailsUseCase(
          repository: fakeRepo,
        ),
        getTopEarnersUseCase: GetTopEarnersUseCase(repository: fakeRepo),
        createCustomerUseCase: CreateCustomerUseCase(repository: fakeRepo),
      );
    });

    tearDown(() async {
      await bloc.close();
    });

    test('CreateCustomerUseCase validates inputs and normalizes 10-digit mobile numbers', () async {
      final useCase = CreateCustomerUseCase(repository: fakeRepo);

      expect(
        () => useCase.execute(
          fullName: 'A',
          email: 'valid@example.com',
          mobileNumber: '9876543210',
          password: 'Password@123',
          confirmPassword: 'Password@123',
        ),
        throwsArgumentError,
      );

      expect(
        () => useCase.execute(
          fullName: 'Ananya K.',
          email: 'invalid-email',
          mobileNumber: '9876543210',
          password: 'Password@123',
          confirmPassword: 'Password@123',
        ),
        throwsArgumentError,
      );

      expect(
        () => useCase.execute(
          fullName: 'Ananya K.',
          email: 'ananya@example.com',
          mobileNumber: '9876543210',
          password: 'weak',
          confirmPassword: 'weak',
        ),
        throwsArgumentError,
      );

      final created = await useCase.execute(
        fullName: 'Ananya Krishnan',
        email: 'ANANYA@EXAMPLE.COM',
        mobileNumber: '9876543210',
        password: 'Password@123',
        confirmPassword: 'Password@123',
        initialPoints: 50,
      );

      expect(created.email, 'ananya@example.com');
      expect(created.mobileNumber, '+919876543210');
      expect(created.instantPoints, 50);
      expect(fakeRepo.createCallCount, 1);
    });

    test('CreateCustomerRequested refreshes statistics and customer list on success', () async {
      bloc.add(
        const CreateCustomerRequested(
          fullName: 'Karthik Raj',
          email: 'karthik@example.com',
          mobileNumber: '+919988776655',
          password: 'Password@123',
          confirmPassword: 'Password@123',
          approvalStatus: 'approved',
          membershipTier: 'Gold Tier',
          initialPoints: 100,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.status, UserManagementStatus.loaded);
      expect(bloc.state.customers.length, 1);
      expect(bloc.state.customers.first.fullName, 'Karthik Raj');
      expect(bloc.state.customers.first.instantPoints, 100);
      expect(bloc.state.statistics.registeredCount, 1);
      expect(bloc.state.statistics.activeCount, 1);
      expect(bloc.state.successMessage, contains('Customer account created'));
    });

    testWidgets(
      'Tapping Add User opens CreateCustomerSheetWidget, validates & creates customer cleanly on 390px and 320px viewports',
      (tester) async {
        tester.view.physicalSize = const Size(390, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.runAsync(() async {
          bloc.add(const LoadUserManagementRequested());
          await Future<void>.delayed(const Duration(milliseconds: 30));
        });

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<UserManagementBloc>.value(
              value: bloc,
              child: const UserManagementView(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap Add User button in header
        await tester.tap(find.text('Add User'));
        await tester.pumpAndSettle();

        expect(find.byType(CreateCustomerSheetWidget), findsOneWidget);
        expect(find.text('Add Customer Account'), findsOneWidget);
        expect(find.textContaining('₹'), findsNothing);

        // Submit empty form -> shows validation error
        final submitBtn = find.byKey(
          const Key('submit_create_customer_button'),
        );
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();
        expect(
          find.text('Please enter the customer\'s full name.'),
          findsOneWidget,
        );

        // Fill valid customer fields and submit
        await tester.enterText(
          find.byKey(const Key('add_customer_name_input')),
          'Meera Nair',
        );
        await tester.enterText(
          find.byKey(const Key('add_customer_email_input')),
          'meera@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('add_customer_mobile_input')),
          '9876501234',
        );
        await tester.enterText(
          find.byKey(const Key('add_customer_password_input')),
          'Customer@2026',
        );
        await tester.enterText(
          find.byKey(const Key('add_customer_confirm_password_input')),
          'Customer@2026',
        );
        await tester.enterText(
          find.byKey(const Key('add_customer_initial_points_input')),
          '25',
        );

        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pumpAndSettle();

        expect(fakeRepo.createCallCount, 1);
        expect(find.byType(CreateCustomerSheetWidget), findsNothing);
        expect(find.text('Meera Nair'), findsWidgets);
        expect(tester.takeException(), isNull);

        // Compact 320px phone viewport check
        tester.view.physicalSize = const Size(320, 640);
        await tester.tap(find.text('Add User'));
        await tester.pumpAndSettle();
        expect(find.byType(CreateCustomerSheetWidget), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
