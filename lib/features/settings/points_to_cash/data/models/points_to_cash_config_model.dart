import 'package:shiftexadmin/features/settings/points_to_cash/domain/entities/points_to_cash_config_entity.dart';

class PointsToCashConfigModel extends PointsToCashConfigEntity {
  const PointsToCashConfigModel({
    required super.id,
    required super.pointsPerRupee,
    required super.pointsToInrRate,
    super.currencyCode,
    required super.effectiveAt,
    required super.updatedAt,
    super.updatedBy,
    super.updatedByEmail,
  });

  static double _parseDouble(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static int _parseInt(dynamic value, double rateFallback) {
    if (value is int) return value > 0 ? value : 10;
    if (value is num) return value.round() > 0 ? value.round() : 10;
    final parsed =
        int.tryParse(value?.toString() ?? '') ??
        double.tryParse(value?.toString() ?? '')?.round();
    if (parsed != null && parsed > 0) return parsed;
    if (rateFallback > 0) {
      final derived = (1.0 / rateFallback).round();
      if (derived > 0) return derived;
    }
    return 10;
  }

  factory PointsToCashConfigModel.fromJson(Map<String, dynamic> json) {
    final parsedRate = _parseDouble(json['points_to_inr_rate'], 0.10);
    final int ptsPerRupee = _parseInt(
      json['points_per_rupee'] ?? json['points_per_currency_unit'],
      parsedRate,
    );

    final normalizedRate = parsedRate > 0
        ? parsedRate
        : PointsToCashConfigEntity.ratePerPoint(ptsPerRupee);

    return PointsToCashConfigModel(
      id: json['id']?.toString() ?? 'global',
      pointsPerRupee: ptsPerRupee,
      pointsToInrRate: normalizedRate,
      currencyCode: json['currency_code']?.toString() ?? 'INR',
      effectiveAt: json['effective_at'] != null
          ? DateTime.tryParse(json['effective_at'].toString()) ?? DateTime.now()
          : (json['updated_at'] != null
                ? DateTime.tryParse(json['updated_at'].toString()) ??
                      DateTime.now()
                : DateTime.now()),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedBy: json['updated_by']?.toString(),
      updatedByEmail: json['updated_by_email']?.toString(),
    );
  }
}
