import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_access_audit_log_entity.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_access_overview_entity.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_operator_entity.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_permission.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/repositories/admin_access_repository.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/usecases/create_admin_account_usecase.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/usecases/get_admin_access_overview_usecase.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/usecases/update_admin_operator_permissions_usecase.dart';
import 'package:shiftexadmin/features/settings/admin_access/presentation/bloc/admin_access_bloc.dart';
import 'package:shiftexadmin/features/settings/admin_access/presentation/bloc/admin_access_event.dart';
import 'package:shiftexadmin/features/settings/admin_access/presentation/bloc/admin_access_state.dart';
import 'package:shiftexadmin/features/settings/admin_access/presentation/widgets/admin_access_card_widget.dart';
import 'package:shiftexadmin/features/settings/admin_access/presentation/widgets/create_admin_account_sheet_widget.dart';
import 'package:shiftexadmin/features/settings/admin_access/presentation/widgets/manage_admin_operator_sheet_widget.dart';

class _FakeAdminAccessRepository implements AdminAccessRepository {
  final StreamController<AdminOperatorEntity?> _controller =
      StreamController<AdminOperatorEntity?>.broadcast();

  AdminOperatorEntity? _cached;
  late List<AdminOperatorEntity> operators;
  List<AdminAccessAuditLogEntity> auditLogs = [];
  bool simulateEdgeFunctionFailure = false;
  AdminOperatorEntity? currentSessionOverride;

  _FakeAdminAccessRepository() {
    final now = DateTime.now();
    operators = [
      AdminOperatorEntity(
        userId: 'op-owner-1',
        fullName: 'Mohamed Sinas',
        email: 'mohamedsinaasp@gmail.com',
        role: AdminRoleType.superAdmin,
        terminalAssignment: 'ShiftEx Central Control',
        permissionSummary: 'All Permissions',
        badgeLabel: 'Key Master',
        isKeyMaster: true,
        isCurrentUser: true,
        status: 'active',
        permissions: AdminPermission.allPermissions,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now,
      ),
      AdminOperatorEntity(
        userId: 'op-manager-2',
        fullName: 'Rahul V.',
        email: 'rahul.v@shiftex.vault',
        role: AdminRoleType.storeManager,
        terminalAssignment: 'Term #02',
        permissionSummary: 'Verify Claim Only',
        badgeLabel: 'Verify Only',
        isKeyMaster: false,
        isCurrentUser: false,
        status: 'active',
        permissions: AdminRoleType.storeManager.defaultPermissions,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now,
      ),
      AdminOperatorEntity(
        userId: 'op-auditor-3',
        fullName: 'Priya N.',
        email: 'priya.n@shiftex.vault',
        role: AdminRoleType.auditor,
        terminalAssignment: 'Read-only Ledger',
        permissionSummary: 'Read-only Ledger',
        badgeLabel: 'KYC Verify',
        isKeyMaster: false,
        isCurrentUser: false,
        status: 'active',
        permissions: AdminRoleType.auditor.defaultPermissions,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
      ),
    ];
    _cached = operators.first;
  }

  @override
  Stream<AdminOperatorEntity?> get currentAdminStream => _controller.stream;

  @override
  AdminOperatorEntity? get cachedCurrentAdmin => _cached;

  @override
  Future<AdminAccessOverviewEntity> getAdminAccessOverview() async {
    final current = currentSessionOverride ?? operators.first;
    _cached = current;
    _controller.add(_cached);
    return AdminAccessOverviewEntity(
      currentAdmin: current,
      operatorsCount: operators.where((o) => o.status != 'revoked').length,
      operators: List.unmodifiable(
        operators.where((o) => o.status != 'revoked'),
      ),
      auditLogs: List.unmodifiable(auditLogs),
    );
  }

