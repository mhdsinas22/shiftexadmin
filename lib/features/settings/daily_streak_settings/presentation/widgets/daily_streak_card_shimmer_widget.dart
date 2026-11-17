import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/widgets/shimmer_box_widget.dart';

class DailyStreakCardShimmerWidget extends StatelessWidget {
  const DailyStreakCardShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShimmerScopeWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBoxWidget(width: 145, height: 12, borderRadius: 6),
          SizedBox(height: 8),
          ShimmerBoxWidget(height: 48, borderRadius: 14),
          SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ShimmerBoxWidget(width: 52, height: 12, borderRadius: 5),
              ShimmerBoxWidget(width: 54, height: 28, borderRadius: 20),
              ShimmerBoxWidget(width: 60, height: 28, borderRadius: 20),
              ShimmerBoxWidget(width: 60, height: 28, borderRadius: 20),
            ],
          ),
          SizedBox(height: 14),
          ShimmerBoxWidget(height: 38, borderRadius: 11),
          SizedBox(height: 8),
          ShimmerBoxWidget(height: 38, borderRadius: 11),
          SizedBox(height: 8),
          ShimmerBoxWidget(height: 38, borderRadius: 11),
          SizedBox(height: 14),
          ShimmerBoxWidget(height: 128, borderRadius: 14),
          SizedBox(height: 14),
          ShimmerBoxWidget(height: 46, borderRadius: 14),
        ],
      ),
    );
  }
}
