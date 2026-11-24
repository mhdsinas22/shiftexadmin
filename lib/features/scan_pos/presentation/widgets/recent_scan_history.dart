import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/features/scan_pos/domain/entities/pos_transaction_entity.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/widgets/scan_pos_shimmer_widget.dart';

class RecentScanHistory extends StatelessWidget {
  final List<PosTransactionEntity> transactions;
  final String branchName;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback? onLoadMore;

  const RecentScanHistory({
    super.key,
    required this.transactions,
    required this.branchName,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Recent Scan History',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                branchName,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (isLoading && transactions.isEmpty)
          const ScanPosHistoryShimmerWidget()
        else if (transactions.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 32,
                  color: AppColors.textHint,
                ),
                SizedBox(height: 8),
                Text(
                  'No recent POS transactions yet',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Scanned customer allocations and claim verifications will appear here in real time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                PosTransactionTileWidget(transaction: transactions[index]),
          ),
          if (hasMore && onLoadMore != null) ...[
            const SizedBox(height: 12),
            Center(
              child: OutlinedButton(
                onPressed: isLoadingMore ? null : onLoadMore,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.darkNavy,
                  side: const BorderSide(color: AppColors.borderLight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                ),
                child: isLoadingMore
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Load More History',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class PosTransactionTileWidget extends StatelessWidget {
  final PosTransactionEntity transaction;

  const PosTransactionTileWidget({super.key, required this.transaction});

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isRedemption = transaction.isRedemption;
    final codeBadge =
        (transaction.tokenCode != null &&
            transaction.tokenCode!.trim().isNotEmpty)
        ? transaction.tokenCode!
        : transaction.membershipId;

    final String subtitleText;
    if (isRedemption) {
      final pts = transaction.pointsDelta.abs();
      subtitleText = transaction.title.isNotEmpty
          ? transaction.title
          : 'Redeemed $pts pts${transaction.billNumber != null ? ' • ${transaction.billNumber}' : ''}';
    } else {
      final pts = transaction.pointsDelta.abs();
      final billPart =
          (transaction.billNumber != null &&
              transaction.billNumber!.trim().isNotEmpty)
          ? ' • ${transaction.billNumber}'
          : '';
      subtitleText = 'Allocated $pts pts$billPart';
    }

    final ptsAbs = transaction.pointsDelta.abs();
    final trailingLabel = isRedemption
        ? (transaction.status.toLowerCase() == 'completed'
              ? 'Completed'
              : transaction.status)
        : '+$ptsAbs pts';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isRedemption
                  ? const Color(0xFFEFF6FF)
                  : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isRedemption
                  ? Icons.card_giftcard_outlined
                  : Icons.shopping_bag_outlined,
              size: 19,
              color: isRedemption
                  ? AppColors.linkBlue
                  : const Color(0xFF475569),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${transaction.customerName} ($codeBadge)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitleText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                trailingLabel,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isRedemption ? AppColors.linkBlue : AppColors.eifGreen,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatRelativeTime(transaction.createdAt),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
