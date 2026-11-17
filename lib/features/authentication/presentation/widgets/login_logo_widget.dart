import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';

class ShiftExLogoPainter extends CustomPainter {
  final Color color;

  const ShiftExLogoPainter({
    this.color = AppColors.darkNavy,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    // Stylized modern ShiftEx 'S' emblem
    final path = Path();
    path.moveTo(w * 0.75, h * 0.20);
    path.cubicTo(w * 0.70, h * 0.10, w * 0.60, h * 0.05, w * 0.48, h * 0.05);
    path.cubicTo(w * 0.30, h * 0.05, w * 0.18, h * 0.18, w * 0.18, h * 0.34);
    path.cubicTo(w * 0.18, h * 0.48, w * 0.28, h * 0.55, w * 0.46, h * 0.60);
    path.cubicTo(w * 0.66, h * 0.65, w * 0.80, h * 0.72, w * 0.80, h * 0.86);
    path.cubicTo(w * 0.80, h * 0.98, w * 0.66, h * 1.05, w * 0.50, h * 1.05);
    path.cubicTo(w * 0.34, h * 1.05, w * 0.22, h * 0.98, w * 0.16, h * 0.86);
    path.lineTo(w * 0.30, h * 0.76);
    path.cubicTo(w * 0.34, h * 0.83, w * 0.41, h * 0.88, w * 0.50, h * 0.88);
    path.cubicTo(w * 0.58, h * 0.88, w * 0.64, h * 0.82, w * 0.64, h * 0.76);
    path.cubicTo(w * 0.64, h * 0.68, w * 0.52, h * 0.63, w * 0.36, h * 0.58);
    path.cubicTo(w * 0.20, h * 0.53, w * 0.06, h * 0.44, w * 0.06, h * 0.28);
    path.cubicTo(w * 0.06, h * 0.14, w * 0.22, 0.0, w * 0.46, 0.0);
    path.cubicTo(w * 0.64, 0.0, w * 0.78, 0.08, w * 0.86, 0.18);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LoginLogoWidget extends StatelessWidget {
  final double size;
  final double iconSize;
  final Widget? customLogo;

  const LoginLogoWidget({
    super.key,
    this.size = 80.0,
    this.iconSize = 38.0,
    this.customLogo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 24,
            spreadRadius: 2,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.2,
        ),
      ),
      child: Center(
        child: customLogo ??
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: CustomPaint(
                painter: const ShiftExLogoPainter(
                  color: AppColors.darkNavy,
                ),
                child: Center(
                  child: Text(
                    'S',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: iconSize * 0.75,
                      fontWeight: FontWeight.w900,
                      color: AppColors.pureWhite,
                      letterSpacing: -1.0,
                    ),
                  ),
                ),
              ),
            ),
      ),
    );
  }
}
