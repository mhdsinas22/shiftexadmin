import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/master_ledger_entry_entity.dart';

class MasterLedgerTileWidget extends StatelessWidget {
  final MasterLedgerEntryEntity entry;

  const MasterLedgerTileWidget({super.key, required this.entry});

  static String formatLedgerTimestamp(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(dt.year, dt.month, dt.day);
    final diffDays = today.difference(targetDay).inDays;

    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final timePart = '${hour12.toString().padLeft(2, '0')}:$minute $period';

    if (diffDays == 0) {
      return 'Today $timePart';
    } else if (diffDays == 1) {
      return 'Yesterday $timePart';
    } else {
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
      return '${months[dt.month - 1]} ${dt.day} $timePart';
    }
  }

  Color get _iconBgColor {
    if (entry.isRedemption) return const Color(0xFFFEF2F2);
    if (entry.isStreak) return const Color(0xFFF5F3FF);
    return const Color(0xFFEFF6FF);
  }

  Color get _iconColor {
    if (entry.isRedemption) return const Color(0xFFEF4444);
    if (entry.isStreak) return const Color(0xFF7C3AED);
    return const Color(0xFF2563EB);
  }

  IconData get _iconData {
    if (entry.isRedemption) return Icons.storefront_outlined;
    if (entry.isStreak) return Icons.local_fire_department_outlined;
    return Icons.shopping_bag_outlined;
  }

  Color get _badgeBgColor {
    if (entry.isRedemption) return const Color(0xFFFEE2E2);
    if (entry.isStreak) return const Color(0xFFF3E8FF);
    return const Color(0xFFDCFCE7);
  }

  Color get _badgeTextColor {
    if (entry.isRedemption) return const Color(0xFFB91C1C);
    if (entry.isStreak) return const Color(0xFF6D28D9);
    return const Color(0xFF15803D);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(_iconData, size: 19, color: _iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${entry.shortTxCode} • ${formatLedgerTimestamp(entry.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _badgeBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  entry.formattedPointsBadge,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _badgeTextColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                entry.formattedSubValue,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
