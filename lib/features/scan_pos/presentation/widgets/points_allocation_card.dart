import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/bloc/scan_pos_state.dart';

class PointsAllocationCard extends StatefulWidget {
  final ScanPosState state;
  final ValueChanged<String> onInstantPointsChanged;
  final ValueChanged<String> onFuturePointsChanged;
  final ValueChanged<String> onBillNumberChanged;
  final VoidCallback onConfirmPressed;

  const PointsAllocationCard({
    super.key,
    required this.state,
    required this.onInstantPointsChanged,
    required this.onFuturePointsChanged,
    required this.onBillNumberChanged,
    required this.onConfirmPressed,
  });

  @override
  State<PointsAllocationCard> createState() => _PointsAllocationCardState();
}

class _PointsAllocationCardState extends State<PointsAllocationCard> {
  late final TextEditingController _instantController;
  late final TextEditingController _futureController;
  late final TextEditingController _billController;

  @override
  void initState() {
    super.initState();
    _instantController = TextEditingController(
      text: widget.state.instantPointsInput,
    );
    _futureController = TextEditingController(
      text: widget.state.futurePointsInput,
    );
    _billController = TextEditingController(text: widget.state.billNumberInput);
  }

  @override
  void didUpdateWidget(covariant PointsAllocationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.instantPointsInput != _instantController.text) {
      _instantController.value = TextEditingValue(
        text: widget.state.instantPointsInput,
        selection: TextSelection.collapsed(
          offset: widget.state.instantPointsInput.length,
        ),
      );
    }
    if (widget.state.futurePointsInput != _futureController.text) {
      _futureController.value = TextEditingValue(
        text: widget.state.futurePointsInput,
        selection: TextSelection.collapsed(
          offset: widget.state.futurePointsInput.length,
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
    _instantController.dispose();
    _futureController.dispose();
    _billController.dispose();
    super.dispose();
  }

  String _formatUnlockDate(int days) {
    final target = DateTime.now().add(Duration(days: days));
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return 'Auto-release ${months[target.month - 1]} ${target.day} (${days}d)';
  }

  @override
  Widget build(BuildContext context) {
    final totalPts = widget.state.totalAllocationPoints;
    final isAllocating = widget.state.status == ScanPosStatus.allocating;
    final showBillError =
        widget.state.status == ScanPosStatus.error &&
        widget.state.errorMessage.toLowerCase().contains('bill');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Points Allocation',
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
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Instant & Future Pts',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textHint,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Instant Pts + Future Pts Side-by-Side Input Cards
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instant Points Card
            Expanded(
              child: Container(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Instant Pts',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.bolt_rounded,
                          size: 16,
                          color: AppColors.linkBlue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _instantController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            onChanged: widget.onInstantPointsChanged,
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
                              hintStyle: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textHint,
                              ),
                            ),
                          ),
                        ),
                        const Text(
                          'pts',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Immediate credit',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.linkBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Future Points Card
            Expanded(
              child: Container(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Future Pts',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.access_time_rounded,
                          size: 15,
                          color: Color(0xFFB45309),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _futureController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            onChanged: widget.onFuturePointsChanged,
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
                              hintStyle: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textHint,
                              ),
                            ),
                          ),
                        ),
                        const Text(
                          'pts',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Locked until unlock',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Reference Context Box (Bill #, Unlock schedule, Expiration)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    flex: 5,
                    child: Text(
                      'Reference Context',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 155),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.pureWhite,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: showBillError
                                ? AppColors.purered
                                : (widget.state.billNumberInput.trim().length <
                                          2
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF94A3B8)),
                            width: showBillError ? 1.4 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Flexible(
                              flex: 0,
                              child: Text(
                                'Bill #',
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _billController,
                                onChanged: widget.onBillNumberChanged,
                                textCapitalization:
                                    TextCapitalization.characters,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  hintText: 'Enter #',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 6),
                  const Flexible(
                    flex: 0,
                    child: Text(
                      'Unlock schedule:',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.state.futurePoints > 0
                          ? _formatUnlockDate(widget.state.unlockDays)
                          : 'Immediate credit only',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 6),
                  const Flexible(
                    child: Text(
                      'Expiration:',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Valid ${widget.state.expiryDays} Days',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (widget.state.status == ScanPosStatus.error &&
            widget.state.errorMessage.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 15,
                  color: AppColors.purered,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.state.errorMessage,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.purered,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),

        // Confirm & Allocate Primary CTA Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isAllocating ? null : widget.onConfirmPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              disabledBackgroundColor: const Color(0xFF64748B),
              foregroundColor: AppColors.pureWhite,
              disabledForegroundColor: AppColors.pureWhite,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            icon: isAllocating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.pureWhite,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 17),
            label: Text(
              isAllocating
                  ? 'Allocating Points...'
                  : 'Confirm & Allocate $totalPts pts',
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
