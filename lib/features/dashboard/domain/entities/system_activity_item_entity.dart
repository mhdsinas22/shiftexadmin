class SystemActivityItemEntity {
  final String id;
  final String activityType;
  final String title;
  final String subtitle;
  final DateTime occurredAt;

  const SystemActivityItemEntity({
    required this.id,
    required this.activityType,
    required this.title,
    required this.subtitle,
    required this.occurredAt,
  });
}
