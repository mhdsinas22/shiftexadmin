import 'package:shiftexadmin/features/user_management/domain/entities/customer_entity.dart';
import 'package:shiftexadmin/features/user_management/domain/entities/user_statistics_entity.dart';

abstract class UserManagementRepository {
  Future<List<CustomerEntity>> getCustomers({
    String? status,
    String? searchQuery,
    String? sortBy,
    int limit = 50,
    int offset = 0,
  });

  Future<UserStatisticsEntity> getUserStatistics();

  Future<CustomerEntity> getCustomerDetails(String customerId);

  Future<void> approveCustomer(String customerId);

  Future<void> rejectCustomer(String customerId, String reason);
}
