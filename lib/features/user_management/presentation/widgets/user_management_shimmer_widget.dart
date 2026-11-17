import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/widgets/shimmer_box_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/customer_directory_card_shimmer_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/pending_action_shimmer_card_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/top_earners_shimmer_card_widget.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/user_statistics_shimmer_grid_widget.dart';

class UserManagementShimmerWidget extends StatelessWidget {
  const UserManagementShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShimmerScopeWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Grid Skeleton (2x2)
          UserStatisticsShimmerGridWidget(),
          SizedBox(height: 16),

          // Search Bar Skeleton
          ShimmerBoxWidget(height: 48, borderRadius: 24),
          SizedBox(height: 12),

          // Filter Chips Skeleton
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: NeverScrollableScrollPhysics(),
            child: Row(
              children: [
                ShimmerBoxWidget(width: 88, height: 34, borderRadius: 20),
                SizedBox(width: 8),
                ShimmerBoxWidget(width: 102, height: 34, borderRadius: 20),
                SizedBox(width: 8),
                ShimmerBoxWidget(width: 84, height: 34, borderRadius: 20),
                SizedBox(width: 8),
                ShimmerBoxWidget(width: 92, height: 34, borderRadius: 20),
              ],
            ),
          ),
          SizedBox(height: 14),

          // Sort & Filter Row Skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBoxWidget(width: 155, height: 14, borderRadius: 6),
              ShimmerBoxWidget(width: 82, height: 14, borderRadius: 6),
            ],
          ),
          SizedBox(height: 16),

          // Pending Action Required Card Skeleton
          PendingActionShimmerCardWidget(),
          SizedBox(height: 20),

          // User Directory Header Skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBoxWidget(width: 132, height: 16, borderRadius: 6),
              ShimmerBoxWidget(width: 88, height: 12, borderRadius: 5),
            ],
          ),
          SizedBox(height: 12),

          // Directory Cards Skeleton
          CustomerDirectoryCardShimmerWidget(),
          CustomerDirectoryCardShimmerWidget(),
          CustomerDirectoryCardShimmerWidget(),
          SizedBox(height: 16),

          // Top Earners Card Skeleton
          TopEarnersShimmerCardWidget(),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}
