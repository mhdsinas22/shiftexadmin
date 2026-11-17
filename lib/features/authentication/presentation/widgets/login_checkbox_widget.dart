import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';

class LoginCheckboxWidget extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final double size;

  const LoginCheckboxWidget({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onChanged != null) {
          onChanged!(!value);
        }
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: value ? AppColors.darkNavy : AppColors.pureWhite,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: value ? AppColors.darkNavy : const Color(0xFFCBD5E1),
            width: 1.5,
          ),
        ),
        child: value
            ? const Center(
                child: Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: AppColors.pureWhite,
                ),
              )
            : null,
      ),
    );
  }
}
