import 'package:go_router/go_router.dart';
import 'package:shiftexadmin/core/routes/route_names.dart';
import 'package:shiftexadmin/core/widgets/admin_main_shell.dart';
import 'package:shiftexadmin/features/ads/presentation/pages/ads_page.dart';
import 'package:shiftexadmin/features/authentication/presentation/pages/login_page.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/presentation/pages/daily_streak_audit_page.dart';
import 'package:shiftexadmin/features/dashboard/presentation/pages/dashboard_page.dart';
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
                builder: (context, state) => const UserManagementPage(),
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
        ],
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
    ],
  );
}
