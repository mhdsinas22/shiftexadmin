import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/core/widgets/shimmer_box_widget.dart';

class UserStatisticsShimmerCardWidget extends StatelessWidget {
  const UserStatisticsShimmerCardWidget({super.key});

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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBoxWidget(width: 78, height: 12, borderRadius: 6),
              ShimmerBoxWidget(
                width: 22,
                height: 22,
                shape: BoxShape.circle,
              ),
            ],
          ),
          SizedBox(height: 12),
          ShimmerBoxWidget(width: 68, height: 22, borderRadius: 6),
          SizedBox(height: 8),
          ShimmerBoxWidget(width: 96, height: 10, borderRadius: 5),
        ],
      ),
    );
  }
}

class UserStatisticsShimmerGridWidget extends StatelessWidget {
  const UserStatisticsShimmerGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(child: UserStatisticsShimmerCardWidget()),
            SizedBox(width: 12),
            Expanded(child: UserStatisticsShimmerCardWidget()),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: UserStatisticsShimmerCardWidget()),
            SizedBox(width: 12),
            Expanded(child: UserStatisticsShimmerCardWidget()),
          ],
        ),
      ],
    );
  }
}
