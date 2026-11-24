class DashboardStatisticsEntity {
  final int totalClaimsProcessed;
  final int claimsCurrent30d;
  final int claimsPrev30d;
  final double? claimsGrowthPct;
  final double netValueInr;
  final int totalPointsGiven;
  final int activePointsPerRupee;
  final double activePointsToInrRate;
  final String currencyCode;
  final int liquidPoints;
  final double liquidPoolInr;
  final int lockedPoints;
  final double lockedPoolInr;

  const DashboardStatisticsEntity({
    this.totalClaimsProcessed = 0,
    this.claimsCurrent30d = 0,
    this.claimsPrev30d = 0,
    this.claimsGrowthPct,
    this.netValueInr = 0.0,
    this.totalPointsGiven = 0,
    this.activePointsPerRupee = 10,
    this.activePointsToInrRate = 0.10,
    this.currencyCode = 'INR',
    this.liquidPoints = 0,
    this.liquidPoolInr = 0.0,
    this.lockedPoints = 0,
    this.lockedPoolInr = 0.0,
  });

  bool get hasGrowthComparison => claimsGrowthPct != null;

  String? get formattedGrowthBadge {
    final pct = claimsGrowthPct;
    if (pct == null) return null;
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}%';
  }

  static String formatIndianNumber(int value) {
    final isNegative = value < 0;
    final digits = value.abs().toString();
    if (digits.length <= 3) {
      return isNegative ? '-$digits' : digits;
    }
    final lastThree = digits.substring(digits.length - 3);
    final rest = digits.substring(0, digits.length - 3);
    final buffer = StringBuffer();
    for (int i = 0; i < rest.length; i++) {
      if (i > 0 && (rest.length - i) % 2 == 0) {
        buffer.write(',');
      }
      buffer.write(rest[i]);
    }
    return '${isNegative ? '-' : ''}${buffer.toString()},$lastThree';
  }

  static String formatCurrencyInr(double value) {
    if (value == value.roundToDouble()) {
      return '₹${formatIndianNumber(value.round())}';
    }
    final whole = value.truncate();
    final decimals = ((value - whole).abs() * 100).round().toString().padLeft(
      2,
      '0',
    );
    return '₹${formatIndianNumber(whole)}.$decimals';
  }

  static String formatCompactPoints(int points) {
    if (points >= 100000) {
      final lakhs = points / 100000.0;
      return '${lakhs.toStringAsFixed(1)}L';
    }
    return formatIndianNumber(points);
  }

  String get formattedTotalClaims => formatIndianNumber(totalClaimsProcessed);

  String get formattedNetValueInr => formatCurrencyInr(netValueInr);

  String get formattedTotalPointsGiven =>
      '${formatCompactPoints(totalPointsGiven)} pts';

  String get formattedPointsGivenSubtitle =>
      '≈ ${formatCompactPoints(totalPointsGiven)} pts given';

  String get formattedLiquidPoints => '${formatIndianNumber(liquidPoints)} pts';

  String get formattedLiquidPoolSubtitle =>
      '≈ ${formatCurrencyInr(liquidPoolInr)} pool';

  String get formattedLiquidPoolPointsSubtitle => 'Active instant balance';

  String get formattedLockedPoints => '${formatIndianNumber(lockedPoints)} pts';

  String get formattedLockedPoolSubtitle =>
      '≈ ${formatCurrencyInr(lockedPoolInr)} locked';

  String get formattedLockedPoolPointsSubtitle => 'Scheduled future unlock';
}
