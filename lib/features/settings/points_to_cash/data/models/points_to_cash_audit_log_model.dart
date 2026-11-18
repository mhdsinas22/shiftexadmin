import 'package:shiftexadmin/features/settings/points_to_cash/domain/entities/points_to_cash_audit_log_entity.dart';

class PointsToCashAuditLogModel extends PointsToCashAuditLogEntity {
  const PointsToCashAuditLogModel({
    required super.id,
    required super.versionNumber,
    super.previousPointsPerRupee,
    required super.newPointsPerRupee,
    super.previousPointsToInrRate,
    required super.newPointsToInrRate,
    super.currencyCode,
    super.changedBy,
    super.changedByEmail,
    super.note,
    required super.effectiveAt,
    required super.createdAt,
  });

  static double? _parseNullableNum(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString());
  }

  static int? _parseNullableInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is num) return val.round();
    return int.tryParse(val.toString()) ??
        double.tryParse(val.toString())?.round();
  }

  factory PointsToCashAuditLogModel.fromJson(Map<String, dynamic> json) {
    final createdAt = json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
        : DateTime.now();

    final prevPts = _parseNullableInt(
      json['previous_points_per_rupee'] ??
          json['previous_points_per_currency_unit'],
    );
    final newPts =
        _parseNullableInt(
          json['new_points_per_rupee'] ?? json['new_points_per_currency_unit'],
        ) ??
        10;

    return PointsToCashAuditLogModel(
      id: json['id']?.toString() ?? '',
      versionNumber: (json['version_number'] as num?)?.toInt() ?? 1,
      previousPointsPerRupee: prevPts,
      newPointsPerRupee: newPts > 0 ? newPts : 10,
      previousPointsToInrRate: _parseNullableNum(
        json['previous_points_to_inr_rate'],
      ),
      newPointsToInrRate:
          _parseNullableNum(json['new_points_to_inr_rate']) ?? 0.10,
      currencyCode: json['currency_code']?.toString() ?? 'INR',
      changedBy: json['changed_by']?.toString(),
      changedByEmail: json['changed_by_email']?.toString(),
      note: json['note']?.toString(),
      effectiveAt: json['effective_at'] != null
          ? DateTime.tryParse(json['effective_at'].toString()) ?? createdAt
          : createdAt,
      createdAt: createdAt,
    );
  }
}
