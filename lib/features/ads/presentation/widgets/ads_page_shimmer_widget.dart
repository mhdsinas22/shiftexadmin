import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/core/widgets/shimmer_box_widget.dart';
import 'package:shiftexadmin/features/ads/presentation/widgets/ad_campaign_card_shimmer_widget.dart';
import 'package:shiftexadmin/features/ads/presentation/widgets/ads_statistics_shimmer_grid_widget.dart';

class AdsPageShimmerWidget extends StatelessWidget {
  const AdsPageShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerScopeWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Grid Skeleton (2x2)
          const AdsStatisticsShimmerGridWidget(),
          const SizedBox(height: 16),

          // Filter Chips Skeleton
          const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: NeverScrollableScrollPhysics(),
            child: Row(
              children: [
                ShimmerBoxWidget(width: 84, height: 34, borderRadius: 24),
                SizedBox(width: 8),
                ShimmerBoxWidget(width: 88, height: 34, borderRadius: 24),
                SizedBox(width: 8),
                ShimmerBoxWidget(width: 106, height: 34, borderRadius: 24),
                SizedBox(width: 8),
                ShimmerBoxWidget(width: 82, height: 34, borderRadius: 24),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick Create Popup Collapsed Card Skeleton
          Container(
            padding: const EdgeInsets.all(14),
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
            child: const Row(
              children: [
                ShimmerBoxWidget(width: 36, height: 36, borderRadius: 12),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBoxWidget(
                        width: 138,
                        height: 14,
                        borderRadius: 6,
                      ),
                      SizedBox(height: 5),
                      ShimmerBoxWidget(
                        width: 185,
                        height: 11,
                        borderRadius: 5,
                      ),
                    ],
                  ),
                ),
                ShimmerBoxWidget(
                  width: 28,
                  height: 28,
                  shape: BoxShape.circle,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Campaign Library Heading Skeleton
          const ShimmerBoxWidget(width: 148, height: 18, borderRadius: 6),
          const SizedBox(height: 12),

          // Campaign Cards Skeleton
          const AdCampaignCardShimmerWidget(),
          const AdCampaignCardShimmerWidget(),
          const AdCampaignCardShimmerWidget(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
