import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/core/widgets/shimmer_box_widget.dart';

class PointsToCashCardShimmerWidget extends StatelessWidget {
  const PointsToCashCardShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerScopeWidget(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x060F172A),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerBoxWidget(width: 40, height: 40, borderRadius: 12),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBoxWidget(width: 165, height: 15, borderRadius: 6),
                      SizedBox(height: 6),
                      ShimmerBoxWidget(width: 140, height: 11, borderRadius: 5),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 14),
            ShimmerBoxWidget(width: double.infinity, height: 68, borderRadius: 12),
            SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: ShimmerBoxWidget(height: 52, borderRadius: 10)),
                SizedBox(width: 8),
                Expanded(child: ShimmerBoxWidget(height: 52, borderRadius: 10)),
                SizedBox(width: 8),
                Expanded(child: ShimmerBoxWidget(height: 52, borderRadius: 10)),
              ],
            ),
            SizedBox(height: 14),
            ShimmerBoxWidget(width: double.infinity, height: 74, borderRadius: 12),
            SizedBox(height: 14),
            ShimmerBoxWidget(width: double.infinity, height: 46, borderRadius: 24),
          ],
        ),
      ),
    );
  }
}
