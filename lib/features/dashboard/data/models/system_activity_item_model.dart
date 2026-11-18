import 'package:shiftexadmin/features/dashboard/domain/entities/system_activity_item_entity.dart';

class SystemActivityItemModel extends SystemActivityItemEntity {
  const SystemActivityItemModel({
    required super.id,
    required super.activityType,
    required super.title,
    required super.subtitle,
    required super.occurredAt,
  });

  factory SystemActivityItemModel.fromJson(Map<String, dynamic> json) {
    final occurredAt = json['occurred_at'] != null
        ? (DateTime.tryParse(json['occurred_at'].toString())?.toLocal() ??
              DateTime.now())
        : DateTime.now();

    return SystemActivityItemModel(
      id: json['id']?.toString() ?? '',
      activityType: json['activity_type']?.toString() ?? 'terminal_pos',
      title: json['title']?.toString() ?? 'System Event',
      subtitle: json['subtitle']?.toString() ?? 'ShiftEx Central Control',
      occurredAt: occurredAt,
    );
  }
}
