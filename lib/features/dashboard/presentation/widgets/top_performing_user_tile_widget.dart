import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/top_performing_user_entity.dart';

class TopPerformingUserTileWidget extends StatelessWidget {
  final TopPerformingUserEntity user;

  const TopPerformingUserTileWidget({super.key, required this.user});

  bool get _isEliteTier => user.tierBadge.toLowerCase().contains('elite');

  Color get _tierBgColor =>
      _isEliteTier ? const Color(0xFFEDE9FE) : const Color(0xFFFEF3C7);

  Color get _tierTextColor =>
      _isEliteTier ? const Color(0xFF6D28D9) : const Color(0xFFB45309);

  @override
  Widget build(BuildContext context) {
    final isTop = user.isTopEarner;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTop ? 12 : 4,
        vertical: isTop ? 12 : 10,
      ),
      decoration: BoxDecoration(
        color: isTop ? const Color(0xFFF8FAFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isTop ? const Color(0xFFEDE9FE) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${user.rank}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isTop
                    ? const Color(0xFF6D28D9)
                    : const Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      flex: 2,
                      child: Text(
                        user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _tierBgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user.tierBadge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: _tierTextColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  user.membershipAndHubLabel,
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
              Text(
                user.formattedPoints,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                user.activitySubtitle,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: isTop ? FontWeight.w700 : FontWeight.w500,
                  color: isTop
                      ? const Color(0xFF15803D)
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
