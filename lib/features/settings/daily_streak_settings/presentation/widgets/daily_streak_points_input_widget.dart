import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';

class DailyStreakPointsInputWidget extends StatefulWidget {
  final String pointsText;
  final int pointsPerRupee;
  final bool enabled;
  final String? validationError;
  final ValueChanged<String> onChanged;

  const DailyStreakPointsInputWidget({
    super.key,
    required this.pointsText,
    required this.pointsPerRupee,
    required this.enabled,
    required this.onChanged,
    this.validationError,
  });

  @override
  State<DailyStreakPointsInputWidget> createState() =>
      _DailyStreakPointsInputWidgetState();
}

class _DailyStreakPointsInputWidgetState
    extends State<DailyStreakPointsInputWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.pointsText);
  }

  @override
  void didUpdateWidget(covariant DailyStreakPointsInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pointsText != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.pointsText,
        selection: TextSelection.collapsed(offset: widget.pointsText.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.validationError != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Points per Daily Check-in',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: widget.enabled
                ? const Color(0xFFF8FAFC)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError ? AppColors.purered : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 66,
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  onChanged: widget.onChanged,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: widget.enabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
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
                'PTS',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Points / login',
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            widget.validationError!,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.purered,
            ),
          ),
        ],
      ],
    );
  }
}
