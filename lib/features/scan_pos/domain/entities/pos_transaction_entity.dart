class PosTransactionEntity {
  final String id;
  final String customerId;
  final String customerName;
  final String membershipId;
  final String? tokenCode;
  final String transactionType;
  final String title;
  final String description;
  final int pointsDelta;
  final bool isLockedAllocation;
  final String? billNumber;
  final String branchName;
  final String? adminId;
  final int? pointsPerRupee;
  final double? pointsToInrRate;
  final String currencyCode;
  final double inrEquivalent;
  final String status;
  final DateTime createdAt;

  const PosTransactionEntity({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.membershipId,
    this.tokenCode,
    required this.transactionType,
    required this.title,
    required this.description,
    required this.pointsDelta,
    required this.isLockedAllocation,
    this.billNumber,
    required this.branchName,
    this.adminId,
    this.pointsPerRupee,
    this.pointsToInrRate,
    this.currencyCode = 'INR',
    required this.inrEquivalent,
    required this.status,
    required this.createdAt,
  });

  bool get isRedemption => transactionType == 'discount_redemption';
}
