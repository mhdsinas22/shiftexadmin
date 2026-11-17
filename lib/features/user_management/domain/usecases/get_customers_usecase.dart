import 'package:shiftexadmin/features/user_management/domain/entities/customer_entity.dart';
import 'package:shiftexadmin/features/user_management/domain/repositories/user_management_repository.dart';

class GetCustomersUseCase {
  final UserManagementRepository repository;

  const GetCustomersUseCase({required this.repository});

  Future<List<CustomerEntity>> execute({
    String? status,
    String? searchQuery,
    String? sortBy,
    int limit = 50,
    int offset = 0,
  }) {
    return repository.getCustomers(
      status: status,
      searchQuery: searchQuery,
      sortBy: sortBy,
      limit: limit,
      offset: offset,
    );
  }
}
