import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/features/user_management/domain/entities/user_statistics_entity.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/user_statistics_card_widget.dart';

class UserStatisticsGridWidget extends StatelessWidget {
  final UserStatisticsEntity statistics;

  const UserStatisticsGridWidget({
    super.key,
    required this.statistics,
  });

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: UserStatisticsCardWidget(
                title: 'Registered',
                value: _formatNumber(statistics.registeredCount),
                subtitle: 'All-time database',
                trailingWidget: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.groups_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: UserStatisticsCardWidget(
                title: 'Pending Action',
                value: '${_formatNumber(statistics.pendingCount)} Users',
                subtitle: 'Waiting admin check',
                valueColor: const Color(0xFFB45309),
                trailingWidget: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD97706),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: UserStatisticsCardWidget(
                title: 'Active Status',
                value: _formatNumber(statistics.activeCount),
                subtitle: 'Verified / Active',
                trailingWidget: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.eifGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: UserStatisticsCardWidget(
                title: 'Restricted',
                value: '${_formatNumber(statistics.restrictedCount)} Users',
                subtitle: 'Fraud flag/POS hold',
                valueColor: AppColors.purered,
                trailingWidget: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    size: 12,
                    color: AppColors.purered,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
