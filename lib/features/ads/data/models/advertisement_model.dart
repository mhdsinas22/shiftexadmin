import 'package:shiftexadmin/features/ads/domain/entities/advertisement_entity.dart';

class AdvertisementModel extends AdvertisementEntity {
  const AdvertisementModel({
    required super.id,
    required super.title,
    required super.offerDetails,
    super.imageUrl,
    super.imagePath,
    super.popupDurationSeconds,
    super.frequencyType,
    super.frequencyLimit,
    required super.startAt,
    required super.endAt,
    super.status,
    super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    super.publishedAt,
    super.deactivatedAt,
    super.viewsCount,
    super.clicksCount,
    super.claimsCount,
    super.ctrPercent,
  });

  factory AdvertisementModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value, DateTime fallback) {
      if (value == null) return fallback;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString()) ?? fallback;
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    final int views = (json['views_count'] as num?)?.toInt() ?? 0;
    final int claims = (json['claims_count'] as num?)?.toInt() ?? 0;
    final int clicks = (json['clicks_count'] as num?)?.toInt() ?? 0;
    final double ctr = views > 0
        ? double.parse(((claims / views) * 100).toStringAsFixed(1))
        : 0.0;

    return AdvertisementModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      offerDetails: json['offer_details']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      imagePath: json['image_path']?.toString(),
      popupDurationSeconds:
          (json['popup_duration_seconds'] as num?)?.toInt() ?? 6,
      frequencyType: json['frequency_type']?.toString() ?? 'once_per_session',
      frequencyLimit: (json['frequency_limit'] as num?)?.toInt() ?? 1,
      startAt: parseDate(json['start_at'], DateTime.now()),
      endAt: parseDate(
        json['end_at'],
        DateTime.now().add(const Duration(days: 7)),
      ),
      status: json['status']?.toString() ?? 'draft',
      createdBy: json['created_by']?.toString(),
      createdAt: parseDate(json['created_at'], DateTime.now()),
      updatedAt: parseDate(json['updated_at'], DateTime.now()),
      publishedAt: parseNullableDate(json['published_at']),
      deactivatedAt: parseNullableDate(json['deactivated_at']),
      viewsCount: views,
      clicksCount: clicks,
      claimsCount: claims,
      ctrPercent: (json['ctr_percent'] as num?)?.toDouble() ?? ctr,
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'title': title,
      'offer_details': offerDetails,
      'image_url': imageUrl,
      'image_path': imagePath,
      'popup_duration_seconds': popupDurationSeconds,
      'frequency_type': frequencyType,
      'frequency_limit': frequencyLimit,
      'start_at': startAt.toUtc().toIso8601String(),
      'end_at': endAt.toUtc().toIso8601String(),
      'status': status,
      'created_by': createdBy,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    if (publishedAt != null) {
      map['published_at'] = publishedAt!.toUtc().toIso8601String();
    }
    if (deactivatedAt != null) {
      map['deactivated_at'] = deactivatedAt!.toUtc().toIso8601String();
    }

    return map;
  }

  @override
  AdvertisementModel copyWith({
    String? id,
    String? title,
    String? offerDetails,
    String? imageUrl,
    String? imagePath,
    int? popupDurationSeconds,
    String? frequencyType,
    int? frequencyLimit,
    DateTime? startAt,
    DateTime? endAt,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
    DateTime? deactivatedAt,
    int? viewsCount,
    int? clicksCount,
    int? claimsCount,
    double? ctrPercent,
    bool clearDeactivatedAt = false,
  }) {
    return AdvertisementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      offerDetails: offerDetails ?? this.offerDetails,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePath: imagePath ?? this.imagePath,
      popupDurationSeconds: popupDurationSeconds ?? this.popupDurationSeconds,
      frequencyType: frequencyType ?? this.frequencyType,
      frequencyLimit: frequencyLimit ?? this.frequencyLimit,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      deactivatedAt: clearDeactivatedAt
          ? null
          : (deactivatedAt ?? this.deactivatedAt),
      viewsCount: viewsCount ?? this.viewsCount,
      clicksCount: clicksCount ?? this.clicksCount,
      claimsCount: claimsCount ?? this.claimsCount,
      ctrPercent: ctrPercent ?? this.ctrPercent,
    );
  }

  factory AdvertisementModel.fromEntity(AdvertisementEntity entity) {
    return AdvertisementModel(
      id: entity.id,
      title: entity.title,
      offerDetails: entity.offerDetails,
      imageUrl: entity.imageUrl,
      imagePath: entity.imagePath,
      popupDurationSeconds: entity.popupDurationSeconds,
      frequencyType: entity.frequencyType,
      frequencyLimit: entity.frequencyLimit,
      startAt: entity.startAt,
      endAt: entity.endAt,
      status: entity.status,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      publishedAt: entity.publishedAt,
      deactivatedAt: entity.deactivatedAt,
      viewsCount: entity.viewsCount,
      clicksCount: entity.clicksCount,
      claimsCount: entity.claimsCount,
      ctrPercent: entity.ctrPercent,
    );
  }
}
