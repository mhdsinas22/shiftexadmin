import 'package:shiftexadmin/features/user_management/domain/repositories/user_management_repository.dart';

class RejectCustomerUseCase {
  final UserManagementRepository repository;

  const RejectCustomerUseCase({required this.repository});

  Future<void> execute(String customerId, String reason) {
    return repository.rejectCustomer(customerId, reason);
  }
}
