import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/core/widgets/shimmer_box_widget.dart';

class PendingActionShimmerCardWidget extends StatelessWidget {
  const PendingActionShimmerCardWidget({super.key});

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
            color: Color(0x080F172A),
            blurRadius: 12,
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
              ShimmerBoxWidget(width: 105, height: 11, borderRadius: 5),
              ShimmerBoxWidget(width: 82, height: 11, borderRadius: 5),
            ],
          ),
          SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShimmerBoxWidget(
                          width: 125,
                          height: 15,
                          borderRadius: 6,
                        ),
                        ShimmerBoxWidget(
                          width: 66,
                          height: 11,
                          borderRadius: 5,
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    ShimmerBoxWidget(width: 110, height: 11, borderRadius: 5),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        ShimmerBoxWidget(
                          width: 68,
                          height: 16,
                          borderRadius: 4,
                        ),
                        SizedBox(width: 6),
                        ShimmerBoxWidget(
                          width: 105,
                          height: 11,
                          borderRadius: 5,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ShimmerBoxWidget(height: 40, borderRadius: 12),
              ),
              SizedBox(width: 10),
              Expanded(
                child: ShimmerBoxWidget(height: 40, borderRadius: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
