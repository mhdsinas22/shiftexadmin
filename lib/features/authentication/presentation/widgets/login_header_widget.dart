import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/core/constants/app_texts.dart';

class LoginHeaderWidget extends StatelessWidget {
  final String title;
  final String subtitle;

  const LoginHeaderWidget({
    super.key,
    this.title = 'ShiftEx Admin',
    this.subtitle = 'Admin Login',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppTexts.bold(
          title,
          fontSize: 28,
          color: AppColors.textPrimary,
          align: TextAlign.center,
          letterSpacing: -0.5,
        ),
        const SizedBox(height: 8),
        AppTexts.medium(
          subtitle,
          fontSize: 16,
          color: AppColors.textSecondary,
          align: TextAlign.center,
        ),
      ],
    );
  }
}
