import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/core/di/injection_container.dart';
import 'package:shiftexadmin/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:shiftexadmin/features/authentication/presentation/widgets/login_form_widget.dart';
import 'package:shiftexadmin/features/authentication/presentation/widgets/login_header_widget.dart';
import 'package:shiftexadmin/features/authentication/presentation/widgets/login_logo_widget.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthenticationBloc>(
      create: (_) => getIt<AuthenticationBloc>(),
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 20),
                    LoginLogoWidget(),
                    SizedBox(height: 24),
                    LoginHeaderWidget(),
                    SizedBox(height: 32),
                    LoginFormWidget(),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
