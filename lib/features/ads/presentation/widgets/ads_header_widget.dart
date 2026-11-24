import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/core/constants/app_texts.dart';
import 'package:shiftexadmin/core/widgets/admin_top_app_bar_widget.dart';

class AdsHeaderWidget extends StatelessWidget {
  final bool hasUnreadNotifications;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onProfilePressed;
  final VoidCallback? onNewAdPressed;

  const AdsHeaderWidget({
    super.key,
    this.hasUnreadNotifications = false,
    this.onNotificationPressed,
    this.onProfilePressed,
    this.onNewAdPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top branding bar consistent with Dashboard AppBar
        AdminTopAppBarWidget(
          hasUnreadNotifications: hasUnreadNotifications,
          notificationButtonKey: const Key('ads_notification_button'),
          profileButtonKey: const Key('ads_profile_button'),
          onNotificationPressed: onNotificationPressed,
          onProfilePressed: onProfilePressed,
        ),
        const SizedBox(height: 18),

        // Title and + New Ad Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTexts.bold(
                    'Advertisements',
                    fontSize: 22,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(height: 4),
                  AppTexts.medium(
                    'In-App Popups & Promotional Campaigns',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: onNewAdPressed ?? () {},
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
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'New Ad',
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
