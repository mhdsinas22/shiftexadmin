import 'package:shiftexadmin/features/dashboard/domain/entities/dashboard_statistics_entity.dart';

class DashboardStatisticsModel extends DashboardStatisticsEntity {
  const DashboardStatisticsModel({
    super.totalClaimsProcessed,
    super.claimsCurrent30d,
    super.claimsPrev30d,
    super.claimsGrowthPct,
    super.netValueInr,
    super.totalPointsGiven,
    super.activePointsPerRupee,
    super.activePointsToInrRate,
    super.currencyCode,
    super.liquidPoints,
    super.liquidPoolInr,
    super.lockedPoints,
    super.lockedPoolInr,
  });

  static int _parseInt(dynamic raw, [int fallback = 0]) {
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? fallback;
  }

  static double _parseDouble(dynamic raw, [double fallback = 0.0]) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? fallback;
  }

  static double? _parseNullableDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString());
  }

  factory DashboardStatisticsModel.fromJson(Map<String, dynamic> json) {
    final ptsPerRupee = _parseInt(json['active_points_per_rupee'], 10);
    return DashboardStatisticsModel(
      totalClaimsProcessed: _parseInt(json['total_claims_processed']),
      claimsCurrent30d: _parseInt(json['claims_current_30d']),
      claimsPrev30d: _parseInt(json['claims_prev_30d']),
      claimsGrowthPct: _parseNullableDouble(json['claims_growth_pct']),
      netValueInr: _parseDouble(json['net_value_inr']),
      totalPointsGiven: _parseInt(json['total_points_given']),
      activePointsPerRupee: ptsPerRupee > 0 ? ptsPerRupee : 10,
      activePointsToInrRate: _parseDouble(
        json['active_points_to_inr_rate'],
        ptsPerRupee > 0 ? 1.0 / ptsPerRupee : 0.10,
      ),
      currencyCode: json['currency_code']?.toString() ?? 'INR',
      liquidPoints: _parseInt(json['liquid_points']),
      liquidPoolInr: _parseDouble(json['liquid_pool_inr']),
      lockedPoints: _parseInt(json['locked_points']),
      lockedPoolInr: _parseDouble(json['locked_pool_inr']),
    );
  }
}
