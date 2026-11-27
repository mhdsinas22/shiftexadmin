import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/features/scan_pos/domain/entities/verified_pos_customer_entity.dart';

class ManualQrCodeDialog extends StatefulWidget {
  final ScanPosMode mode;

  const ManualQrCodeDialog({super.key, required this.mode});

  static Future<String?> show(
    BuildContext context, {
    required ScanPosMode mode,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => ManualQrCodeDialog(mode: mode),
    );
  }

  @override
  State<ManualQrCodeDialog> createState() => _ManualQrCodeDialogState();
}

class _ManualQrCodeDialogState extends State<ManualQrCodeDialog> {
  final TextEditingController _codeController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _codeController.text.trim();
    if (text.length < 4) {
      setState(() => _error = 'Enter a valid QR payload or short code.');
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final isClaim = widget.mode == ScanPosMode.verifyClaim;

    return AlertDialog(
      backgroundColor: AppColors.pureWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        isClaim ? 'Enter Claim QR Code' : 'Enter Member QR Code',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isClaim
                ? 'Enter the Claim QR code (e.g. CLM-5A9A-1FE), Order Ref, or full SHIIFTEX:CLAIM payload shown on the customer app.'
                : 'Enter the Member QR code (e.g. ACC-DE0A-FC73), Member ID (e.g. SHFT-81F6), or mobile number.',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => _submit(),
            onChanged: (_) {
              if (_error != null) {
                setState(() => _error = null);
              }
            },
            decoration: InputDecoration(
              hintText: isClaim
                  ? 'CLM-XXXX-XXX'
                  : 'ACC-XXXX-XXXX or SHFT-XXXX',
              errorText: _error,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.linkBlue,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.darkNavy,
            foregroundColor: AppColors.pureWhite,
          ),
          child: const Text('Verify Code'),
        ),
      ],
    );
  }
}
