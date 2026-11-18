import 'package:shiftexadmin/features/dashboard/domain/entities/admin_identity_entity.dart';

class AdminIdentityModel extends AdminIdentityEntity {
  const AdminIdentityModel({
    required super.id,
    required super.fullName,
    required super.email,
    super.roleLabel,
    super.organizationLabel,
  });

  factory AdminIdentityModel.fromJson(Map<String, dynamic> json) {
    return AdminIdentityModel(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? 'Admin',
      email: json['email']?.toString() ?? '',
      roleLabel: json['role_label']?.toString() ?? 'Super Admin',
      organizationLabel:
          json['organization_label']?.toString() ?? 'ShiftEx Central Control',
    );
  }
}
