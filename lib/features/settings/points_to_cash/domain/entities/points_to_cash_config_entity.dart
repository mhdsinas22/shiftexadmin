class PointsToCashConfigEntity {
  final String id;
  final int pointsPerRupee;
  final double pointsToInrRate;
  final String currencyCode;
  final DateTime effectiveAt;
  final DateTime updatedAt;
  final String? updatedBy;
  final String? updatedByEmail;

  const PointsToCashConfigEntity({
    required this.id,
    required this.pointsPerRupee,
    required this.pointsToInrRate,
    this.currencyCode = 'INR',
    required this.effectiveAt,
    required this.updatedAt,
    this.updatedBy,
    this.updatedByEmail,
  });

  factory PointsToCashConfigEntity.defaultConfig() {
    final now = DateTime.now();
    return PointsToCashConfigEntity(
      id: 'global',
      pointsPerRupee: 10,
      pointsToInrRate: 0.10,
      currencyCode: 'INR',
      effectiveAt: now,
      updatedAt: now,
    );
  }

  /// Single centralized formula across Admin app:
  /// `INR Value = Points / points_per_rupee` rounded to nearest paisa (2 decimals),
  /// matching PostgreSQL `ROUND(points::numeric / points_per_rupee::numeric, 2)`.
  static double inrFromPoints({
    required int points,
    required int pointsPerRupee,
  }) {
    if (points <= 0 || pointsPerRupee <= 0) return 0.0;
    return ((points * 100) / pointsPerRupee).round() / 100.0;
  }

  /// Inverse centralized conversion: `Point Value = INR Amount × points_per_rupee`.
  static int pointsFromInr({
    required double inrAmount,
    required int pointsPerRupee,
  }) {
    if (inrAmount <= 0 || pointsPerRupee <= 0) return 0;
    return (inrAmount * pointsPerRupee).round();
  }

  static double ratePerPoint(int pointsPerRupee) {
    if (pointsPerRupee <= 0) return 0.10;
    return 1.0 / pointsPerRupee;
  }

  static String formatLiabilityPerPointFor(int pointsPerRupee) {
    final val = ratePerPoint(pointsPerRupee);
    final paise = val * 100.0;
    if ((paise - paise.roundToDouble()).abs() < 0.001) {
      return val.toStringAsFixed(2);
    }
    return val.toStringAsFixed(4);
  }

  double get cashValuePerPoint => ratePerPoint(pointsPerRupee);

  double inrValueFor(int points) =>
      inrFromPoints(points: points, pointsPerRupee: pointsPerRupee);

  int pointsForInr(double inrAmount) =>
      pointsFromInr(inrAmount: inrAmount, pointsPerRupee: pointsPerRupee);

  String get formattedLiabilityPerPoint =>
      formatLiabilityPerPointFor(pointsPerRupee);

  PointsToCashConfigEntity copyWith({
    String? id,
    int? pointsPerRupee,
    double? pointsToInrRate,
    String? currencyCode,
    DateTime? effectiveAt,
    DateTime? updatedAt,
    String? updatedBy,
    String? updatedByEmail,
  }) {
    final nextPtsPerRupee = pointsPerRupee ?? this.pointsPerRupee;
    return PointsToCashConfigEntity(
      id: id ?? this.id,
      pointsPerRupee: nextPtsPerRupee,
      pointsToInrRate: pointsToInrRate ?? ratePerPoint(nextPtsPerRupee),
      currencyCode: currencyCode ?? this.currencyCode,
      effectiveAt: effectiveAt ?? this.effectiveAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedByEmail: updatedByEmail ?? this.updatedByEmail,
    );
  }
}
