import 'package:shiftexadmin/features/scan_pos/domain/entities/pos_transaction_entity.dart';

class PosTransactionModel extends PosTransactionEntity {
  const PosTransactionModel({
    required super.id,
    required super.customerId,
    required super.customerName,
    required super.membershipId,
    super.tokenCode,
    required super.transactionType,
    required super.title,
    required super.description,
    required super.pointsDelta,
    required super.isLockedAllocation,
    super.billNumber,
    required super.branchName,
    super.adminId,
    super.pointsPerRupee,
    super.pointsToInrRate,
    super.currencyCode,
    required super.inrEquivalent,
    required super.status,
    required super.createdAt,
  });

  factory PosTransactionModel.fromJson(Map<String, dynamic> json) {
    final rawInr = json['inr_equivalent'];
    final double inr = rawInr is num
        ? rawInr.toDouble()
        : (double.tryParse(rawInr?.toString() ?? '') ?? 0.0);

    final rawPtsPerRupee =
        json['points_per_rupee'] ?? json['points_per_currency_unit'];
    int? ptsPerRupee;
    if (rawPtsPerRupee is num) {
      ptsPerRupee = rawPtsPerRupee.round();
    } else if (rawPtsPerRupee != null) {
      ptsPerRupee = double.tryParse(rawPtsPerRupee.toString())?.round();
    }

    final rawRate = json['points_to_inr_rate'];
    final double? rate = rawRate is num
        ? rawRate.toDouble()
        : double.tryParse(rawRate?.toString() ?? '');

    if ((ptsPerRupee == null || ptsPerRupee <= 0) && rate != null && rate > 0) {
      ptsPerRupee = (1.0 / rate).round();
    }

    return PosTransactionModel(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? 'SHIIFTEX Member',
      membershipId: json['membership_id']?.toString() ?? '',
      tokenCode: json['token_code']?.toString(),
      transactionType:
          json['transaction_type']?.toString() ?? 'merchant_reward',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      pointsDelta: (json['points_delta'] as num?)?.toInt() ?? 0,
      isLockedAllocation: json['is_locked_allocation'] as bool? ?? false,
      billNumber: json['bill_number']?.toString(),
      branchName: json['branch_name']?.toString() ?? 'Counter #1 POS',
      adminId: json['admin_id']?.toString(),
      pointsPerRupee: ptsPerRupee,
      pointsToInrRate: rate,
      currencyCode: json['currency_code']?.toString() ?? 'INR',
      inrEquivalent: inr,
      status: json['status']?.toString() ?? 'Completed',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
