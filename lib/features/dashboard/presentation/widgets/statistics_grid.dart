import 'package:flutter/material.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/dashboard_statistics_entity.dart';
import 'package:shiftexadmin/features/dashboard/presentation/widgets/dashboard_stat_card_widget.dart';

class StatisticsGrid extends StatelessWidget {
  final DashboardStatisticsEntity statistics;

  const StatisticsGrid({super.key, required this.statistics});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: DashboardStatCardWidget(
                  key: const Key('stat_card_total_claims'),
                  icon: Icons.assignment_turned_in_outlined,
                  badgeText: statistics.formattedGrowthBadge,
                  badgeBackgroundColor: const Color(0xFFF3E8FF),
                  badgeTextColor: const Color(0xFF7E22CE),
                  primaryValue: statistics.formattedTotalClaims,
                  subtitle: 'Total claims processed',
                  valueFontSize: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DashboardStatCardWidget(
                  key: const Key('stat_card_net_value'),
                  icon: Icons.stars_rounded,
                  badgeText: 'Points Given',
                  badgeBackgroundColor: const Color(0xFFEFF6FF),
                  badgeTextColor: const Color(0xFF2563EB),
                  primaryValue: statistics.formattedTotalPointsGiven,
                  subtitle: 'Total points issued',
                  valueFontSize: 21,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: DashboardStatCardWidget(
                  key: const Key('stat_card_liquid_points'),
                  icon: Icons.bolt_rounded,
                  badgeText: '• Liquid',
                  badgeBackgroundColor: const Color(0xFFDCFCE7),
                  badgeTextColor: const Color(0xFF15803D),
                  primaryValue: statistics.formattedLiquidPoints,
                  subtitle: statistics.formattedLiquidPoolPointsSubtitle,
                  valueFontSize: 18.5,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DashboardStatCardWidget(
                  key: const Key('stat_card_locked_points'),
                  icon: Icons.lock_clock_outlined,
                  badgeText: 'Batched',
                  badgeBackgroundColor: const Color(0xFFFEF3C7),
                  badgeTextColor: const Color(0xFFB45309),
                  primaryValue: statistics.formattedLockedPoints,
                  subtitle: statistics.formattedLockedPoolPointsSubtitle,
                  valueFontSize: 18.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
