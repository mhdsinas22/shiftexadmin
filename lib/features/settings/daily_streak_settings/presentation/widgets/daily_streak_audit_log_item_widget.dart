import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/entities/daily_streak_audit_log_entity.dart';

class DailyStreakAuditLogItemWidget extends StatelessWidget {
  final DailyStreakAuditLogEntity log;

  const DailyStreakAuditLogItemWidget({
    super.key,
    required this.log,
  });

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = local.hour > 12
        ? local.hour - 12
        : (local.hour == 0 ? 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${months[local.month - 1]} ${local.day}, ${local.year} • $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: log.newEnabled
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  log.newEnabled ? 'Streak Enabled' : 'Streak Disabled',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: log.newEnabled
                        ? const Color(0xFF15803D)
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                _formatDateTime(log.createdAt),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                size: 16,
                color: AppColors.purple,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  log.previousPoints != null
                      ? 'Points updated: ${log.previousPoints} pts → ${log.newPoints} pts / login'
                      : 'Points configured: ${log.newPoints} pts / login',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (log.previousEnabled != null &&
              log.previousEnabled != log.newEnabled) ...[
            const SizedBox(height: 4),
            Text(
              'Status changed: ${log.previousEnabled! ? 'Enabled' : 'Disabled'} → ${log.newEnabled ? 'Enabled' : 'Disabled'}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.admin_panel_settings_outlined,
                size: 14,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'By ${log.changedByEmail}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
