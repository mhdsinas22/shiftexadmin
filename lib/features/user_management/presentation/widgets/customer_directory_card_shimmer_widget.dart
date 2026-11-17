import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/core/widgets/shimmer_box_widget.dart';

class CustomerDirectoryCardShimmerWidget extends StatelessWidget {
  const CustomerDirectoryCardShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Customer Row
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    Row(
                      children: [
                        ShimmerBoxWidget(
                          width: 118,
                          height: 14,
                          borderRadius: 6,
                        ),
                        SizedBox(width: 8),
                        ShimmerBoxWidget(
                          width: 62,
                          height: 18,
                          borderRadius: 10,
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    ShimmerBoxWidget(width: 170, height: 11, borderRadius: 5),
                  ],
                ),
              ),
              SizedBox(width: 8),
              ShimmerBoxWidget(width: 18, height: 18, borderRadius: 6),
            ],
          ),
          const SizedBox(height: 12),

          // Sub-card (Wallet / Points placeholder)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFF1F5F9),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBoxWidget(width: 74, height: 10, borderRadius: 5),
                      SizedBox(height: 6),
                      ShimmerBoxWidget(width: 62, height: 14, borderRadius: 6),
                      SizedBox(height: 5),
                      ShimmerBoxWidget(width: 84, height: 10, borderRadius: 5),
                    ],
                  ),
                ),
                Container(
                  height: 36,
                  width: 1,
                  color: const Color(0xFFE2E8F0),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBoxWidget(width: 72, height: 10, borderRadius: 5),
                      SizedBox(height: 6),
                      ShimmerBoxWidget(width: 56, height: 14, borderRadius: 6),
                      SizedBox(height: 5),
                      ShimmerBoxWidget(width: 92, height: 10, borderRadius: 5),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Footer Row
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBoxWidget(width: 120, height: 11, borderRadius: 5),
              ShimmerBoxWidget(width: 88, height: 12, borderRadius: 6),
            ],
          ),
        ],
      ),
    );
  }
}

class CustomerDirectoryShimmerListWidget extends StatelessWidget {
  final int itemCount;

  const CustomerDirectoryShimmerListWidget({
    super.key,
    this.itemCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerScopeWidget(
      child: Column(
        children: List.generate(
          itemCount,
          (_) => const CustomerDirectoryCardShimmerWidget(),
        ),
      ),
    );
  }
}
