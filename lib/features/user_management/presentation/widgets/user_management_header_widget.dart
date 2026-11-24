import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/core/constants/app_texts.dart';
import 'package:shiftexadmin/core/widgets/admin_top_app_bar_widget.dart';

class UserManagementHeaderWidget extends StatelessWidget {
  final bool hasUnreadNotifications;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onProfilePressed;
  final VoidCallback? onAddUserPressed;

  const UserManagementHeaderWidget({
    super.key,
    this.hasUnreadNotifications = false,
    this.onNotificationPressed,
    this.onProfilePressed,
    this.onAddUserPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top branding bar consistent with Dashboard AppBar
        AdminTopAppBarWidget(
          hasUnreadNotifications: hasUnreadNotifications,
          notificationButtonKey: const Key('users_notification_button'),
          profileButtonKey: const Key('users_profile_button'),
          onNotificationPressed: onNotificationPressed,
          onProfilePressed: onProfilePressed,
        ),
        const SizedBox(height: 18),

        // Title and + Add User Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTexts.bold(
                    'User Management',
                    fontSize: 22,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(height: 4),
                  AppTexts.medium(
                    'Access Control & Member Directory',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: onAddUserPressed ?? () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkNavy,
                foregroundColor: AppColors.pureWhite,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.person_add_outlined, size: 16),
              label: const Text(
                'Add User',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
