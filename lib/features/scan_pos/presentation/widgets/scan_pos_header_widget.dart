import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/core/widgets/admin_top_app_bar_widget.dart';
import 'package:shiftexadmin/features/scan_pos/domain/entities/verified_pos_customer_entity.dart';

class ScanPosHeaderWidget extends StatelessWidget {
  final ScanPosMode selectedMode;
  final ValueChanged<ScanPosMode> onModeChanged;
  final bool hasUnreadNotifications;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onProfilePressed;

  const ScanPosHeaderWidget({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
    this.hasUnreadNotifications = false,
    this.onNotificationPressed,
    this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Branding Bar consistent with Dashboard AppBar
        AdminTopAppBarWidget(
          hasUnreadNotifications: hasUnreadNotifications,
          notificationButtonKey: const Key('scan_pos_notification_button'),
          profileButtonKey: const Key('scan_pos_profile_button'),
          onNotificationPressed: onNotificationPressed,
          onProfilePressed: onProfilePressed,
        ),
        const SizedBox(height: 18),

        // Mode Switcher Pill: Give Reward / Verify Claim
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x050F172A),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onModeChanged(ScanPosMode.giveReward),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selectedMode == ScanPosMode.giveReward
                          ? const Color(0xFF0F172A)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          size: 16,
                          color: selectedMode == ScanPosMode.giveReward
                              ? AppColors.pureWhite
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Give Reward',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: selectedMode == ScanPosMode.giveReward
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: selectedMode == ScanPosMode.giveReward
                                  ? AppColors.pureWhite
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onModeChanged(ScanPosMode.verifyClaim),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selectedMode == ScanPosMode.verifyClaim
                          ? const Color(0xFF0F172A)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 16,
                          color: selectedMode == ScanPosMode.verifyClaim
                              ? AppColors.pureWhite
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Verify Claim',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight:
                                  selectedMode == ScanPosMode.verifyClaim
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                              color: selectedMode == ScanPosMode.verifyClaim
                                  ? AppColors.pureWhite
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
