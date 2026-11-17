import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';

class DailyStreakPresetsRowWidget extends StatelessWidget {
  final int? selectedPoints;
  final ValueChanged<int> onPresetSelected;

  const DailyStreakPresetsRowWidget({
    super.key,
    required this.selectedPoints,
    required this.onPresetSelected,
  });

  static const List<int> presets = [5, 10, 15, 25];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Presets:',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textHint,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: presets.map((pts) {
              final isSelected = selectedPoints == pts;
              return GestureDetector(
                onTap: () => onPresetSelected(pts),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppColors.darkNavy : AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.darkNavy
                          : const Color(0xFFE2E8F0),
                      width: 1.1,
                    ),
                  ),
                  child: Text(
                    '+$pts pts',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? AppColors.pureWhite
                          : const Color(0xFF475569),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
