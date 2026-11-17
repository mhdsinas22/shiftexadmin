import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftexadmin/features/user_management/domain/entities/customer_entity.dart';
import 'package:shiftexadmin/features/user_management/domain/entities/user_statistics_entity.dart';
import 'package:shiftexadmin/features/user_management/presentation/bloc/user_management_state.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/admin_bottom_nav_bar_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/approval_confirmation_dialog_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/customer_directory_card_shimmer_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/customer_search_bar_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/rejection_reason_dialog_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/user_management_shimmer_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/user_statistics_grid_widget.dart';

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

      final state = UserManagementState(
        customers: [customer1, customer2],
      );

      expect(state.topPendingCustomer, customer2);
      expect(state.topPendingCustomer?.fullName, 'Pending User');
    });
  });

  group('User Management Widget Tests', () {
    testWidgets('UserStatisticsGridWidget renders correct data',
        (WidgetTester tester) async {
      const stats = UserStatisticsEntity(
        registeredCount: 12480,
        pendingCount: 3,
        activeCount: 11850,
        restrictedCount: 24,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserStatisticsGridWidget(statistics: stats),
          ),
        ),
      );

      expect(find.text('Registered'), findsOneWidget);
      expect(find.text('12,480'), findsOneWidget);
      expect(find.text('3 Users'), findsOneWidget);
      expect(find.text('11,850'), findsOneWidget);
      expect(find.text('24 Users'), findsOneWidget);
    });

    testWidgets('CustomerSearchBarWidget renders with hint and clear button',
        (WidgetTester tester) async {
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

    testWidgets('ApprovalConfirmationDialogWidget triggers confirmation',
        (WidgetTester tester) async {
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

    testWidgets('RejectionReasonDialogWidget validates empty reason',
        (WidgetTester tester) async {
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
                  RejectionReasonDialogWidget.show(
                    context,
                    customer: customer,
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

      expect(find.text('Reject Customer'), findsNWidgets(2)); // Title & button

      // Tap Reject Customer button without typing
      await tester.tap(find.widgetWithText(ElevatedButton, 'Reject Customer'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter or select a rejection reason'), findsOneWidget);
    });

    testWidgets('AdminBottomNavBarWidget renders and triggers tab selections',
        (WidgetTester tester) async {
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

    testWidgets('UserManagementShimmerWidget and directory shimmer render without overflow',
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
      expect(find.byType(CustomerDirectoryCardShimmerWidget), findsNWidgets(3));

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
      expect(find.byType(CustomerDirectoryCardShimmerWidget), findsNWidgets(2));
    });
  });
}
