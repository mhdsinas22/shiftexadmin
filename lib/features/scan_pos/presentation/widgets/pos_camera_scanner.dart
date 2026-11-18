import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/features/scan_pos/domain/entities/verified_pos_customer_entity.dart';

class PosCameraScanner extends StatefulWidget {
  final ScanPosMode mode;
  final bool isVerifying;
  final ValueChanged<String> onQrDetected;
  final VoidCallback onEnterCodeManuallyPressed;
  final VoidCallback onPhoneOrIdSearchPressed;
  final bool enableCamera;

  const PosCameraScanner({
    super.key,
    required this.mode,
    required this.isVerifying,
    required this.onQrDetected,
    required this.onEnterCodeManuallyPressed,
    required this.onPhoneOrIdSearchPressed,
    this.enableCamera = true,
  });

  @override
  State<PosCameraScanner> createState() => _PosCameraScannerState();
}

class _PosCameraScannerState extends State<PosCameraScanner> {
  MobileScannerController? _controller;
  bool _torchEnabled = false;

  @override
  void initState() {
    super.initState();
    if (widget.enableCamera) {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    if (_controller == null) return;
    try {
      await _controller!.toggleTorch();
      if (mounted) {
        setState(() {
          _torchEnabled = !_torchEnabled;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final instruction = widget.mode == ScanPosMode.giveReward
        ? "Align customer's personal Member QR within frame"
        : "Align customer's single-use Claim QR within frame";

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 280,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_controller != null)
              MobileScanner(
                controller: _controller!,
                onDetect: (BarcodeCapture capture) {
                  if (widget.isVerifying) return;
                  for (final barcode in capture.barcodes) {
                    final raw = barcode.rawValue;
                    if (raw != null && raw.trim().isNotEmpty) {
                      widget.onQrDetected(raw);
                      break;
                    }
                  }
                },
                errorBuilder: (context, error) {
                  return Container(
                    color: const Color(0xFF1E293B),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.videocam_off_outlined,
                          color: Color(0xFF94A3B8),
                          size: 36,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Camera preview unavailable (${error.errorCode.name}). Use Manual Code or Phone / ID below.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
            else
              Container(
                color: const Color(0xFF1E293B),
                child: const Center(
                  child: Icon(
                    Icons.qr_code_2_rounded,
                    size: 96,
                    color: Color(0xFF475569),
                  ),
                ),
              ),

            // Top Instruction Overlay Banner
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xCC0F172A),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 16,
                            color: Color(0xFF4ADE80),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              instruction,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.pureWhite,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_controller != null) ...[
                    const SizedBox(width: 8),
                    Material(
                      color: const Color(0xCC0F172A),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: _toggleTorch,
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(9),
                          child: Icon(
                            _torchEnabled
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded,
                            size: 18,
                            color: _torchEnabled
                                ? const Color(0xFFFACC15)
                                : AppColors.pureWhite,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Center QR Scanning Frame Overlay
            Center(
              child: Container(
                width: 158,
                height: 158,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.isVerifying
                        ? const Color(0xFF4ADE80)
                        : Colors.white.withValues(alpha: 0.78),
                    width: 2.5,
                  ),
                ),
                child: widget.isVerifying
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF4ADE80),
                          strokeWidth: 2.6,
                        ),
                      )
                    : null,
              ),
            ),

            // Bottom Action Pills: Enter Code Manually & Phone / ID
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Material(
                      color: const Color(0xDD1E293B),
                      borderRadius: BorderRadius.circular(22),
                      child: InkWell(
                        onTap: widget.onEnterCodeManuallyPressed,
                        borderRadius: BorderRadius.circular(22),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.dialpad_rounded,
                                size: 15,
                                color: AppColors.pureWhite,
                              ),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Enter Code Manually',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.pureWhite,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Material(
                      color: const Color(0xDD1E293B),
                      borderRadius: BorderRadius.circular(22),
                      child: InkWell(
                        onTap: widget.onPhoneOrIdSearchPressed,
                        borderRadius: BorderRadius.circular(22),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_rounded,
                                size: 15,
                                color: AppColors.pureWhite,
                              ),
                              SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  'Phone / ID',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.pureWhite,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
