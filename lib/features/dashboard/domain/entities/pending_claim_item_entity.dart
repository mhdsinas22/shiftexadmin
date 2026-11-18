class PendingClaimItemEntity {
  final String id;
  final String? qrTokenId;
  final String claimReference;
  final String qrPayload;
  final String userId;
  final String customerName;
  final String membershipId;
  final String merchantCounter;
  final String statusSubtitle;
  final int points;
  final double pointsToInrRate;
  final double discountAmount;
  final String status;
  final DateTime expiresAt;
  final DateTime createdAt;

  const PendingClaimItemEntity({
    required this.id,
    this.qrTokenId,
    required this.claimReference,
    required this.qrPayload,
    required this.userId,
    required this.customerName,
    required this.membershipId,
    this.merchantCounter = 'SHIIFTEX POS Counter',
    this.statusSubtitle = 'Point deduction verified',
    required this.points,
    this.pointsToInrRate = 0.10,
    required this.discountAmount,
    this.status = 'pending',
    required this.expiresAt,
    required this.createdAt,
  });

  bool isExpiredAt([DateTime? now]) {
    final ref = now ?? DateTime.now();
    return status.toLowerCase() != 'pending' || !expiresAt.isAfter(ref);
  }

  Duration remainingDuration([DateTime? now]) {
    final ref = now ?? DateTime.now();
    final diff = expiresAt.difference(ref);
    return diff.isNegative ? Duration.zero : diff;
  }

  String formattedCountdown([DateTime? now]) {
    final rem = remainingDuration(now);
    final totalSeconds = rem.inSeconds;
    if (totalSeconds <= 0) return '00:00';
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get formattedDiscountInr => '₹${discountAmount.toStringAsFixed(2)}';

  String get formattedPoints => '$points pts';

  String get verificationCode =>
      qrPayload.trim().isNotEmpty ? qrPayload.trim() : claimReference.trim();
}
