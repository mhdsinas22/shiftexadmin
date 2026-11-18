import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/bloc/scan_pos_state.dart';

class VerifyClaimCardWidget extends StatefulWidget {
  final ScanPosState state;
  final ValueChanged<String> onRedeemPointsChanged;
  final ValueChanged<String> onBillNumberChanged;
  final VoidCallback onConfirmRedeemPressed;

  const VerifyClaimCardWidget({
    super.key,
    required this.state,
    required this.onRedeemPointsChanged,
    required this.onBillNumberChanged,
    required this.onConfirmRedeemPressed,
  });

  @override
  State<VerifyClaimCardWidget> createState() => _VerifyClaimCardWidgetState();
}

class _VerifyClaimCardWidgetState extends State<VerifyClaimCardWidget> {
  late final TextEditingController _redeemController;
  late final TextEditingController _billController;

  @override
  void initState() {
    super.initState();
    _redeemController =
        TextEditingController(text: widget.state.redeemPointsInput);
    _billController =
        TextEditingController(text: widget.state.billNumberInput);
  }

  @override
  void didUpdateWidget(covariant VerifyClaimCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.redeemPointsInput != _redeemController.text) {
      _redeemController.value = TextEditingValue(
        text: widget.state.redeemPointsInput,
        selection: TextSelection.collapsed(
          offset: widget.state.redeemPointsInput.length,
        ),
      );
    }
    if (widget.state.billNumberInput != _billController.text) {
      _billController.value = TextEditingValue(
        text: widget.state.billNumberInput,
        selection: TextSelection.collapsed(
          offset: widget.state.billNumberInput.length,
        ),
      );
    }
  }

  @override
  void dispose() {
    _redeemController.dispose();
    _billController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.state.customer;
    final hasClaimToken = customer?.hasClaimToken ?? false;
    final isProcessing = widget.state.status == ScanPosStatus.allocating;

    if (!hasClaimToken) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: const Row(
          children: [
            Icon(Icons.qr_code_2_rounded, color: AppColors.linkBlue, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Scan or enter a Customer single-use Claim QR (CLM-XXXX) to verify & redeem instant points.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E40AF),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final redeemPts = widget.state.redeemPoints;
    final redeemInr = widget.state.redeemInr.toStringAsFixed(2);
    final availablePts = customer!.availablePoints;
    final exceedsBalance = redeemPts > availablePts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Claim Redemption Verification',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Single-Use Authorized',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF15803D),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: exceedsBalance
                  ? AppColors.purered
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Points to Redeem from Instant Balance',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _redeemController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      onChanged: widget.onRedeemPointsChanged,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        hintText: '0',
                      ),
                    ),
                  ),
                  const Text(
                    'pts',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Discount: ₹$redeemInr',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.linkBlue,
                      ),
                    ),
                  ),
                ],
              ),
              if (exceedsBalance) ...[
                const SizedBox(height: 6),
                Text(
                  'Exceeds customer available balance ($availablePts pts max).',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.purered,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Text(
                'Bill Reference #',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _billController,
                  onChanged: widget.onBillNumberChanged,
                  textAlign: TextAlign.right,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: 'Enter #',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isProcessing ? null : widget.onConfirmRedeemPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.linkBlue,
              foregroundColor: AppColors.pureWhite,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            icon: isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.pureWhite,
                    ),
                  )
                : const Icon(Icons.verified_rounded, size: 18),
            label: Text(
              isProcessing
                  ? 'Verifying & Redeeming...'
                  : 'Verify & Redeem $redeemPts pts (₹$redeemInr)',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
