import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/core/widgets/shimmer_box_widget.dart';

class AdsStatisticsShimmerCardWidget extends StatelessWidget {
  const AdsStatisticsShimmerCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ShimmerBoxWidget(width: 72, height: 12, borderRadius: 6),
              ShimmerBoxWidget(width: 32, height: 32, borderRadius: 10),
            ],
          ),
          SizedBox(height: 8),
          ShimmerBoxWidget(width: 44, height: 26, borderRadius: 6),
          SizedBox(height: 6),
          ShimmerBoxWidget(width: 64, height: 11, borderRadius: 5),
        ],
      ),
    );
  }
}

class AdsStatisticsShimmerGridWidget extends StatelessWidget {
  const AdsStatisticsShimmerGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(child: AdsStatisticsShimmerCardWidget()),
            SizedBox(width: 12),
            Expanded(child: AdsStatisticsShimmerCardWidget()),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: AdsStatisticsShimmerCardWidget()),
            SizedBox(width: 12),
            Expanded(child: AdsStatisticsShimmerCardWidget()),
          ],
        ),
      ],
    );
  }
}
