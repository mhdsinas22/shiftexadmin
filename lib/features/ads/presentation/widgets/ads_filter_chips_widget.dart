import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/features/ads/domain/entities/advertisement_statistics_entity.dart';

class AdsFilterChipsWidget extends StatelessWidget {
  final String selectedFilter;
  final AdvertisementStatisticsEntity statistics;
  final ValueChanged<String> onFilterChanged;

  const AdsFilterChipsWidget({
    super.key,
    required this.selectedFilter,
    required this.statistics,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      {'key': 'all', 'label': 'All (${statistics.totalAds})'},
      {'key': 'active', 'label': 'Active (${statistics.activeCount})'},
      {'key': 'scheduled', 'label': 'Scheduled (${statistics.scheduledCount})'},
      {'key': 'draft', 'label': 'Draft (${statistics.draftCount})'},
      {'key': 'ended', 'label': 'Ended (${statistics.endedCount})'},
      {'key': 'deactivated', 'label': 'Deactivated (${statistics.deactivatedCount})'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          final isSelected = selectedFilter.toLowerCase() == f['key']!.toLowerCase();
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => onFilterChanged(f['key']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.darkNavy : AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.darkNavy
                        : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Color(0x1A0F172A),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: AppColors.pureWhite,
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      f['label']!,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.pureWhite
                            : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