  @override
  Future<AdminOperatorEntity> createAdminAccount({
    required String fullName,
    required String email,
    required String password,
    required AdminRoleType role,
    required String terminalAssignment,
    required List<String> permissions,
  }) async {
    if (simulateEdgeFunctionFailure) {
      throw Exception(
        'Failed to provision admin profile. Auth user rolled back.',
      );
    }

    final caller = currentSessionOverride ?? operators.first;
    if (!caller.canCreateAdminAccount) {
      throw Exception(
        'Only active Super Admins are authorized to create Admin accounts.',
      );
    }

    if (operators.any((op) => op.email.toLowerCase() == email.toLowerCase())) {
      throw Exception('An admin account with email $email already exists.');
    }

    final now = DateTime.now();
    final created = AdminOperatorEntity(
      userId: 'op-new-${operators.length + 1}',
      fullName: fullName,
      email: email,
      role: role,
      terminalAssignment: terminalAssignment,
      permissionSummary: role == AdminRoleType.superAdmin
          ? 'All Permissions'
          : (role == AdminRoleType.storeManager
                ? 'Verify Claim Only'
                : 'Read-only Ledger'),
      badgeLabel: role == AdminRoleType.superAdmin
          ? 'Full Access'
          : (role == AdminRoleType.storeManager ? 'Verify Only' : 'KYC Verify'),
      isKeyMaster: false,
      isCurrentUser: false,
      status: 'active',
      permissions: permissions,
      createdBy: caller.userId,
      createdAt: now,
      updatedAt: now,
    );
    operators.add(created);
    auditLogs.insert(
      0,
      AdminAccessAuditLogEntity(
        id: 'log-${auditLogs.length + 1}',
        actorUserId: caller.userId,
        actorEmail: caller.email,
        targetUserId: created.userId,
        targetEmail: created.email,
        action: 'CREATE_ADMIN_ACCOUNT',
        newRole: role.dbValue,
        newPermissions: permissions,
        note: 'Created admin account for $fullName (${role.dbValue})',
        createdAt: now,
      ),
    );
    return created;
  }

  @override
  Future<AdminOperatorEntity> updateOperatorPermissions({
    required String targetUserId,
    required AdminRoleType role,
    required String terminalAssignment,
    required List<String> permissions,
    String status = 'active',
  }) async {
    final idx = operators.indexWhere((o) => o.userId == targetUserId);
    if (idx < 0) throw Exception('Operator not found.');
    final target = operators[idx];
    if (target.isKeyMaster &&
        (role != AdminRoleType.superAdmin || status != 'active')) {
      throw Exception(
        'The primary Key Master owner account cannot be demoted or locked out.',
      );
    }

    final updated = AdminOperatorEntity(
      userId: target.userId,
      fullName: target.fullName,
      email: target.email,
      role: role,
      terminalAssignment: terminalAssignment,
      permissionSummary: role == AdminRoleType.superAdmin
          ? 'All Permissions'
          : (role == AdminRoleType.storeManager
                ? 'POS Operations'
                : 'Read-only Ledger'),
      badgeLabel: target.isKeyMaster
          ? 'Key Master'
          : (role == AdminRoleType.storeManager ? 'Verify Only' : 'KYC Verify'),
      isKeyMaster: target.isKeyMaster,
      isCurrentUser: target.isCurrentUser,
      status: status,
      permissions: permissions,
      createdBy: target.createdBy,
      createdAt: target.createdAt,
      updatedAt: DateTime.now(),
    );
    operators[idx] = updated;
    return updated;
  }
}

