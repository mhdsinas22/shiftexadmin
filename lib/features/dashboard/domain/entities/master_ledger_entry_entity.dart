enum LedgerCategoryFilter {
  all('all', 'All'),
  purchases('purchases', 'Purchases'),
  redemptions('redemptions', 'Redemptions'),
  streak('streak', 'Streak');

  final String queryKey;
  final String label;

  const LedgerCategoryFilter(this.queryKey, this.label);

  static LedgerCategoryFilter fromString(String? raw) {
    final clean = (raw ?? '').trim().toLowerCase();
    for (final value in LedgerCategoryFilter.values) {
      if (value.queryKey == clean) return value;
    }
    return LedgerCategoryFilter.all;
  }
}

class MasterLedgerEntryEntity {
  final String id;
  final String shortTxCode;
  final String userId;
  final String customerName;
  final String membershipId;
  final String transactionType;
  final String category;
  final String title;
  final String description;
  final String billNumber;
  final String branchName;
  final int pointsDelta;
  final bool isLockedAllocation;
  final int pointsPerRupee;
  final double pointsToInrRate;
  final double inrValue;
  final String currencyCode;
  final bool isAutoBonus;
  final DateTime createdAt;

  const MasterLedgerEntryEntity({
    required this.id,
    required this.shortTxCode,
    required this.userId,
    required this.customerName,
    required this.membershipId,
    required this.transactionType,
    required this.category,
    required this.title,
    this.description = '',
    this.billNumber = '',
    this.branchName = '',
    required this.pointsDelta,
    this.isLockedAllocation = false,
    this.pointsPerRupee = 10,
    this.pointsToInrRate = 0.10,
    required this.inrValue,
    this.currencyCode = 'INR',
    this.isAutoBonus = false,
    required this.createdAt,
  });

  bool get isPositive => pointsDelta >= 0;

  bool get isRedemption =>
      transactionType == 'discount_redemption' || pointsDelta < 0;

  bool get isStreak =>
      transactionType == 'daily_streak' ||
      transactionType == 'streak_unlock' ||
      category == 'streak';

  String get formattedPointsBadge {
    final sign = pointsDelta > 0 ? '+' : '';
    return '$sign$pointsDelta pts';
  }

  String get formattedSubValue {
    if (isAutoBonus) return 'Auto-Bonus';
    final cleanBill = billNumber.trim();
    if (cleanBill.isNotEmpty) {
      return cleanBill.toLowerCase().startsWith('bill')
          ? cleanBill
          : 'Bill #$cleanBill';
    }
    return isRedemption ? 'Points Redeemed' : 'Points Credited';
  }
}
