import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/entities/points_to_cash_audit_log_entity.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/entities/points_to_cash_config_entity.dart';

class PointsToCashAuditLogItemWidget extends StatelessWidget {
  final PointsToCashAuditLogEntity log;

  const PointsToCashAuditLogItemWidget({super.key, required this.log});

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
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
    final isInitialBaseline = log.previousPointsPerRupee == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isInitialBaseline
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isInitialBaseline
                          ? Icons.flag_outlined
                          : Icons.tune_rounded,
                      size: 11,
                      color: isInitialBaseline
                          ? AppColors.textSecondary
                          : AppColors.linkBlue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isInitialBaseline
                          ? 'v${log.versionNumber} • Baseline'
                          : 'v${log.versionNumber} • Rate Update',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isInitialBaseline
                            ? AppColors.textSecondary
                            : AppColors.linkBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatDateTime(log.createdAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.currency_exchange_rounded,
                size: 16,
                color: AppColors.goldenYellow,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  log.previousPointsPerRupee != null
                      ? 'Rate updated: ${log.previousPointsPerRupee} pts = ₹1 → ${log.newPointsPerRupee} pts = ₹1.00'
                      : 'Active baseline rate: ${log.newPointsPerRupee} pts = ₹1.00',
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
          const SizedBox(height: 4),
          Text(
            'Liability: ₹${PointsToCashConfigEntity.formatLiabilityPerPointFor(log.newPointsPerRupee)} / pt'
            '${log.previousPointsPerRupee != null ? ' (was ₹${PointsToCashConfigEntity.formatLiabilityPerPointFor(log.previousPointsPerRupee!)} / pt)' : ''}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          if (log.note != null && log.note!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                log.note!,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.admin_panel_settings_outlined,
                size: 13,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Changed by ${log.changedByEmail ?? 'System Seed'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textHint,
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
