import 'package:shiftexadmin/features/user_management/domain/entities/customer_entity.dart';
import 'package:shiftexadmin/features/user_management/domain/repositories/user_management_repository.dart';

class GetCustomerDetailsUseCase {
  final UserManagementRepository repository;

  const GetCustomerDetailsUseCase({required this.repository});

  Future<CustomerEntity> execute(String customerId) {
    return repository.getCustomerDetails(customerId);
  }
}
