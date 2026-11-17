import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';

class AdsKpiCardWidget extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const AdsKpiCardWidget({
    super.key,
    required this.label,
    required this.value,
    this.color = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
