import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/features/scan_pos/domain/entities/verified_pos_customer_entity.dart';

class ClaimAuditChecksWidget extends StatelessWidget {
  final ClaimAuditChecksEntity auditChecks;
  final bool isExpired;

  const ClaimAuditChecksWidget({
    super.key,
    required this.auditChecks,
    this.isExpired = false,
  });

  Widget _buildCheckItem(String label, bool passed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 16,
            color: passed ? const Color(0xFF15803D) : AppColors.purered,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: passed ? AppColors.textPrimary : AppColors.purered,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            passed ? 'Passed' : 'Failed',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: passed ? const Color(0xFF15803D) : AppColors.purered,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notExpiredPassed = auditChecks.claimNotExpired && !isExpired;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 15,
                color: AppColors.linkBlue,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Security & Cryptographic Audit Checks',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildCheckItem(
            'Token signature valid',
            auditChecks.tokenSignatureValid,
          ),
          _buildCheckItem('Claim not expired', notExpiredPassed),
          _buildCheckItem(
            'Single-use validation passed',
            auditChecks.singleUsePassed,
          ),
          _buildCheckItem(
            'Replay protection passed',
            auditChecks.replayProtectionPassed,
          ),
        ],
      ),
    );
  }
}
