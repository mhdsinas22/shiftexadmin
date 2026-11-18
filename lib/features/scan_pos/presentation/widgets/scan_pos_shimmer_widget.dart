import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/core/widgets/shimmer_box_widget.dart';

class ScanPosCustomerShimmerWidget extends StatelessWidget {
  const ScanPosCustomerShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerScopeWidget(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
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
                ShimmerBoxWidget(
                  width: 44,
                  height: 44,
                  shape: BoxShape.circle,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBoxWidget(width: 140, height: 15, borderRadius: 6),
                      SizedBox(height: 6),
                      ShimmerBoxWidget(width: 190, height: 11, borderRadius: 5),
                    ],
                  ),
                ),
                ShimmerBoxWidget(width: 28, height: 28, shape: BoxShape.circle),
              ],
            ),
            SizedBox(height: 14),
            ShimmerBoxWidget(width: double.infinity, height: 68, borderRadius: 14),
            SizedBox(height: 16),
            ShimmerBoxWidget(width: 130, height: 14, borderRadius: 6),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ShimmerBoxWidget(height: 82, borderRadius: 14),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ShimmerBoxWidget(height: 82, borderRadius: 14),
                ),
              ],
            ),
            SizedBox(height: 12),
            ShimmerBoxWidget(width: double.infinity, height: 92, borderRadius: 14),
            SizedBox(height: 14),
            ShimmerBoxWidget(width: double.infinity, height: 48, borderRadius: 14),
          ],
        ),
      ),
    );
  }
}

class ScanPosHistoryShimmerWidget extends StatelessWidget {
  const ScanPosHistoryShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerScopeWidget(
      child: Column(
        children: List.generate(
          3,
          (index) => Container(
            margin: EdgeInsets.only(bottom: index == 2 ? 0 : 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: const Row(
              children: [
                ShimmerBoxWidget(width: 40, height: 40, shape: BoxShape.circle),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBoxWidget(width: 150, height: 13, borderRadius: 5),
                      SizedBox(height: 6),
                      ShimmerBoxWidget(width: 170, height: 10, borderRadius: 4),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ShimmerBoxWidget(width: 58, height: 12, borderRadius: 5),
                    SizedBox(height: 6),
                    ShimmerBoxWidget(width: 42, height: 10, borderRadius: 4),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
