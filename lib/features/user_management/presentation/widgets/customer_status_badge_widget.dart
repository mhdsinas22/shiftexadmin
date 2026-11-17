import 'package:flutter/material.dart';

class CustomerStatusBadgeWidget extends StatelessWidget {
  final String status;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const CustomerStatusBadgeWidget({
    super.key,
    required this.status,
    this.fontSize = 10.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;

    final normalized = status.toLowerCase();
    if (normalized == 'approved' || normalized == 'verified') {
      bg = const Color(0xFFDCFCE7);
      text = const Color(0xFF15803D);
      label = 'Verified';
    } else if (normalized == 'pending') {
      bg = const Color(0xFFFEF3C7);
      text = const Color(0xFFB45309);
      label = 'Pending Review';
    } else {
      bg = const Color(0xFFFEE2E2);
      text = const Color(0xFFB91C1C);
      label = normalized == 'suspended' ? 'Suspended' : 'Restricted';
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
    );
  }
}
