import 'package:shiftexadmin/features/dashboard/domain/entities/master_ledger_entry_entity.dart';

class MasterLedgerEntryModel extends MasterLedgerEntryEntity {
  const MasterLedgerEntryModel({
    required super.id,
    required super.shortTxCode,
    required super.userId,
    required super.customerName,
    required super.membershipId,
    required super.transactionType,
    required super.category,
    required super.title,
    super.description,
    super.billNumber,
    super.branchName,
    required super.pointsDelta,
    super.isLockedAllocation,
    super.pointsPerRupee,
    super.pointsToInrRate,
    required super.inrValue,
    super.currencyCode,
    super.isAutoBonus,
    required super.createdAt,
  });

  factory MasterLedgerEntryModel.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final shortCode =
        json['short_tx_code']?.toString() ??
        (id.isNotEmpty
            ? 'TXN-${id.replaceAll('-', '').substring(0, id.replaceAll('-', '').length >= 5 ? 5 : id.replaceAll('-', '').length).toUpperCase()}'
            : 'TXN-00000');

    final rawPts = json['points_delta'];
    final int pointsDelta = rawPts is num
        ? rawPts.toInt()
        : (int.tryParse(rawPts?.toString() ?? '') ?? 0);

    final rawRate = json['points_to_inr_rate'];
    final double rate = rawRate is num
        ? rawRate.toDouble()
        : (double.tryParse(rawRate?.toString() ?? '') ?? 0.10);

    final rawPtsPerRupee = json['points_per_rupee'];
    final int ptsPerRupee = rawPtsPerRupee is num
        ? rawPtsPerRupee.round()
        : (int.tryParse(rawPtsPerRupee?.toString() ?? '') ??
              (rate > 0 ? (1.0 / rate).round() : 10));

    final rawInr = json['inr_value'] ?? json['cash_value'];
    final double inrValue = rawInr is num
        ? rawInr.toDouble()
        : (double.tryParse(rawInr?.toString() ?? '') ??
              (pointsDelta.abs() * rate));

    final txType = json['transaction_type']?.toString() ?? 'merchant_reward';
    final category =
        json['category']?.toString() ??
        (txType == 'merchant_reward'
            ? 'purchases'
            : txType == 'discount_redemption'
            ? 'redemptions'
            : (txType == 'daily_streak' || txType == 'streak_unlock')
            ? 'streak'
            : 'other');

    final createdAt = json['created_at'] != null
        ? (DateTime.tryParse(json['created_at'].toString())?.toLocal() ??
              DateTime.now())
        : DateTime.now();

    return MasterLedgerEntryModel(
      id: id,
      shortTxCode: shortCode,
      userId: json['user_id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? 'SHIIFTEX Member',
      membershipId: json['membership_id']?.toString() ?? 'SHFT-0000',
      transactionType: txType,
      category: category,
      title: json['title']?.toString() ?? 'Ledger Entry',
      description: json['description']?.toString() ?? '',
      billNumber: json['bill_number']?.toString() ?? '',
      branchName: json['branch_name']?.toString() ?? '',
      pointsDelta: pointsDelta,
      isLockedAllocation: json['is_locked_allocation'] as bool? ?? false,
      pointsPerRupee: ptsPerRupee > 0 ? ptsPerRupee : 10,
      pointsToInrRate: rate,
      inrValue: inrValue,
      currencyCode: json['currency_code']?.toString() ?? 'INR',
      isAutoBonus:
          json['is_auto_bonus'] as bool? ??
          (txType == 'daily_streak' || txType == 'streak_unlock'),
      createdAt: createdAt,
    );
  }
}
