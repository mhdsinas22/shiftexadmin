import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/widgets/shimmer_box_widget.dart';

class DashboardShimmerWidget extends StatelessWidget {
  const DashboardShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShimmerScopeWidget(
      child: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBoxWidget(
                  width: 44,
                  height: 44,
                  shape: BoxShape.circle,
                ),
                Row(
                  children: [
                    ShimmerBoxWidget(
                      width: 40,
                      height: 40,
                      shape: BoxShape.circle,
                    ),
                    SizedBox(width: 10),
                    ShimmerBoxWidget(
                      width: 40,
                      height: 40,
                      shape: BoxShape.circle,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 18),
            ShimmerBoxWidget(width: 220, height: 26, borderRadius: 8),
            SizedBox(height: 6),
            ShimmerBoxWidget(width: 180, height: 14, borderRadius: 6),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: ShimmerBoxWidget(height: 124, borderRadius: 22)),
                SizedBox(width: 12),
                Expanded(child: ShimmerBoxWidget(height: 124, borderRadius: 22)),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: ShimmerBoxWidget(height: 118, borderRadius: 22)),
                SizedBox(width: 12),
                Expanded(child: ShimmerBoxWidget(height: 118, borderRadius: 22)),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: ShimmerBoxWidget(height: 118, borderRadius: 22)),
                SizedBox(width: 12),
                Expanded(child: ShimmerBoxWidget(height: 118, borderRadius: 22)),
              ],
            ),
            SizedBox(height: 24),
            ShimmerBoxWidget(width: 150, height: 18, borderRadius: 6),
            SizedBox(height: 12),
            ShimmerBoxWidget(height: 130, borderRadius: 20),
            SizedBox(height: 24),
            ShimmerBoxWidget(width: 140, height: 18, borderRadius: 6),
            SizedBox(height: 12),
            ShimmerBoxWidget(height: 165, borderRadius: 22),
            SizedBox(height: 24),
            ShimmerBoxWidget(width: 130, height: 18, borderRadius: 6),
            SizedBox(height: 12),
            ShimmerBoxWidget(height: 210, borderRadius: 22),
          ],
        ),
      ),
    );
  }
}
