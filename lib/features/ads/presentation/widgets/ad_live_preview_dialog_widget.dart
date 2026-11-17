import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/features/ads/domain/entities/advertisement_entity.dart';

class AdLivePreviewDialogWidget extends StatefulWidget {
  final AdvertisementEntity advertisement;
  final Function(String adId, String eventType)? onTrackEvent;

  const AdLivePreviewDialogWidget({
    super.key,
    required this.advertisement,
    this.onTrackEvent,
  });

  static Future<void> show(
    BuildContext context, {
    required AdvertisementEntity advertisement,
    Function(String adId, String eventType)? onTrackEvent,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0xCC0B1120),
      builder: (_) => AdLivePreviewDialogWidget(
        advertisement: advertisement,
        onTrackEvent: onTrackEvent,
      ),
    );
  }

  @override
  State<AdLivePreviewDialogWidget> createState() =>
      _AdLivePreviewDialogWidgetState();
}

class _AdLivePreviewDialogWidgetState extends State<AdLivePreviewDialogWidget> {
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.advertisement.popupDurationSeconds > 0
        ? widget.advertisement.popupDurationSeconds
        : 6;

    widget.onTrackEvent?.call(widget.advertisement.id, 'impression');

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 1) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
        }
      } else {
        _timer?.cancel();
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleClaim() {
    widget.onTrackEvent?.call(widget.advertisement.id, 'claim');
    _timer?.cancel();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Offer Claimed! (Recorded test analytics for "${widget.advertisement.title}")',
        ),
        backgroundColor: AppColors.eifGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar with Timer & Close Button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 13,
                            color: AppColors.linkBlue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Auto-closes in ${_remainingSeconds}s',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.linkBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Image Banner
              if (widget.advertisement.imageUrl != null &&
                  widget.advertisement.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  child: Image.network(
                    widget.advertisement.imageUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _buildFallbackBanner(),
                  ),
                )
              else
                _buildFallbackBanner(),

              // Text Details
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.advertisement.title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.advertisement.offerDetails,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Primary Action CTA
                    ElevatedButton(
                      onPressed: _handleClaim,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.linkBlue,
                        foregroundColor: AppColors.pureWhite,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.redeem_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Claim Reward Offer',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ShiftEx Branding footer
                    const Center(
                      child: Text(
                        'ShiftEx Verified Partner Promotion',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackBanner() {
    return Container(
      height: 150,
      color: const Color(0xFF0F172A),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_rounded, size: 48, color: Color(0xFF94A3B8)),
            SizedBox(height: 6),
            Text(
              'ShiftEx In-App Promotion',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
