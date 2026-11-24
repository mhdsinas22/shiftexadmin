import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/core/constants/app_texts.dart';
import 'package:shiftexadmin/core/widgets/admin_top_app_bar_widget.dart';

class SettingsHeaderWidget extends StatelessWidget {
  final String? profileInitials;
  final bool hasUnreadNotifications;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onProfilePressed;

  const SettingsHeaderWidget({
    super.key,
    this.profileInitials,
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
          profileInitials: profileInitials,
          hasUnreadNotifications: hasUnreadNotifications,
          notificationButtonKey: const Key('settings_notification_button'),
          profileButtonKey: const Key('settings_profile_button'),
          onNotificationPressed: onNotificationPressed,
          onProfilePressed: onProfilePressed,
        ),
        const SizedBox(height: 18),
        AppTexts.bold(
          'Settings & Rules Engine',
          fontSize: 22,
          color: AppColors.textPrimary,
        ),
        const SizedBox(height: 4),
        AppTexts.medium(
          'Global platform parameters, ledger yields & terminal security',
          fontSize: 12.5,
          color: AppColors.textSecondary,
        ),
      ],
    );
  }
}
