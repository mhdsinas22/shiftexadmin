import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/features/user_management/domain/entities/customer_entity.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/customer_status_badge_widget.dart';

class CustomerDirectoryCardWidget extends StatelessWidget {
  final CustomerEntity customer;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const CustomerDirectoryCardWidget({
    super.key,
    required this.customer,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
  });

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final month = months[dt.month - 1];
    return 'Registered $month ${dt.day}, ${dt.year}';
  }

  Color _avatarBgColor() {
    if (customer.isApproved) return const Color(0xFFEDE9FE);
    if (customer.isPending) return const Color(0xFFFEF3C7);
    if (customer.isRestricted) return const Color(0xFFFEE2E2);
    return const Color(0xFFE0F2FE);
  }

  Color _avatarTextColor() {
    if (customer.isApproved) return AppColors.purple;
    if (customer.isPending) return const Color(0xFFB45309);
    if (customer.isRestricted) return AppColors.purered;
    return const Color(0xFF0284C7);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Customer Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar with badge
                    Stack(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _avatarBgColor(),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              customer.initials,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _avatarTextColor(),
                              ),
                            ),
                          ),
                        ),
                        if (customer.isApproved)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: AppColors.eifGreen,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.pureWhite,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 8,
                                color: AppColors.pureWhite,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // Name, Status Badge & IDs
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  customer.fullName,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              CustomerStatusBadgeWidget(
                                status: customer.approvalStatus,
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${customer.formattedCustomerId} • ${customer.mobileNumber.isNotEmpty ? customer.mobileNumber : customer.email}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (customer.isRestricted &&
                              customer.restrictedReason != null) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 12,
                                  color: AppColors.purered,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    customer.restrictedReason!,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.purered,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Kebab Menu Popup
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        size: 20,
                        color: AppColors.textHint,
                      ),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        if (value == 'details') onTap();
                        if (value == 'approve') onApprove();
                        if (value == 'reject') onReject();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'details',
                          child: Row(
                            children: [
                              Icon(Icons.visibility_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('View Profile'),
                            ],
                          ),
                        ),
                        if (customer.isPending) ...[
                          const PopupMenuItem(
                            value: 'approve',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline,
                                    size: 18, color: AppColors.eifGreen),
                                SizedBox(width: 8),
                                Text('Approve KYC',
                                    style: TextStyle(color: AppColors.eifGreen)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'reject',
                            child: Row(
                              children: [
                                Icon(Icons.cancel_outlined,
                                    size: 18, color: AppColors.purered),
                                SizedBox(width: 8),
                                Text('Reject Customer',
                                    style: TextStyle(color: AppColors.purered)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Sub-card (Wallet / Points Data)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFF1F5F9),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Instant points
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer.isRestricted
                                  ? 'Instant Points (Frozen)'
                                  : 'Instant Points',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: AppColors.textPrimary,
                                ),
                                children: [
                                  TextSpan(
                                    text: '${customer.instantPoints} ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: 'pts',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              customer.isRestricted
                                  ? 'Redemptions paused'
                                  : customer.instantPoints > 0
                                      ? 'Ready to claim'
                                      : 'Zero claimed',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: customer.isRestricted
                                    ? AppColors.purered
                                    : customer.instantPoints > 0
                                        ? AppColors.linkBlue
                                        : AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 36,
                        width: 1,
                        color: const Color(0xFFE2E8F0),
                      ),
                      const SizedBox(width: 14),

                      // Future points
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Future Points',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: AppColors.textPrimary,
                                ),
                                children: [
                                  TextSpan(
                                    text: '${customer.futurePoints} ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: 'pts',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              customer.futurePointsNote ??
                                  (customer.futurePoints > 0
                                      ? 'Hold remaining'
                                      : 'No pending escrow'),
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: customer.futurePoints > 0
                                    ? const Color(0xFFD97706)
                                    : AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Footer: Registered date & Action Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(customer.createdAt),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                    GestureDetector(
                      onTap: customer.isPending ? onApprove : onTap,
                      child: _buildFooterAction(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterAction() {
    if (customer.isPending) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Approve KYC',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB45309),
            ),
          ),
          SizedBox(width: 4),
          Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFFB45309)),
        ],
      );
    }
    if (customer.isRestricted) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Audit Log',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.purered,
            ),
          ),
          SizedBox(width: 4),
          Icon(Icons.shield_outlined, size: 13, color: AppColors.purered),
        ],
      );
    }
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Tap for Profile',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.linkBlue,
          ),
        ),
        SizedBox(width: 2),
        Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.linkBlue),
      ],
    );
  }
}
