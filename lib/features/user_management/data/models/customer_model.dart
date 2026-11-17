import 'package:shiftexadmin/features/user_management/domain/entities/customer_entity.dart';

class CustomerModel extends CustomerEntity {
  const CustomerModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.mobileNumber,
    required super.approvalStatus,
    super.approvedBy,
    super.approvedAt,
    super.rejectionReason,
    required super.createdAt,
    required super.updatedAt,
    super.instantPoints,
    super.instantRupees,
    super.futurePoints,
    super.futurePointsNote,
    super.restrictedReason,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final createdAtStr = json['created_at'] as String?;
    final updatedAtStr = json['updated_at'] as String?;
    final approvedAtStr = json['approved_at'] as String?;

    final createdAt = createdAtStr != null
        ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
        : DateTime.now();
    final updatedAt = updatedAtStr != null
        ? DateTime.tryParse(updatedAtStr) ?? DateTime.now()
        : DateTime.now();
    final approvedAt = approvedAtStr != null
        ? DateTime.tryParse(approvedAtStr)
        : null;

    final status = (json['approval_status'] as String? ?? 'pending').toLowerCase();
    final instantPts = json['instant_points'] is num
        ? (json['instant_points'] as num).toInt()
        : (json['wallet'] is Map && json['wallet']['instant_points'] is num)
            ? (json['wallet']['instant_points'] as num).toInt()
            : 0;

    final futurePts = json['future_points'] is num
        ? (json['future_points'] as num).toInt()
        : (json['wallet'] is Map && json['wallet']['future_points'] is num)
            ? (json['wallet']['future_points'] as num).toInt()
            : 0;

    final rupees = instantPts * 0.10;

    String? futureNote;
    if (futurePts > 0) {
      futureNote = status == 'pending' ? 'Welcome Gift' : 'Hold remaining';
    }

    String? restReason = json['rejection_reason'] as String?;
    if (status == 'suspended' && (restReason == null || restReason.isEmpty)) {
      restReason = 'Suspicious account activity';
    }

    return CustomerModel(
      id: id,
      fullName: json['full_name'] as String? ?? 'Unknown Customer',
      email: json['email'] as String? ?? '',
      mobileNumber: json['mobile_number'] as String? ?? '',
      approvalStatus: status,
      approvedBy: json['approved_by'] as String?,
      approvedAt: approvedAt,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
      instantPoints: instantPts,
      instantRupees: rupees,
      futurePoints: futurePts,
      futurePointsNote: futureNote,
      restrictedReason: restReason,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'mobile_number': mobileNumber,
      'approval_status': approvalStatus,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
