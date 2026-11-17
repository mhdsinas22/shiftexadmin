import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/core/constants/app_texts.dart';
import 'package:shiftexadmin/core/routes/route_names.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Future<void> onSignOutPressed(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    if (context.mounted) {
      context.go(RouteNames.loginRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,

      appBar: AppBar(
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        title: AppTexts.bold(
          'ShiftEx Dashboard',
          fontSize: 18,
          color: AppColors.textPrimary,
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: AppColors.textSecondary,
            ),
            tooltip: 'Sign Out',
            onPressed: () => onSignOutPressed(context),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.borderLight),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.lightGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 48,
                  color: AppColors.eifGreen,
                ),
              ),
              const SizedBox(height: 20),
              AppTexts.bold(
                'Welcome, Admin!',
                fontSize: 22,
                color: AppColors.textPrimary,
              ),
              const SizedBox(height: 8),
              AppTexts.medium(
                user?.email ?? 'Admin User',
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkNavy,
                  foregroundColor: AppColors.pureWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
                icon: const Icon(Icons.people_outline_rounded, size: 20),
                label: const Text(
                  'Open User Management',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () => context.go(RouteNames.userManagementRoute),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: AppColors.purered),
                icon: const Icon(Icons.logout_rounded, size: 16),
                label: const Text('Log Out'),
                onPressed: () => onSignOutPressed(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
