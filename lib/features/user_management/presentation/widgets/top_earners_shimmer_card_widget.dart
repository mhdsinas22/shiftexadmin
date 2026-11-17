import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/core/widgets/shimmer_box_widget.dart';

class TopEarnersShimmerRowWidget extends StatelessWidget {
  const TopEarnersShimmerRowWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          ShimmerBoxWidget(width: 28, height: 28, shape: BoxShape.circle),
          SizedBox(width: 8),
          ShimmerBoxWidget(width: 32, height: 32, shape: BoxShape.circle),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBoxWidget(width: 105, height: 13, borderRadius: 6),
                SizedBox(height: 4),
                ShimmerBoxWidget(width: 72, height: 10, borderRadius: 5),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ShimmerBoxWidget(width: 58, height: 13, borderRadius: 6),
              SizedBox(height: 4),
              ShimmerBoxWidget(width: 44, height: 10, borderRadius: 5),
            ],
          ),
        ],
      ),
    );
  }
}

class TopEarnersShimmerCardWidget extends StatelessWidget {
  const TopEarnersShimmerCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
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
      child: const Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ShimmerBoxWidget(width: 30, height: 30, borderRadius: 8),
                  SizedBox(width: 8),
                  ShimmerBoxWidget(width: 96, height: 16, borderRadius: 6),
                ],
              ),
              ShimmerBoxWidget(width: 138, height: 26, borderRadius: 16),
            ],
          ),
          SizedBox(height: 14),
          TopEarnersShimmerRowWidget(),
          TopEarnersShimmerRowWidget(),
          TopEarnersShimmerRowWidget(),
        ],
      ),
    );
  }
}
