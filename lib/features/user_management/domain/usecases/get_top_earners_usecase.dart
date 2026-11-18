import 'package:shiftexadmin/features/user_management/domain/entities/customer_entity.dart';
import 'package:shiftexadmin/features/user_management/domain/repositories/user_management_repository.dart';

class GetTopEarnersUseCase {
  final UserManagementRepository repository;

  const GetTopEarnersUseCase({required this.repository});

  Future<List<CustomerEntity>> execute({
    String range = 'weekly',
    int limit = 3,
  }) {
    return repository.getTopEarners(
      range: range,
      limit: limit,
    );
  }
}
