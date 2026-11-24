import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/features/user_management/domain/usecases/create_customer_usecase.dart';
import 'package:shiftexadmin/features/user_management/presentation/bloc/user_management_bloc.dart';
import 'package:shiftexadmin/features/user_management/presentation/bloc/user_management_event.dart';
import 'package:shiftexadmin/features/user_management/presentation/bloc/user_management_state.dart';

class CreateCustomerSheetWidget extends StatefulWidget {
  final UserManagementBloc bloc;

  const CreateCustomerSheetWidget({super.key, required this.bloc});

  static Future<void> show(
    BuildContext context, {
    required UserManagementBloc bloc,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider<UserManagementBloc>.value(
        value: bloc,
        child: CreateCustomerSheetWidget(bloc: bloc),
      ),
    );
  }

  @override
  State<CreateCustomerSheetWidget> createState() =>
      _CreateCustomerSheetWidgetState();
}

class _CreateCustomerSheetWidgetState extends State<CreateCustomerSheetWidget> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _initialPointsController = TextEditingController(
    text: '0',
  );

  String _approvalStatus = 'approved';
  String _membershipTier = 'Pebble Black Member';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _validationError;

  static const List<String> _tiers = [
    'Pebble Black Member',
    'Gold Tier',
    'Elite Tier',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _initialPointsController.dispose();
    super.dispose();
  }

  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUpper => RegExp(r'[A-Z]').hasMatch(_passwordController.text);
  bool get _hasLower => RegExp(r'[a-z]').hasMatch(_passwordController.text);
  bool get _hasDigitOrSymbol => RegExp(
    r'[0-9!@#$%^&*(),.?":{}|<>\-_=+\[\]\\\/~`]',
  ).hasMatch(_passwordController.text);

  void _submit() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final mobile = CreateCustomerUseCase.normalizeMobile(
      _mobileController.text,
    );
    final digitsOnly = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final initialPts = int.tryParse(_initialPointsController.text.trim()) ?? 0;

    if (name.length < 2) {
      setState(() {
        _validationError = 'Please enter the customer\'s full name.';
      });
      return;
    }

    if (!CreateCustomerUseCase.emailRegex.hasMatch(email)) {
      setState(() {
        _validationError = 'Please enter a valid customer email address.';
      });
      return;
    }

    if (digitsOnly.length < 10 || digitsOnly.length > 15) {
      setState(() {
        _validationError =
            'Please enter a valid 10 to 15 digit mobile number.';
      });
      return;
    }

    if (!CreateCustomerUseCase.isStrongPassword(password)) {
      setState(() {
        _validationError =
            'Password must be at least 8 characters and include uppercase, lowercase, and a number or symbol.';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _validationError = 'Password and Confirm Password do not match.';
      });
      return;
    }

    if (initialPts < 0 || initialPts > 100000) {
      setState(() {
        _validationError =
            'Initial welcome points must be between 0 and 100,000.';
      });
      return;
    }

    setState(() {
      _validationError = null;
    });

    widget.bloc.add(
      CreateCustomerRequested(
        fullName: name,
        email: email,
        mobileNumber: mobile,
        password: password,
        confirmPassword: confirmPassword,
        approvalStatus: _approvalStatus,
        membershipTier: _membershipTier,
        initialPoints: initialPts,
      ),
    );
  }

  Widget _buildStrengthRule(String label, bool satisfied) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: satisfied ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            satisfied
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 12,
            color: satisfied
                ? const Color(0xFF15803D)
                : const Color(0xFF64748B),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: satisfied
                  ? const Color(0xFF15803D)
                  : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        color: AppColors.textHint,
      ),
      prefixIcon: Icon(prefixIcon, size: 18, color: AppColors.textSecondary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.linkBlue, width: 1.4),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocConsumer<UserManagementBloc, UserManagementState>(
      listenWhen: (previous, current) =>
          previous.status == UserManagementStatus.creating &&
          current.status != UserManagementStatus.creating,
      listener: (context, state) {
        if (state.status == UserManagementStatus.loaded &&
            state.successMessage != null &&
            state.successMessage!.isNotEmpty) {
          Navigator.of(context).pop();
        } else if (state.status == UserManagementStatus.error &&
            state.errorMessage.isNotEmpty) {
          setState(() {
            _validationError = state.errorMessage;
          });
        }
      },
      builder: (context, state) {
        final isSubmitting = state.status == UserManagementStatus.creating;

        return Container(
          margin: const EdgeInsets.only(top: 44),
          padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottomInset),
          decoration: const BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Customer Account',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Create a member profile & activate their points wallet immediately',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Full Name
                _fieldLabel('Full Name'),
                TextField(
                  key: const Key('add_customer_name_input'),
                  controller: _nameController,
                  enabled: !isSubmitting,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() => _validationError = null),
                  decoration: _inputDecoration(
                    hint: 'e.g. Ananya Krishnan',
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                ),
                const SizedBox(height: 12),

                // Email Address
                _fieldLabel('Email Address'),
                TextField(
                  key: const Key('add_customer_email_input'),
                  controller: _emailController,
                  enabled: !isSubmitting,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  onChanged: (_) => setState(() => _validationError = null),
                  decoration: _inputDecoration(
                    hint: 'e.g. ananya@example.com',
                    prefixIcon: Icons.mail_outline_rounded,
                  ),
                ),
                const SizedBox(height: 12),

                // Mobile Number
                _fieldLabel('Mobile Number'),
                TextField(
                  key: const Key('add_customer_mobile_input'),
                  controller: _mobileController,
                  enabled: !isSubmitting,
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => setState(() => _validationError = null),
                  decoration: _inputDecoration(
                    hint: 'e.g. +91 98765 43210',
                    prefixIcon: Icons.phone_outlined,
                  ),
                ),
                const SizedBox(height: 12),

                // Password
                _fieldLabel('Password'),
                TextField(
                  key: const Key('add_customer_password_input'),
                  controller: _passwordController,
                  enabled: !isSubmitting,
                  obscureText: _obscurePassword,
                  onChanged: (_) => setState(() => _validationError = null),
                  decoration: _inputDecoration(
                    hint: 'Min 8 chars, upper, lower & number/symbol',
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildStrengthRule('8+ chars', _hasMinLength),
                    _buildStrengthRule('Uppercase', _hasUpper),
                    _buildStrengthRule('Lowercase', _hasLower),
                    _buildStrengthRule('Number / Symbol', _hasDigitOrSymbol),
                  ],
                ),
                const SizedBox(height: 12),

                // Confirm Password
                _fieldLabel('Confirm Password'),
                TextField(
                  key: const Key('add_customer_confirm_password_input'),
                  controller: _confirmPasswordController,
                  enabled: !isSubmitting,
                  obscureText: _obscureConfirmPassword,
                  onChanged: (_) => setState(() => _validationError = null),
                  decoration: _inputDecoration(
                    hint: 'Re-enter password',
                    prefixIcon: Icons.verified_user_outlined,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        );
                      },
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Initial Approval Status
                _fieldLabel('Initial Account Status'),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        key: const Key('add_customer_status_approved'),
                        onTap: isSubmitting
                            ? null
                            : () => setState(() {
                                _approvalStatus = 'approved';
                                _validationError = null;
                              }),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _approvalStatus == 'approved'
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _approvalStatus == 'approved'
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                size: 15,
                                color: _approvalStatus == 'approved'
                                    ? AppColors.pureWhite
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Approved & Active',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _approvalStatus == 'approved'
                                        ? AppColors.pureWhite
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        key: const Key('add_customer_status_pending'),
                        onTap: isSubmitting
                            ? null
                            : () => setState(() {
                                _approvalStatus = 'pending';
                                _validationError = null;
                              }),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _approvalStatus == 'pending'
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _approvalStatus == 'pending'
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.hourglass_top_rounded,
                                size: 15,
                                color: _approvalStatus == 'pending'
                                    ? AppColors.pureWhite
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Pending KYC',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _approvalStatus == 'pending'
                                        ? AppColors.pureWhite
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Membership Tier
                _fieldLabel('Membership Tier'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tiers.map((tier) {
                    final selected = _membershipTier == tier;
                    return InkWell(
                      onTap: isSubmitting
                          ? null
                          : () => setState(() {
                              _membershipTier = tier;
                              _validationError = null;
                            }),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? AppColors.linkBlue
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          tier,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? AppColors.linkBlue
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Optional Initial Welcome Points (Points-only, zero currency)
                _fieldLabel('Initial Welcome Points (Optional)'),
                TextField(
                  key: const Key('add_customer_initial_points_input'),
                  controller: _initialPointsController,
                  enabled: !isSubmitting,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: (_) => setState(() => _validationError = null),
                  decoration: _inputDecoration(
                    hint: '0',
                    prefixIcon: Icons.stars_rounded,
                    suffixIcon: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'pts',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                if (_validationError != null &&
                    _validationError!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 16,
                          color: AppColors.purered,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _validationError!,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.purered,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    key: const Key('submit_create_customer_button'),
                    onPressed: isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: AppColors.pureWhite,
                      disabledBackgroundColor: const Color(0xFF94A3B8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.pureWhite,
                            ),
                          )
                        : const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: Text(
                      isSubmitting
                          ? 'Creating Account...'
                          : 'Create Customer Account',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
