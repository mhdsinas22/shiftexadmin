import 'package:shiftexadmin/features/user_management/domain/entities/customer_entity.dart';
import 'package:shiftexadmin/features/user_management/domain/repositories/user_management_repository.dart';

class CreateCustomerUseCase {
  final UserManagementRepository repository;

  static final RegExp emailRegex = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  const CreateCustomerUseCase({required this.repository});

  static bool isStrongPassword(String password) {
    if (password.length < 8 || password.length > 128) return false;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasLower = RegExp(r'[a-z]').hasMatch(password);
    final hasNumberOrSymbol = RegExp(
      r'[0-9!@#$%^&*(),.?":{}|<>\-_=+\[\]\\\/~`]',
    ).hasMatch(password);
    return hasUpper && hasLower && hasNumberOrSymbol;
  }

  static String normalizeMobile(String raw) {
    final cleaned = raw.trim().replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.isEmpty) return '';
    if (cleaned.startsWith('+')) return cleaned;
    if (cleaned.length == 10) return '+91$cleaned';
    if (cleaned.length == 12 && cleaned.startsWith('91')) {
      return '+$cleaned';
    }
    return '+$cleaned';
  }

  Future<CustomerEntity> execute({
    required String fullName,
    required String email,
    required String mobileNumber,
    required String password,
    required String confirmPassword,
    String approvalStatus = 'approved',
    String membershipTier = 'Pebble Black Member',
    int initialPoints = 0,
  }) {
    final cleanName = fullName.trim();
    final cleanEmail = email.trim().toLowerCase();
    final normalizedMobile = normalizeMobile(mobileNumber);
    final digitsOnly = normalizedMobile.replaceAll(RegExp(r'[^0-9]'), '');
    final cleanStatus = approvalStatus.trim().toLowerCase();
    final cleanTier = membershipTier.trim().isNotEmpty
        ? membershipTier.trim()
        : 'Pebble Black Member';

    if (cleanName.length < 2 || cleanName.length > 100) {
      throw ArgumentError('Full name must be between 2 and 100 characters.');
    }
    if (!emailRegex.hasMatch(cleanEmail)) {
      throw ArgumentError('Please enter a valid customer email address.');
    }
    if (digitsOnly.length < 10 || digitsOnly.length > 15) {
      throw ArgumentError(
        'Please enter a valid 10 to 15 digit mobile number.',
      );
    }
    if (!isStrongPassword(password)) {
      throw ArgumentError(
        'Password must be at least 8 characters with uppercase, lowercase, and a number or symbol.',
      );
    }
    if (password != confirmPassword) {
      throw ArgumentError('Password and Confirm Password do not match.');
    }
    if (cleanStatus != 'approved' && cleanStatus != 'pending') {
      throw ArgumentError('Initial approval status must be approved or pending.');
    }
    if (initialPoints < 0 || initialPoints > 100000) {
      throw ArgumentError('Initial points must be between 0 and 100,000.');
    }

    return repository.createCustomer(
      fullName: cleanName,
      email: cleanEmail,
      mobileNumber: normalizedMobile,
      password: password,
      approvalStatus: cleanStatus,
      membershipTier: cleanTier,
      initialPoints: initialPoints,
    );
  }
}
