import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/core/routes/route_names.dart';
import 'package:shiftexadmin/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:shiftexadmin/features/authentication/presentation/bloc/authentication_event.dart';
import 'package:shiftexadmin/features/authentication/presentation/bloc/authentication_state.dart';
import 'package:shiftexadmin/features/authentication/presentation/widgets/login_button_widget.dart';
import 'package:shiftexadmin/features/authentication/presentation/widgets/login_card_widget.dart';
import 'package:shiftexadmin/features/authentication/presentation/widgets/login_input_field_widget.dart';
import 'package:shiftexadmin/features/authentication/presentation/widgets/login_remember_forgot_widget.dart';

class LoginFormWidget extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final VoidCallback? onForgotPasswordPressed;

  const LoginFormWidget({
    super.key,
    this.onLoginSuccess,
    this.onForgotPasswordPressed,
  });

  @override
  LoginFormWidgetState createState() => LoginFormWidgetState();
}

class LoginFormWidgetState extends State<LoginFormWidget> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  bool isPasswordVisible = false;
  bool rememberMe = true;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void togglePasswordVisibility() {
    setState(() {
      isPasswordVisible = !isPasswordVisible;
    });
  }

  void onRememberMeChanged(bool value) {
    setState(() {
      rememberMe = value;
    });
  }

  void submitLogin() {
    if (formKey.currentState?.validate() ?? false) {
      final email = emailController.text.trim();
      final password = passwordController.text;
      context.read<AuthenticationBloc>().add(
        LoginEvent(email: email, password: password),
      );
    }
  }

  void showForgotPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.darkNavy),
              SizedBox(width: 8),
              Text(
                'Reset Password',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: const Text(
            'To reset your admin password or request new credentials, please contact the super administrator or system engineering team.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Dismiss',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkNavy,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {
        if (state.status == AuthenticationStatus.authenticated) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.eifGreen,
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.pureWhite),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Admin authenticated successfully!',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        color: AppColors.pureWhite,
                      ),
                    ),
                  ),
                ],
              ),
              duration: Duration(seconds: 2),
            ),
          );

          if (widget.onLoginSuccess != null) {
            widget.onLoginSuccess!();
          } else {
            context.go(RouteNames.dashboardRoute);
          }
        } else if (state.errorMessage.isNotEmpty &&
            (state.status == AuthenticationStatus.unauthenticated ||
                state.status == AuthenticationStatus.error)) {
          final cleanError = state.errorMessage.replaceFirst(
            RegExp(r'^Exception:\s*'),
            '',
          );
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.purered,
              content: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.pureWhite,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      cleanError,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        color: AppColors.pureWhite,
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.status == AuthenticationStatus.loading;

        return LoginCardWidget(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                LoginInputFieldWidget(
                  label: 'Email or Admin ID',
                  hintText: 'Enter your email or admin ID',
                  prefixIcon: Icons.mail_outline_rounded,
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email or admin ID';
                    }
                    if (value.contains('@') &&
                        !RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                LoginInputFieldWidget(
                  label: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: !isPasswordVisible,
                  controller: passwordController,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                  enabled: !isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.textHint,
                    ),
                    onPressed: isLoading ? null : togglePasswordVisibility,
                    splashRadius: 20,
                  ),
                ),
                const SizedBox(height: 18),
                LoginRememberForgotWidget(
                  rememberMe: rememberMe,
                  onRememberMeChanged: isLoading ? null : onRememberMeChanged,
                  onForgotPasswordPressed: isLoading
                      ? null
                      : (widget.onForgotPasswordPressed ??
                            () => showForgotPasswordDialog(context)),
                ),
                const SizedBox(height: 24),
                LoginButtonWidget(
                  onPressed: isLoading ? null : submitLogin,
                  isLoading: isLoading,
                  text: 'Login',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
