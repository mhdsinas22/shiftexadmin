class PosAllocationResultEntity {
  final bool success;
  final String customerId;
  final String fullName;
  final String membershipId;
  final int instantPointsAllocated;
  final int futurePointsAllocated;
  final int totalPointsAllocated;
  final double instantInrEquivalent;
  final double futureInrEquivalent;
  final double totalInrEquivalent;
  final int pointsPerRupee;
  final double pointsToInrRate;
  final String currencyCode;
  final String? rateVersionId;
  final String billNumber;
  final String branchName;
  final int availablePoints;
  final int lockedPoints;
  final int lifetimeEarnedPoints;
  final int lifetimeRedeemedPoints;
  final String? instantTransactionId;
  final String? futureTransactionId;
  final String? futureAllocationId;
  final DateTime? unlockAt;
  final DateTime allocatedAt;

  const PosAllocationResultEntity({
    required this.success,
    required this.customerId,
    required this.fullName,
    required this.membershipId,
    required this.instantPointsAllocated,
    required this.futurePointsAllocated,
    required this.totalPointsAllocated,
    this.instantInrEquivalent = 0.0,
    this.futureInrEquivalent = 0.0,
    required this.totalInrEquivalent,
    this.pointsPerRupee = 10,
    this.pointsToInrRate = 0.10,
    this.currencyCode = 'INR',
    this.rateVersionId,
    required this.billNumber,
    required this.branchName,
    required this.availablePoints,
    required this.lockedPoints,
    this.lifetimeEarnedPoints = 0,
    this.lifetimeRedeemedPoints = 0,
    this.instantTransactionId,
    this.futureTransactionId,
    this.futureAllocationId,
    this.unlockAt,
    required this.allocatedAt,
  });
}

class PosClaimRedemptionResultEntity {
  final bool success;
  final String customerId;
  final String fullName;
  final String membershipId;
  final String tokenCode;
  final int redeemedPoints;
  final double inrValue;
  final int pointsPerRupee;
  final double pointsToInrRate;
  final String currencyCode;
  final String billNumber;
  final String branchName;
  final int availablePoints;
  final int lockedPoints;
  final int lifetimeRedeemedPoints;
  final String transactionId;
  final DateTime redeemedAt;

  const PosClaimRedemptionResultEntity({
    required this.success,
    required this.customerId,
    required this.fullName,
    required this.membershipId,
    required this.tokenCode,
    required this.redeemedPoints,
    required this.inrValue,
    this.pointsPerRupee = 10,
    this.pointsToInrRate = 0.10,
    this.currencyCode = 'INR',
    required this.billNumber,
    required this.branchName,
    required this.availablePoints,
    required this.lockedPoints,
    this.lifetimeRedeemedPoints = 0,
    required this.transactionId,
    required this.redeemedAt,
  });
}
