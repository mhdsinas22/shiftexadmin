class PointsToCashAuditLogEntity {
  final String id;
  final int versionNumber;
  final int? previousPointsPerRupee;
  final int newPointsPerRupee;
  final double? previousPointsToInrRate;
  final double newPointsToInrRate;
  final String currencyCode;
  final String? changedBy;
  final String? changedByEmail;
  final String? note;
  final DateTime effectiveAt;
  final DateTime createdAt;

  const PointsToCashAuditLogEntity({
    required this.id,
    required this.versionNumber,
    this.previousPointsPerRupee,
    required this.newPointsPerRupee,
    this.previousPointsToInrRate,
    required this.newPointsToInrRate,
    this.currencyCode = 'INR',
    this.changedBy,
    this.changedByEmail,
    this.note,
    required this.effectiveAt,
    required this.createdAt,
  });
}
