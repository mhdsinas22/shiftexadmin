import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/core/constants/app_texts.dart';
import 'package:shiftexadmin/features/authentication/presentation/widgets/login_logo_widget.dart';

class SettingsHeaderWidget extends StatelessWidget {
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onProfilePressed;

  const SettingsHeaderWidget({
    super.key,
    this.onNotificationPressed,
    this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const LoginLogoWidget(size: 38, iconSize: 20),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF1F5F9),
                      width: 1.2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x080F172A),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      size: 20,
                      color: AppColors.darkNavy,
                    ),
                    onPressed: onNotificationPressed ?? () {},
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onProfilePressed ?? () {},
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF475569),
                      border: Border.all(
                        color: AppColors.pureWhite,
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0C0F172A),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'AD',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.pureWhite,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
