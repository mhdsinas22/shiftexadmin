import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';

class DailyStreakFixedRuleTileWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool emphasizeValue;

  const DailyStreakFixedRuleTileWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.emphasizeValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 4,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: emphasizeValue ? FontWeight.w700 : FontWeight.w500,
                color: emphasizeValue
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DailyStreakFixedRulesWidget extends StatelessWidget {
  final int eligibilityScansPerCycle;
  final int streakDurationDays;
  final int lockDurationDays;
  final String resetHourLabel;

  const DailyStreakFixedRulesWidget({
    super.key,
    this.eligibilityScansPerCycle = 1,
    this.streakDurationDays = 7,
    this.lockDurationDays = 7,
    this.resetHourLabel = '06:00 AM IST (UTC+05:30)',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DailyStreakFixedRuleTileWidget(
          icon: Icons.verified_user_outlined,
          label: 'Eligibility Threshold',
          value: '$eligibilityScansPerCycle check-in / cycle',
        ),
        const SizedBox(height: 8),
        DailyStreakFixedRuleTileWidget(
          icon: Icons.access_time_rounded,
          label: 'Ledger Reset Hour',
          value: resetHourLabel,
          emphasizeValue: true,
        ),
        const SizedBox(height: 8),
        DailyStreakFixedRuleTileWidget(
          icon: Icons.lock_outline_rounded,
          label: 'Streak Cycle (Fixed)',
          value: '$streakDurationDays days • ${lockDurationDays}d per-day lock',
        ),
      ],
    );
  }
}
