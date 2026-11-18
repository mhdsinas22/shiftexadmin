import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/system_activity_item_entity.dart';

class SystemActivityTileWidget extends StatelessWidget {
  final SystemActivityItemEntity item;

  const SystemActivityTileWidget({super.key, required this.item});

  static String formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Color get _iconBgColor {
    switch (item.activityType) {
      case 'batch_unlock':
        return const Color(0xFFDCFCE7);
      case 'rate_update':
      case 'rule_update':
        return const Color(0xFFFEF3C7);
      case 'user_verification':
        return const Color(0xFFF3E8FF);
      default:
        return const Color(0xFFEFF6FF);
    }
  }

  Color get _iconColor {
    switch (item.activityType) {
      case 'batch_unlock':
        return const Color(0xFF15803D);
      case 'rate_update':
      case 'rule_update':
        return const Color(0xFFB45309);
      case 'user_verification':
        return const Color(0xFF6D28D9);
      default:
        return const Color(0xFF2563EB);
    }
  }

  IconData get _iconData {
    switch (item.activityType) {
      case 'batch_unlock':
        return Icons.sync_rounded;
      case 'rate_update':
      case 'rule_update':
        return Icons.tune_rounded;
      case 'user_verification':
        return Icons.verified_user_outlined;
      default:
        return Icons.sensors_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(_iconData, size: 18, color: _iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${formatRelativeTime(item.occurredAt)} • ${item.subtitle}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
