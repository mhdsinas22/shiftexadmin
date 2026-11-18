import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/core/constants/app_texts.dart';

class UserStatisticsCardWidget extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Widget? trailingWidget;
  final Color valueColor;

  const UserStatisticsCardWidget({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    this.trailingWidget,
    this.valueColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppTexts.medium(
                title,
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              ?trailingWidget,
            ],
          ),
          const SizedBox(height: 10),
          AppTexts.bold(
            value,
            fontSize: 20,
            color: valueColor,
          ),
          const SizedBox(height: 4),
          AppTexts.regular(
            subtitle,
            fontSize: 11,
            color: AppColors.textHint,
          ),
        ],
      ),
    );
  }
}
