import 'package:go_router/go_router.dart';
import 'package:shiftexadmin/core/di/injection_container.dart';
import 'package:shiftexadmin/core/routes/route_names.dart';
import 'package:shiftexadmin/core/widgets/admin_main_shell.dart';
import 'package:shiftexadmin/features/ads/presentation/pages/ads_page.dart';
import 'package:shiftexadmin/features/authentication/presentation/pages/login_page.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/master_ledger_entry_entity.dart';
import 'package:shiftexadmin/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:shiftexadmin/features/dashboard/presentation/pages/master_ledger_page.dart';
import 'package:shiftexadmin/features/scan_pos/domain/entities/verified_pos_customer_entity.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/pages/scan_pos_page.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_permission.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/usecases/get_admin_access_overview_usecase.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/presentation/pages/daily_streak_audit_page.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/presentation/pages/points_to_cash_audit_page.dart';
import 'package:shiftexadmin/features/settings/presentation/pages/settings_page.dart';
import 'package:shiftexadmin/features/user_management/domain/entities/customer_entity.dart';
import 'package:shiftexadmin/features/user_management/presentation/pages/customer_details_page.dart';
import 'package:shiftexadmin/features/user_management/presentation/pages/user_management_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.loginRoute,

    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;

      final isLoggingIn = state.matchedLocation == RouteNames.loginRoute;

      if (session == null && !isLoggingIn) {
        return RouteNames.loginRoute;
      }

      if (session != null && isLoggingIn) {
        return RouteNames.dashboardRoute;
      }

      if (session != null &&
          getIt.isRegistered<GetAdminAccessOverviewUseCase>()) {
        final admin = getIt<GetAdminAccessOverviewUseCase>().cachedCurrentAdmin;
        if (admin != null) {
          if (!admin.isActive) {
            return RouteNames.loginRoute;
          }
          final loc = state.matchedLocation;
          if (loc.startsWith(RouteNames.adsRoute) &&
              !admin.hasPermission(AdminPermission.adsManage)) {
            return RouteNames.dashboardRoute;
          }
          if (loc.startsWith(RouteNames.scanPosRoute) &&
              !admin.hasPermission(AdminPermission.posView) &&
              !admin.hasPermission(AdminPermission.posGiveReward) &&
              !admin.hasPermission(AdminPermission.posVerifyClaim)) {
            return RouteNames.dashboardRoute;
          }
          if (loc.startsWith(RouteNames.userManagementRoute) &&
              !admin.hasPermission(AdminPermission.usersView)) {
            return RouteNames.dashboardRoute;
          }
        }
      }

      return null;
    },

    routes: [
      GoRoute(
        path: RouteNames.loginRoute,
        builder: (context, state) => const LoginPage(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AdminMainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.dashboardRoute,
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.userManagementRoute,
                builder: (context, state) {
                  final filter = state.uri.queryParameters['filter'];
                  final ts = state.uri.queryParameters['ts'];
                  return UserManagementPage(
                    initialFilter: filter,
                    navigationNonce: ts,
                  );
                },
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.adsRoute,
                builder: (context, state) => const AdsPage(),
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.settingsRoute,
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.scanPosRoute,
                builder: (context, state) {
                  final modeStr = state.uri.queryParameters['mode'];
                  final code = state.uri.queryParameters['code'];
                  final ts = state.uri.queryParameters['ts'];
                  ScanPosMode? initialMode;
                  if (modeStr == 'verify_claim') {
                    initialMode = ScanPosMode.verifyClaim;
                  } else if (modeStr == 'give_reward') {
                    initialMode = ScanPosMode.giveReward;
                  }
                  return ScanPosPage(
                    initialMode: initialMode,
                    initialQrCode: code,
                    navigationNonce: ts,
                  );
                },
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: RouteNames.masterLedgerRoute,
        builder: (context, state) {
          final categoryParam = state.uri.queryParameters['category'];
          return MasterLedgerPage(
            initialCategory: LedgerCategoryFilter.fromString(categoryParam),
          );
        },
      ),
      GoRoute(
        path: RouteNames.customerDetailsRoute,
        builder: (context, state) {
          final customer = state.extra as CustomerEntity?;

          if (customer == null) {
            return const UserManagementPage();
          }

          return CustomerDetailsPage(customer: customer);
        },
      ),
      GoRoute(
        path: RouteNames.dailyStreakAuditRoute,
        builder: (context, state) => const DailyStreakAuditPage(),
      ),
      GoRoute(
        path: RouteNames.pointsToCashAuditRoute,
        builder: (context, state) => const PointsToCashAuditPage(),
      ),
    ],
  );
}
