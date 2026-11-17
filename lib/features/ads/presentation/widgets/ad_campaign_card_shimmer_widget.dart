import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/core/widgets/shimmer_box_widget.dart';

class AdCampaignCardShimmerWidget extends StatelessWidget {
  const AdCampaignCardShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
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
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Status Badge Pill
          ShimmerBoxWidget(width: 120, height: 22, borderRadius: 20),
          SizedBox(height: 12),

          // Thumbnail + Content Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBoxWidget(width: 60, height: 60, borderRadius: 14),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBoxWidget(width: 175, height: 15, borderRadius: 6),
                    SizedBox(height: 6),
                    ShimmerBoxWidget(height: 11, borderRadius: 5),
                    SizedBox(height: 4),
                    ShimmerBoxWidget(width: 140, height: 11, borderRadius: 5),
                    SizedBox(height: 8),
                    ShimmerBoxWidget(width: 165, height: 11, borderRadius: 5),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14),

          // Duration & Views Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBoxWidget(width: 132, height: 12, borderRadius: 5),
              ShimmerBoxWidget(width: 70, height: 12, borderRadius: 5),
            ],
          ),
          SizedBox(height: 8),

          // Progress Bar Placeholder
          ShimmerBoxWidget(height: 5, borderRadius: 4),
          SizedBox(height: 8),

          // Conversion Performance Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBoxWidget(width: 130, height: 12, borderRadius: 5),
              ShimmerBoxWidget(width: 122, height: 12, borderRadius: 5),
            ],
          ),
          SizedBox(height: 14),

          // Action Buttons Row
          Row(
            children: [
              Expanded(
                flex: 4,
                child: ShimmerBoxWidget(height: 38, borderRadius: 12),
              ),
              SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ShimmerBoxWidget(height: 38, borderRadius: 12),
              ),
              SizedBox(width: 8),
              ShimmerBoxWidget(width: 42, height: 38, borderRadius: 12),
            ],
          ),
        ],
      ),
    );
  }
}

class AdCampaignShimmerListWidget extends StatelessWidget {
  final int itemCount;

  const AdCampaignShimmerListWidget({
    super.key,
    this.itemCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerScopeWidget(
      child: Column(
        children: List.generate(
          itemCount,
          (_) => const AdCampaignCardShimmerWidget(),
        ),
      ),
    );
  }
}
