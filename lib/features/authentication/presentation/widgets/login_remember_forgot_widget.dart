import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/core/constants/app_texts.dart';
import 'package:shiftexadmin/features/authentication/presentation/widgets/login_checkbox_widget.dart';

class LoginRememberForgotWidget extends StatelessWidget {
  final bool rememberMe;
  final ValueChanged<bool>? onRememberMeChanged;
  final VoidCallback? onForgotPasswordPressed;

  const LoginRememberForgotWidget({
    super.key,
    required this.rememberMe,
    this.onRememberMeChanged,
    this.onForgotPasswordPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (onRememberMeChanged != null) {
              onRememberMeChanged!(!rememberMe);
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              LoginCheckboxWidget(
                value: rememberMe,
                onChanged: onRememberMeChanged,
              ),
              const SizedBox(width: 8),
              AppTexts.medium(
                'Remember me',
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
