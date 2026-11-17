import 'package:shiftexadmin/features/user_management/domain/repositories/user_management_repository.dart';

class ApproveCustomerUseCase {
  final UserManagementRepository repository;

  const ApproveCustomerUseCase({required this.repository});

  Future<void> execute(String customerId) {
    return repository.approveCustomer(customerId);
  }
}