void main() {
  late _FakeAdminAccessRepository fakeRepo;
  late AdminAccessBloc bloc;

  setUp(() {
    fakeRepo = _FakeAdminAccessRepository();
    bloc = AdminAccessBloc(
      getAdminAccessOverviewUseCase: GetAdminAccessOverviewUseCase(fakeRepo),
      createAdminAccountUseCase: CreateAdminAccountUseCase(fakeRepo),
      updateAdminOperatorPermissionsUseCase:
          UpdateAdminOperatorPermissionsUseCase(fakeRepo),
    );
  });

  tearDown(() async {
    await bloc.close();
  });

  group('Direct Admin Account Creation & Role Security Verification', () {
    test(
      '1. Super Admin creates Store Manager, Auditor, and Super Admin with active status and audit logs',
      () async {
        bloc.add(const LoadAdminAccessRequested());
        await Future<void>.delayed(const Duration(milliseconds: 25));
        expect(bloc.state.operatorsCount, 3);

        // 1) Create Store Manager
        bloc.add(
          CreateAdminAccountRequested(
            fullName: 'Arjun Nair',
            email: 'arjun.manager@shiftex.vault',
            password: 'StrongPassword#1',
            confirmPassword: 'StrongPassword#1',
            role: AdminRoleType.storeManager,
            terminalAssignment: 'Term #04',
            permissions: AdminRoleType.storeManager.defaultPermissions,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 35));

        expect(bloc.state.operatorsCount, 4);
        expect(
          bloc.state.operators.last.email,
          'arjun.manager@shiftex.vault',
        );
        expect(bloc.state.operators.last.role, AdminRoleType.storeManager);
        expect(bloc.state.operators.last.status, 'active');
        expect(
          bloc.state.successMessage,
          contains('Ready for immediate login'),
        );

        // 2) Create Auditor
        bloc.add(
          CreateAdminAccountRequested(
            fullName: 'Meera K.',
            email: 'meera.auditor@shiftex.vault',
            password: 'StrongPassword#2',
            confirmPassword: 'StrongPassword#2',
            role: AdminRoleType.auditor,
            terminalAssignment: 'Read-only Ledger',
            permissions: AdminRoleType.auditor.defaultPermissions,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 35));

        expect(bloc.state.operatorsCount, 5);
        expect(bloc.state.operators.last.role, AdminRoleType.auditor);

        // 3) Create another Super Admin
        bloc.add(
          CreateAdminAccountRequested(
            fullName: 'Vikram S.',
            email: 'vikram.super@shiftex.vault',
            password: 'StrongPassword#3',
            confirmPassword: 'StrongPassword#3',
            role: AdminRoleType.superAdmin,
            terminalAssignment: 'ShiftEx Central Control',
            permissions: AdminPermission.allPermissions,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 35));

        expect(bloc.state.operatorsCount, 6);
        expect(bloc.state.operators.last.role, AdminRoleType.superAdmin);
        expect(bloc.state.auditLogs.length, 3);
      },
    );

    test(
      '2. Rejects duplicate email, weak password, and mismatched confirm password',
      () async {
        final useCase = CreateAdminAccountUseCase(fakeRepo);

        // Weak password
        expect(
          () => useCase(
            fullName: 'Test User',
            email: 'new@shiftex.vault',
            password: 'weak',
            confirmPassword: 'weak',
            role: AdminRoleType.storeManager,
            terminalAssignment: 'Term #01',
            permissions: AdminRoleType.storeManager.defaultPermissions,
          ),
          throwsA(
            predicate(
              (e) => e.toString().contains('at least 8 characters'),
            ),
          ),
        );

        // Mismatched confirm password
        expect(
          () => useCase(
            fullName: 'Test User',
            email: 'new@shiftex.vault',
            password: 'StrongPassword#1',
            confirmPassword: 'DifferentPassword#1',
            role: AdminRoleType.storeManager,
            terminalAssignment: 'Term #01',
            permissions: AdminRoleType.storeManager.defaultPermissions,
          ),
          throwsA(
            predicate(
              (e) => e.toString().contains('do not match'),
            ),
          ),
        );

        // Duplicate email rejected
        bloc.add(const LoadAdminAccessRequested());
        await Future<void>.delayed(const Duration(milliseconds: 25));

        bloc.add(
          CreateAdminAccountRequested(
            fullName: 'Duplicate Rahul',
            email: 'rahul.v@shiftex.vault',
            password: 'StrongPassword#1',
            confirmPassword: 'StrongPassword#1',
            role: AdminRoleType.storeManager,
            terminalAssignment: 'Term #02',
            permissions: AdminRoleType.storeManager.defaultPermissions,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(bloc.state.status, AdminAccessStatus.error);
        expect(bloc.state.errorMessage, contains('already exists'));
      },
    );

    test(
      '3. Unauthorized Store Manager or Auditor cannot create Admin accounts, and Edge Function failure is handled cleanly',
      () async {
        // Switch active session to Store Manager (Rahul V.)
        fakeRepo.currentSessionOverride = fakeRepo.operators[1];
        bloc.add(const LoadAdminAccessRequested());
        await Future<void>.delayed(const Duration(milliseconds: 25));

        expect(bloc.state.canCreateAdminAccount, isFalse);

        bloc.add(
          CreateAdminAccountRequested(
            fullName: 'Unauthorized Attempt',
            email: 'unauth@shiftex.vault',
            password: 'StrongPassword#1',
            confirmPassword: 'StrongPassword#1',
            role: AdminRoleType.auditor,
            terminalAssignment: 'Term #02',
            permissions: AdminRoleType.auditor.defaultPermissions,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 25));

        expect(bloc.state.status, AdminAccessStatus.error);
        expect(
          bloc.state.errorMessage,
          contains('Only authorized Super Admins'),
        );

        // Restore Super Admin & test Edge Function failure handling
        fakeRepo.currentSessionOverride = null;
        fakeRepo.simulateEdgeFunctionFailure = true;
        bloc.add(const LoadAdminAccessRequested());
        await Future<void>.delayed(const Duration(milliseconds: 25));

        bloc.add(
          CreateAdminAccountRequested(
            fullName: 'Rollback Test',
            email: 'rollback@shiftex.vault',
            password: 'StrongPassword#1',
            confirmPassword: 'StrongPassword#1',
            role: AdminRoleType.storeManager,
            terminalAssignment: 'Term #02',
            permissions: AdminRoleType.storeManager.defaultPermissions,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(bloc.state.status, AdminAccessStatus.error);
        expect(bloc.state.errorMessage, contains('Auth user rolled back'));
      },
    );
  });

  group('AdminAccessCardWidget & CreateAdminAccountSheetWidget UI Verification', () {
    testWidgets(
      '4. Renders + Create Admin Account button, opens sheet with Password & Confirm Password fields, and creates account without overflow on 390px and 320px viewports',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.runAsync(() async {
          bloc.add(const LoadAdminAccessRequested());
          await Future<void>.delayed(const Duration(milliseconds: 30));
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider<AdminAccessBloc>.value(
                value: bloc,
                child: BlocBuilder<AdminAccessBloc, AdminAccessState>(
                  builder: (context, state) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: AdminAccessCardWidget(
                        state: state,
                        onCreateAdminPressed: () =>
                            CreateAdminAccountSheetWidget.show(
                              context,
                              bloc: bloc,
                            ),
                        onOperatorTapped: (op) =>
                            ManageAdminOperatorSheetWidget.show(
                              context,
                              operatorItem: op,
                              canManage: state.canManageAdmins,
                              bloc: bloc,
                            ),
                        onRetryLoad: () =>
                            bloc.add(const LoadAdminAccessRequested()),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Admin Access'), findsOneWidget);
        expect(find.text('3 registered console operators'), findsOneWidget);
        expect(find.text('Mohamed Sinas (You)'), findsOneWidget);
        expect(find.text('Key Master'), findsOneWidget);
        expect(find.text('+ Create Admin Account'), findsOneWidget);
        expect(find.textContaining('Invite'), findsNothing);

        // Verify narrow 320px screen has zero overflow
        await tester.binding.setSurfaceSize(const Size(320, 740));
        await tester.pump();
        expect(tester.takeException(), isNull);

        await tester.binding.setSurfaceSize(const Size(390, 844));
        await tester.pump();

        // Open Create Admin Account sheet
        await tester.tap(find.byKey(const Key('create_admin_account_button')));
        await tester.pumpAndSettle();

        expect(find.text('Create Admin Account'), findsNWidgets(2));
        expect(
          find.byKey(const Key('create_admin_name_input')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('create_admin_email_input')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('create_admin_password_input')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('create_admin_confirm_password_input')),
          findsOneWidget,
        );

        // Toggle password visibility
        await tester.tap(
          find.byKey(const Key('toggle_admin_password_visibility')),
        );
        await tester.pump();

        // Fill form and submit
        await tester.enterText(
          find.byKey(const Key('create_admin_name_input')),
          'Kiran Rao',
        );
        await tester.enterText(
          find.byKey(const Key('create_admin_email_input')),
          'kiran.rao@shiftex.vault',
        );
        await tester.enterText(
          find.byKey(const Key('create_admin_password_input')),
          'AdminPass#2026',
        );
        await tester.enterText(
          find.byKey(const Key('create_admin_confirm_password_input')),
          'AdminPass#2026',
        );
        await tester.pump();

        final submitBtn = find.byKey(
          const Key('submit_create_admin_account_button'),
        );
        await tester.ensureVisible(submitBtn);
        await tester.runAsync(() async {
          await tester.tap(submitBtn);
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pumpAndSettle();

        expect(find.text('4 registered console operators'), findsOneWidget);
        expect(find.text('Kiran Rao'), findsOneWidget);
      },
    );
  });
}
