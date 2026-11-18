import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';

class RateMatrixCellWidget extends StatelessWidget {
  final String pointsLabel;
  final String cashLabel;

  const RateMatrixCellWidget({
    super.key,
    required this.pointsLabel,
    required this.cashLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Text(
            pointsLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            cashLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
