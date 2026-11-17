import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';

class CustomerFilterChipsWidget extends StatelessWidget {
  final String selectedFilter;
  final int pendingCount;
  final ValueChanged<String> onFilterSelected;

  const CustomerFilterChipsWidget({
    super.key,
    required this.selectedFilter,
    required this.pendingCount,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildFilterChip(
            id: 'all',
            label: 'All Users',
            icon: Icons.check_rounded,
            isSelected: selectedFilter == 'all',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            id: 'pending',
            label: 'Pending ($pendingCount)',
            dotColor: const Color(0xFFD97706),
            isSelected: selectedFilter == 'pending',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            id: 'approved',
            label: 'Verified',
            dotColor: AppColors.eifGreen,
            isSelected: selectedFilter == 'approved' || selectedFilter == 'verified',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            id: 'restricted',
            label: 'Restricted',
            dotColor: AppColors.purered,
            isSelected: selectedFilter == 'restricted',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String id,
    required String label,
    Color? dotColor,
    IconData? icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onFilterSelected(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkNavy : AppColors.pureWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.darkNavy : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x140F172A),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x040F172A),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null && isSelected) ...[
              Icon(
                icon,
                size: 14,
                color: AppColors.pureWhite,
              ),
              const SizedBox(width: 6),
            ] else if (dotColor != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.pureWhite : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
