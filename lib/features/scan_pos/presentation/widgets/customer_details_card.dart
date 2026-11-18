import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/features/scan_pos/domain/entities/verified_pos_customer_entity.dart';

class CustomerDetailsCard extends StatelessWidget {
  final VerifiedPosCustomerEntity customer;
  final VoidCallback onClearPressed;

  const CustomerDetailsCard({
    super.key,
    required this.customer,
    required this.onClearPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool isApproved = customer.isApproved;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Customer Initials Avatar
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              customer.initials,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.pureWhite,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Customer Name + Membership ID + Phone Number
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      customer.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (customer.tokenCode != null) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: customer.hasClaimToken
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          customer.tokenCode!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: customer.hasClaimToken
                                ? AppColors.linkBlue
                                : const Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '${customer.membershipId}  •  ${customer.mobileNumber.isNotEmpty ? customer.mobileNumber : customer.email}',
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
        const SizedBox(width: 8),

        // Account Verification Status Icon + Clear
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isApproved
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isApproved
                    ? Icons.check_circle_outline_rounded
                    : Icons.error_outline_rounded,
                size: 18,
                color: isApproved ? AppColors.eifGreen : AppColors.purered,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: onClearPressed,
              tooltip: 'Clear customer',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              icon: const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
