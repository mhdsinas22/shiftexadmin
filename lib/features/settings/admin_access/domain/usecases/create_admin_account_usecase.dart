import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_operator_entity.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_permission.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/repositories/admin_access_repository.dart';

class CreateAdminAccountUseCase {
  final AdminAccessRepository repository;

  const CreateAdminAccountUseCase(this.repository);

  static final RegExp emailRegex = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  static bool isStrongPassword(String password) {
    if (password.length < 8 || password.length > 128) return false;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasLower = RegExp(r'[a-z]').hasMatch(password);
    final hasDigitOrSymbol = RegExp(
      r'[0-9!@#$%^&*(),.?":{}|<>\-_=+\[\]\\\/~`]',
    ).hasMatch(password);
    return hasUpper && hasLower && hasDigitOrSymbol;
  }

  Future<AdminOperatorEntity> call({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    required AdminRoleType role,
    required String terminalAssignment,
    required List<String> permissions,
  }) {
    final cleanName = fullName.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanTerminal = terminalAssignment.trim().isNotEmpty
        ? terminalAssignment.trim()
        : role.defaultTerminal;

    if (cleanName.length < 2) {
      throw Exception('Full name must be at least 2 characters.');
    }
    if (!emailRegex.hasMatch(cleanEmail)) {
      throw Exception('Please enter a valid email address.');
    }
    if (!isStrongPassword(password)) {
      throw Exception(
        'Password must be at least 8 characters and include uppercase, lowercase, and a number or symbol.',
      );
    }
    if (password != confirmPassword) {
      throw Exception('Password and Confirm Password do not match.');
    }
    if (permissions.isEmpty) {
      throw Exception('Select at least one operational permission.');
    }

    return repository.createAdminAccount(
      fullName: cleanName,
      email: cleanEmail,
      password: password,
      role: role,
      terminalAssignment: cleanTerminal,
      permissions: permissions,
    );
  }
}
