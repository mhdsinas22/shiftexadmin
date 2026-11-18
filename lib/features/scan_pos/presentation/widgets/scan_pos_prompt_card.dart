import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/features/scan_pos/domain/entities/verified_pos_customer_entity.dart';

class ScanPosPromptCard extends StatelessWidget {
  final ScanPosMode mode;
  final VoidCallback onEnterCodePressed;
  final VoidCallback onSearchPressed;

  const ScanPosPromptCard({
    super.key,
    required this.mode,
    required this.onEnterCodePressed,
    required this.onSearchPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isClaim = mode == ScanPosMode.verifyClaim;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isClaim
                  ? const Color(0xFFEFF6FF)
                  : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isClaim ? Icons.verified_outlined : Icons.qr_code_2_rounded,
              size: 24,
              color: isClaim ? AppColors.linkBlue : AppColors.darkNavy,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isClaim ? 'Ready to Verify Claim QR' : 'Ready to Scan Member QR',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isClaim
                ? 'Scan the customer\'s single-use Claim QR above or enter their CLM code manually to verify and redeem points.'
                : 'Scan the customer\'s personal Member QR above, enter their ACC code manually, or look up by Phone / Membership ID.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: onEnterCodePressed,
                icon: const Icon(Icons.dialpad_rounded, size: 16),
                label: const Text('Enter Code'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.darkNavy,
                  side: const BorderSide(color: AppColors.borderLight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!isClaim)
                ElevatedButton.icon(
                  onPressed: onSearchPressed,
                  icon: const Icon(Icons.search_rounded, size: 16),
                  label: const Text('Lookup Phone / ID'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkNavy,
                    foregroundColor: AppColors.pureWhite,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
