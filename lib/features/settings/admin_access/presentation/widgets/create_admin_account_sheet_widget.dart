import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_permission.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/usecases/create_admin_account_usecase.dart';
import 'package:shiftexadmin/features/settings/admin_access/presentation/bloc/admin_access_bloc.dart';
import 'package:shiftexadmin/features/settings/admin_access/presentation/bloc/admin_access_event.dart';
import 'package:shiftexadmin/features/settings/admin_access/presentation/bloc/admin_access_state.dart';

class CreateAdminAccountSheetWidget extends StatefulWidget {
  final AdminAccessBloc bloc;

  const CreateAdminAccountSheetWidget({super.key, required this.bloc});

  static Future<void> show(
    BuildContext context, {
    required AdminAccessBloc bloc,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider<AdminAccessBloc>.value(
        value: bloc,
        child: CreateAdminAccountSheetWidget(bloc: bloc),
      ),
    );
  }

  @override
  State<CreateAdminAccountSheetWidget> createState() =>
      _CreateAdminAccountSheetWidgetState();
}

class _CreateAdminAccountSheetWidgetState
    extends State<CreateAdminAccountSheetWidget> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _terminalController = TextEditingController(
    text: 'Term #02',
  );

  AdminRoleType _selectedRole = AdminRoleType.storeManager;
  late Set<String> _selectedPermissions;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _selectedPermissions = Set<String>.from(_selectedRole.defaultPermissions);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _terminalController.dispose();
    super.dispose();
  }

  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUpper => RegExp(r'[A-Z]').hasMatch(_passwordController.text);
  bool get _hasLower => RegExp(r'[a-z]').hasMatch(_passwordController.text);
  bool get _hasDigitOrSymbol => RegExp(
    r'[0-9!@#$%^&*(),.?":{}|<>\-_=+\[\]\\\/~`]',
  ).hasMatch(_passwordController.text);

  void _onRoleChanged(AdminRoleType role) {
    setState(() {
      _selectedRole = role;
      _terminalController.text = role.defaultTerminal;
      _selectedPermissions = Set<String>.from(role.defaultPermissions);
      _validationError = null;
    });
  }

  void _togglePermission(String permissionId) {
    setState(() {
      if (_selectedPermissions.contains(permissionId)) {
        _selectedPermissions.remove(permissionId);
      } else {
        _selectedPermissions.add(permissionId);
      }
      _validationError = null;
    });
  }

  void _submit() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final terminal = _terminalController.text.trim().isNotEmpty
        ? _terminalController.text.trim()
        : _selectedRole.defaultTerminal;

    if (name.length < 2) {
      setState(() {
        _validationError = 'Please enter the operator\'s full name.';
      });
      return;
    }

    if (!CreateAdminAccountUseCase.emailRegex.hasMatch(email)) {
      setState(() {
        _validationError = 'Please enter a valid work email address.';
      });
      return;
    }

    if (!CreateAdminAccountUseCase.isStrongPassword(password)) {
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

    if (_selectedPermissions.isEmpty) {
      setState(() {
        _validationError = 'Select at least one operational permission.';
      });
      return;
    }

    setState(() {
      _validationError = null;
    });

    widget.bloc.add(
      CreateAdminAccountRequested(
        fullName: name,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        role: _selectedRole,
        terminalAssignment: terminal,
        permissions: _selectedPermissions.toList(),
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocConsumer<AdminAccessBloc, AdminAccessState>(
      listenWhen: (previous, current) =>
          previous.status == AdminAccessStatus.submitting &&
          current.status != AdminAccessStatus.submitting,
      listener: (context, state) {
        if (state.status == AdminAccessStatus.loaded &&
            state.successMessage != null &&
            state.successMessage!.isNotEmpty) {
          Navigator.of(context).pop();
        } else if (state.status == AdminAccessStatus.error &&
            state.errorMessage.isNotEmpty) {
          setState(() {
            _validationError = state.errorMessage;
          });
        }
      },
      builder: (context, state) {
        final isSubmitting = state.status == AdminAccessStatus.submitting;

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
                            'Create Admin Account',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Directly provision a console operator for immediate login',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
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
                if (_validationError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Text(
                      _validationError!,
                      key: const Key('create_admin_validation_error'),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.purered,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const Text(
                  'Full Name',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('create_admin_name_input'),
                  controller: _nameController,
                  enabled: !isSubmitting,
                  decoration: InputDecoration(
                    hintText: 'e.g. Rahul Verma',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Email Address',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('create_admin_email_input'),
                  controller: _emailController,
                  enabled: !isSubmitting,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'operator@shiftex.vault',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Password',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('create_admin_password_input'),
                  controller: _passwordController,
                  enabled: !isSubmitting,
                  obscureText: _obscurePassword,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Minimum 8 characters',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    suffixIcon: IconButton(
                      key: const Key('toggle_admin_password_visibility'),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
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
                    _buildStrengthRule('Number/Symbol', _hasDigitOrSymbol),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Confirm Password',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('create_admin_confirm_password_input'),
                  controller: _confirmPasswordController,
                  enabled: !isSubmitting,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: 'Re-enter password',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    suffixIcon: IconButton(
                      key: const Key(
                        'toggle_admin_confirm_password_visibility',
                      ),
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Admin Role',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: AdminRoleType.values.map((role) {
                    final isSelected = role == _selectedRole;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: role == AdminRoleType.values.last ? 0 : 8,
                        ),
                        child: InkWell(
                          key: Key('create_admin_role_option_${role.dbValue}'),
                          onTap: isSubmitting
                              ? null
                              : () => _onRoleChanged(role),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF090D16)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF090D16)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              role.displayLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? AppColors.pureWhite
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Assigned Terminal / Branch',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('create_admin_terminal_input'),
                  controller: _terminalController,
                  enabled: !isSubmitting,
                  decoration: InputDecoration(
                    hintText: 'e.g. Term #02 or Read-only Ledger',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Permissions',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${_selectedPermissions.length} enabled',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.linkBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: AdminPermission.allPermissions.map((perm) {
                    final selected = _selectedPermissions.contains(perm);
                    return FilterChip(
                      label: Text(
                        AdminPermission.labelFor(perm),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? AppColors.pureWhite
                              : AppColors.textPrimary,
                        ),
                      ),
                      selected: selected,
                      selectedColor: AppColors.linkBlue,
                      checkmarkColor: AppColors.pureWhite,
                      backgroundColor: const Color(0xFFF1F5F9),
                      visualDensity: VisualDensity.compact,
                      onSelected: isSubmitting
                          ? null
                          : (_) => _togglePermission(perm),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    key: const Key('submit_create_admin_account_button'),
                    onPressed: isSubmitting ? null : _submit,
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
                          ? 'Creating Admin Account...'
                          : 'Create Admin Account',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF090D16),
                      foregroundColor: AppColors.pureWhite,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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
