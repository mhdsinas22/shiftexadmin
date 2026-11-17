class AdvertisementEntity {
  final String id;
  final String title;
  final String offerDetails;
  final String? imageUrl;
  final String? imagePath;
  final int popupDurationSeconds;
  final String frequencyType;
  final int frequencyLimit;
  final DateTime startAt;
  final DateTime endAt;
  final String status;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final DateTime? deactivatedAt;
  final int viewsCount;
  final int clicksCount;
  final int claimsCount;
  final double ctrPercent;

  const AdvertisementEntity({
    required this.id,
    required this.title,
    required this.offerDetails,
    this.imageUrl,
    this.imagePath,
    this.popupDurationSeconds = 6,
    this.frequencyType = 'once_per_session',
    this.frequencyLimit = 1,
    required this.startAt,
    required this.endAt,
    this.status = 'draft',
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
    this.deactivatedAt,
    this.viewsCount = 0,
    this.clicksCount = 0,
    this.claimsCount = 0,
    this.ctrPercent = 0.0,
  });

  bool get isDraft => status.toLowerCase() == 'draft';
  bool get isDeactivated =>
      status.toLowerCase() == 'deactivated' || deactivatedAt != null;

  bool get isScheduled {
    if (isDraft || isDeactivated) return false;
    return startAt.isAfter(DateTime.now());
  }

  bool get isActive {
    if (isDraft || isDeactivated) return false;
    final now = DateTime.now();
    return (startAt.isBefore(now) || startAt.isAtSameMomentAs(now)) &&
        endAt.isAfter(now);
  }

  bool get isEnded {
    if (isDraft || isDeactivated) return false;
    return endAt.isBefore(DateTime.now());
  }

  String get effectiveStatus {
    if (isDeactivated) return 'deactivated';
    if (isDraft) return 'draft';
    if (isActive) return 'active';
    if (isScheduled) return 'scheduled';
    if (isEnded) return 'ended';
    return status;
  }

  String get formattedFrequency {
    switch (frequencyType) {
      case 'once_per_day':
        return '1x / day';
      case 'once_per_user':
        return 'Once per user';
      case 'once_per_session':
      default:
        return '1x / session';
    }
  }

  AdvertisementEntity copyWith({
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
    return AdvertisementEntity(
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
}
