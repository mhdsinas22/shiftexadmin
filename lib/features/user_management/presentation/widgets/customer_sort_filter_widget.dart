import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';

class CustomerSortFilterWidget extends StatelessWidget {
  final String sortBy;
  final ValueChanged<String> onSortChanged;
  final VoidCallback? onFilterOptionsPressed;

  const CustomerSortFilterWidget({
    super.key,
    required this.sortBy,
    required this.onSortChanged,
    this.onFilterOptionsPressed,
  });

  String get _sortLabel {
    switch (sortBy) {
      case 'oldest':
        return 'Oldest Registration';
      case 'name':
        return 'Name (A-Z)';
      case 'newest':
      default:
        return 'Newest Registration';
    }
  }

  void _showSortMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Sort Customers',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Newest Registration'),
                  leading: const Icon(Icons.arrow_downward_rounded, size: 20),
                  trailing: sortBy == 'newest'
                      ? const Icon(Icons.check, color: AppColors.darkNavy)
                      : null,
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    onSortChanged('newest');
                  },
                ),
                ListTile(
                  title: const Text('Oldest Registration'),
                  leading: const Icon(Icons.arrow_upward_rounded, size: 20),
                  trailing: sortBy == 'oldest'
                      ? const Icon(Icons.check, color: AppColors.darkNavy)
                      : null,
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    onSortChanged('oldest');
                  },
                ),
                ListTile(
                  title: const Text('Name (A-Z)'),
                  leading: const Icon(Icons.sort_by_alpha_rounded, size: 20),
                  trailing: sortBy == 'name'
                      ? const Icon(Icons.check, color: AppColors.darkNavy)
                      : null,
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    onSortChanged('name');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => _showSortMenu(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.sort_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    const TextSpan(text: 'Sort: '),
                    TextSpan(
                      text: _sortLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onFilterOptionsPressed ?? () => _showSortMenu(context),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 14,
                color: AppColors.linkBlue,
              ),
              SizedBox(width: 4),
              Text(
                'Reward Filter',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.linkBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
