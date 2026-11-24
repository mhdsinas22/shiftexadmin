import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftexadmin/core/routes/route_names.dart';
import 'package:shiftexadmin/core/widgets/admin_top_app_bar_widget.dart';
import 'package:shiftexadmin/features/ads/presentation/widgets/ads_header_widget.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/admin_identity_entity.dart';
import 'package:shiftexadmin/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:shiftexadmin/features/scan_pos/domain/entities/verified_pos_customer_entity.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/widgets/scan_pos_header_widget.dart';
import 'package:shiftexadmin/features/settings/presentation/widgets/settings_header_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/user_management_header_widget.dart';

void main() {
  group('Consistent Admin Top AppBar across all 5 primary screens', () {
    testWidgets(
      'Dashboard, Users, Scan POS, Ads, and Settings all render AdminTopAppBarWidget with matching layout & no overflow',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final headers = <Widget>[
          const DashboardHeader(
            adminProfile: AdminIdentityEntity(
              id: 'adm-1',
              fullName: 'Vishnu K.',
              email: 'vishnu@shiftex.vault',
            ),
            hasUnreadNotifications: true,
          ),
          const UserManagementHeaderWidget(hasUnreadNotifications: true),
          ScanPosHeaderWidget(
            selectedMode: ScanPosMode.giveReward,
            onModeChanged: (_) {},
          ),
          const AdsHeaderWidget(),
          const SettingsHeaderWidget(profileInitials: 'VK'),
        ];

        final capturedTopBarHeights = <double>[];

        for (final header in headers) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: header,
                  ),
                ),
              ),
            ),
          );
          await tester.pump();

          final topBarFinder = find.byType(AdminTopAppBarWidget);
          expect(topBarFinder, findsOneWidget);
          final size = tester.getSize(topBarFinder);
          capturedTopBarHeights.add(size.height);
          expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
          expect(tester.takeException(), isNull);
        }

        // Every page's top app bar has identical 44px height matching Dashboard
        expect(capturedTopBarHeights.toSet().length, 1);
        expect(capturedTopBarHeights.first, 44.0);
      },
    );

    testWidgets(
      'Tapping profile avatar navigates to Settings and tapping logo navigates to Dashboard',
      (tester) async {
        String currentRoute = RouteNames.userManagementRoute;
        final router = GoRouter(
          initialLocation: RouteNames.userManagementRoute,
          routes: [
            GoRoute(
              path: RouteNames.dashboardRoute,
              builder: (context, state) {
                currentRoute = RouteNames.dashboardRoute;
                return const Scaffold(body: Text('Dashboard Target'));
              },
            ),
            GoRoute(
              path: RouteNames.userManagementRoute,
              builder: (context, state) => const Scaffold(
                body: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: UserManagementHeaderWidget(),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: RouteNames.settingsRoute,
              builder: (context, state) {
                currentRoute = RouteNames.settingsRoute;
                return const Scaffold(body: Text('Settings Target'));
              },
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('users_profile_button')));
        await tester.pumpAndSettle();
        expect(currentRoute, RouteNames.settingsRoute);
        expect(find.text('Settings Target'), findsOneWidget);

        // Return to users page and verify logo tap navigates to Dashboard
        router.go(RouteNames.userManagementRoute);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('app_bar_logo_button')));
        await tester.pumpAndSettle();
        expect(currentRoute, RouteNames.dashboardRoute);
        expect(find.text('Dashboard Target'), findsOneWidget);
      },
    );
  });
}
