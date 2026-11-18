import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';

class RejectOrFlagClaimDialogResult {
  final String action;
  final String reason;

  const RejectOrFlagClaimDialogResult({
    required this.action,
    required this.reason,
  });
}

class RejectOrFlagClaimDialogWidget extends StatefulWidget {
  final String claimReference;
  final String customerName;

  const RejectOrFlagClaimDialogWidget({
    super.key,
    required this.claimReference,
    required this.customerName,
  });

  static Future<RejectOrFlagClaimDialogResult?> show(
    BuildContext context, {
    required String claimReference,
    required String customerName,
  }) {
    return showDialog<RejectOrFlagClaimDialogResult>(
      context: context,
      builder: (_) => RejectOrFlagClaimDialogWidget(
        claimReference: claimReference,
        customerName: customerName,
      ),
    );
  }

  @override
  State<RejectOrFlagClaimDialogWidget> createState() =>
      _RejectOrFlagClaimDialogWidgetState();
}

class _RejectOrFlagClaimDialogWidgetState
    extends State<RejectOrFlagClaimDialogWidget> {
  String _selectedAction = 'reject';
  final TextEditingController _reasonController = TextEditingController();
  String? _validationError;

  static const List<String> _presets = [
    'Bill reference mismatch at POS',
    'Suspected screenshot or replay attempt',
    'Customer cancelled order at counter',
    'Claim amount exceeds eligible bill items',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reasonController.text.trim();
    if (reason.length < 3) {
      setState(() {
        _validationError = 'Please enter or select a reason (min 3 characters).';
      });
      return;
    }
    Navigator.of(context).pop(
      RejectOrFlagClaimDialogResult(
        action: _selectedAction,
        reason: reason,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFlag = _selectedAction == 'flag';

    return Dialog(
      backgroundColor: AppColors.pureWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.gpp_maybe_outlined,
                    color: AppColors.purered,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reject or Flag Claim Token',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.claimReference} • ${widget.customerName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    key: const Key('claim_action_option_reject'),
                    onTap: () => setState(() => _selectedAction = 'reject'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !isFlag
                            ? const Color(0xFF090D16)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: !isFlag
                              ? const Color(0xFF090D16)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Reject Claim',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: !isFlag
                              ? AppColors.pureWhite
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    key: const Key('claim_action_option_flag'),
                    onTap: () => setState(() => _selectedAction = 'flag'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isFlag
                            ? AppColors.purered
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isFlag
                              ? AppColors.purered
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Flag Suspicious',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isFlag
                              ? AppColors.pureWhite
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _presets.map((preset) {
                return ActionChip(
                  label: Text(
                    preset,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  backgroundColor: const Color(0xFFF1F5F9),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    setState(() {
                      _reasonController.text = preset;
                      _validationError = null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('reject_or_flag_reason_input'),
              controller: _reasonController,
              maxLines: 2,
              onChanged: (_) {
                if (_validationError != null) {
                  setState(() => _validationError = null);
                }
              },
              decoration: InputDecoration(
                hintText: 'Enter rejection or security flag reason...',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            if (_validationError != null) ...[
              const SizedBox(height: 6),
              Text(
                _validationError!,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.purered,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    key: const Key('confirm_reject_or_flag_claim_button'),
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFlag
                          ? AppColors.purered
                          : const Color(0xFF090D16),
                      foregroundColor: AppColors.pureWhite,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isFlag ? 'Flag Token' : 'Reject Claim',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
