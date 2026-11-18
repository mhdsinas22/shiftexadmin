class CustomerEntity {
  final String id;
  final String fullName;
  final String email;
  final String mobileNumber;
  final String approvalStatus;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? customerCode;
  final String? membershipTier;
  final int instantPoints;
  final double instantRupees;
  final int futurePoints;
  final String? futurePointsNote;
  final String? restrictedReason;
  final int earnedPoints;
  final double earnedRupees;
  final int earnedTxCount;

  const CustomerEntity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.mobileNumber,
    required this.approvalStatus,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    this.customerCode,
    this.membershipTier,
    this.instantPoints = 0,
    this.instantRupees = 0.0,
    this.futurePoints = 0,
    this.futurePointsNote,
    this.restrictedReason,
    this.earnedPoints = 0,
    this.earnedRupees = 0.0,
    this.earnedTxCount = 0,
  });

  bool get isPending => approvalStatus.toLowerCase() == 'pending';
  bool get isApproved => approvalStatus.toLowerCase() == 'approved';
  bool get isRejected => approvalStatus.toLowerCase() == 'rejected';
  bool get isSuspended => approvalStatus.toLowerCase() == 'suspended';
  bool get isRestricted => isRejected || isSuspended;

  int get displayTopEarnerPoints =>
      earnedPoints > 0 ? earnedPoints : instantPoints;

  double get displayTopEarnerRupees =>
      earnedRupees > 0 ? earnedRupees : instantRupees;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'U';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String get formattedCustomerId {
    if (customerCode != null && customerCode!.trim().isNotEmpty) {
      return customerCode!.trim();
    }
    if (id.length >= 8) {
      return 'SHFT-${id.substring(0, 4).toUpperCase()}';
    }
    return 'SHFT-$id';
  }

  CustomerEntity copyWith({
    String? id,
    String? fullName,
    String? email,
    String? mobileNumber,
    String? approvalStatus,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customerCode,
    String? membershipTier,
    int? instantPoints,
    double? instantRupees,
    int? futurePoints,
    String? futurePointsNote,
    String? restrictedReason,
    int? earnedPoints,
    double? earnedRupees,
    int? earnedTxCount,
  }) {
    return CustomerEntity(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customerCode: customerCode ?? this.customerCode,
      membershipTier: membershipTier ?? this.membershipTier,
      instantPoints: instantPoints ?? this.instantPoints,
      instantRupees: instantRupees ?? this.instantRupees,
      futurePoints: futurePoints ?? this.futurePoints,
      futurePointsNote: futurePointsNote ?? this.futurePointsNote,
      restrictedReason: restrictedReason ?? this.restrictedReason,
      earnedPoints: earnedPoints ?? this.earnedPoints,
      earnedRupees: earnedRupees ?? this.earnedRupees,
      earnedTxCount: earnedTxCount ?? this.earnedTxCount,
    );
  }
}
