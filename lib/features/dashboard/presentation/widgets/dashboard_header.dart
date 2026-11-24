import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/core/widgets/admin_top_app_bar_widget.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/admin_identity_entity.dart';

class DashboardHeader extends StatelessWidget {
  final AdminIdentityEntity adminProfile;
  final bool hasUnreadNotifications;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onProfilePressed;

  const DashboardHeader({
    super.key,
    required this.adminProfile,
    this.hasUnreadNotifications = false,
    this.onNotificationPressed,
    this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminTopAppBarWidget(
          profileInitials: adminProfile.initials,
          hasUnreadNotifications: hasUnreadNotifications,
          notificationButtonKey: const Key('dashboard_notification_button'),
          profileButtonKey: const Key('dashboard_profile_button'),
          onLogoPressed: () {},
          onNotificationPressed: onNotificationPressed,
          onProfilePressed: onProfilePressed,
        ),
        const SizedBox(height: 18),
        Text(
          '${adminProfile.greetingWithName()} 👋',
          key: const Key('dashboard_greeting_text'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 23,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          adminProfile.subtitleText,
          key: const Key('dashboard_admin_subtitle_text'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
