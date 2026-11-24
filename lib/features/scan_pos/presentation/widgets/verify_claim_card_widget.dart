import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/bloc/scan_pos_state.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/widgets/claim_audit_checks_widget.dart';

class VerifyClaimCardWidget extends StatefulWidget {
  final ScanPosState state;
  final ValueChanged<String> onRedeemPointsChanged;
  final ValueChanged<String> onBillNumberChanged;
  final VoidCallback onConfirmRedeemPressed;
  final VoidCallback? onRejectOrFlagPressed;
  final VoidCallback? onRefreshValidationPressed;
  final VoidCallback? onCloseClaimPressed;
  final VoidCallback? onClaimExpired;

  const VerifyClaimCardWidget({
    super.key,
    required this.state,
    required this.onRedeemPointsChanged,
    required this.onBillNumberChanged,
    required this.onConfirmRedeemPressed,
    this.onRejectOrFlagPressed,
    this.onRefreshValidationPressed,
    this.onCloseClaimPressed,
    this.onClaimExpired,
  });

  @override
  State<VerifyClaimCardWidget> createState() => _VerifyClaimCardWidgetState();
}

class _VerifyClaimCardWidgetState extends State<VerifyClaimCardWidget> {
  late final TextEditingController _redeemController;
  late final TextEditingController _billController;
  Timer? _countdownTimer;
  late DateTime _now;
  bool _hasNotifiedExpired = false;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _redeemController = TextEditingController(
      text: widget.state.redeemPointsInput,
    );
    _billController = TextEditingController(text: widget.state.billNumberInput);
    _startCountdown();
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
    if (oldWidget.state.customer?.tokenId != widget.state.customer?.tokenId ||
        oldWidget.state.customer?.tokenExpiresAt !=
            widget.state.customer?.tokenExpiresAt) {
      _hasNotifiedExpired = false;
      _now = DateTime.now();
      _startCountdown();
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    final customer = widget.state.customer;
    if (customer == null || customer.tokenExpiresAt == null) return;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final current = DateTime.now();
      setState(() {
        _now = current;
      });
      final c = widget.state.customer;
      if (c != null && c.isClaimExpiredAt(current) && !_hasNotifiedExpired) {
        _hasNotifiedExpired = true;
        _countdownTimer?.cancel();
        widget.onClaimExpired?.call();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _redeemController.dispose();
    _billController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.state.customer;
    final hasClaimToken = customer?.hasClaimToken ?? false;
    final isProcessing =
        widget.state.status == ScanPosStatus.allocating ||
        widget.state.verifyClaimStatus == VerifyClaimStatus.redeeming ||
        widget.state.verifyClaimStatus == VerifyClaimStatus.rejecting;

    if (!hasClaimToken || customer == null) {
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

    final isExpired =
        customer.isClaimExpiredAt(_now) ||
        widget.state.verifyClaimStatus == VerifyClaimStatus.expired;
    final allChecksPassed = customer.auditChecks.allChecksPassed && !isExpired;
    final redeemPts = widget.state.redeemPoints;
    final availablePts = customer.availablePoints;
    final exceedsBalance = redeemPts > availablePts;
    final hasValidBill = widget.state.billNumberInput.trim().length >= 2;
    final canConfirm =
        allChecksPassed &&
        redeemPts > 0 &&
        !exceedsBalance &&
        hasValidBill &&
        !isProcessing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Header: Verify Claim Token + Refresh + Close
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Verify Claim Token',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.onRefreshValidationPressed != null)
                  IconButton(
                    key: const Key('refresh_claim_validation_button'),
                    onPressed: isProcessing
                        ? null
                        : widget.onRefreshValidationPressed,
                    tooltip: 'Refresh Validation',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: AppColors.linkBlue,
                    ),
                  ),
                if (widget.onCloseClaimPressed != null)
                  IconButton(
                    key: const Key('close_verify_claim_button'),
                    onPressed: isProcessing ? null : widget.onCloseClaimPressed,
                    tooltip: 'Close Claim',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 2. Claim Status Banner: Active & Single-Use badge + Claim Reference + Countdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: allChecksPassed
                ? const Color(0xFFF0FDF4)
                : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: allChecksPassed
                  ? const Color(0xFFBBF7D0)
                  : const Color(0xFFFECACA),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: allChecksPassed
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isExpired
                            ? 'Expired Token'
                            : (allChecksPassed
                                  ? 'Active & Single-Use'
                                  : 'Validation Failed'),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: allChecksPassed
                              ? const Color(0xFF15803D)
                              : AppColors.purered,
                        ),
                      ),
                    ),
                    Text(
                      customer.displayClaimReference,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: isExpired
                        ? AppColors.purered
                        : const Color(0xFF15803D),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    customer.formattedRemainingTime(_now),
                    key: const Key('verify_claim_countdown_text'),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isExpired
                          ? AppColors.purered
                          : const Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 3. Redeemed Item / Offer Card
        Container(
          padding: const EdgeInsets.all(13),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.rewardName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${customer.merchantName} • ${customer.orderReference.isNotEmpty ? customer.orderReference : customer.rewardCategory}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Single-Use Claim',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.linkBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: Color(0xFFE2E8F0)),
              ),
              const Text(
                'Points to Deduct from Instant Balance',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      key: const Key('verify_claim_points_input'),
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
                      '$redeemPts pts Deduction',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
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
        const SizedBox(height: 12),

        // 4. Cryptographic & Replay Audit Checks
        ClaimAuditChecksWidget(
          auditChecks: customer.auditChecks,
          isExpired: isExpired,
        ),
        const SizedBox(height: 12),

        // 5. POS Bill Association
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'POS Bill Association • ${widget.state.branchName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: hasValidBill
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      hasValidBill ? 'Associated' : 'Bill # Required',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: hasValidBill
                            ? const Color(0xFF15803D)
                            : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
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
                      key: const Key('verify_claim_bill_input'),
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
                        hintText: 'Enter Bill / Order #',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 6. Primary Action: Confirm Redemption & Hand Over
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            key: const Key('confirm_redeem_claim_button'),
            onPressed: (!canConfirm && isExpired) || isProcessing
                ? null
                : widget.onConfirmRedeemPressed,
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
                  ? 'Processing Redemption...'
                  : 'Confirm Redemption ($redeemPts pts)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        if (widget.onRejectOrFlagPressed != null) ...[
          const SizedBox(height: 10),
          // 7. Secondary Action: Reject or Flag Token
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              key: const Key('reject_or_flag_claim_button'),
              onPressed: isProcessing ? null : widget.onRejectOrFlagPressed,
              icon: const Icon(
                Icons.gpp_maybe_outlined,
                size: 16,
                color: AppColors.purered,
              ),
              label: const Text(
                'Reject or Flag Token',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.purered,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                backgroundColor: const Color(0xFFFEF2F2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(21),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
