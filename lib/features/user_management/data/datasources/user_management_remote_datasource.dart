import 'package:shiftexadmin/features/user_management/data/models/customer_model.dart';
import 'package:shiftexadmin/features/user_management/data/models/user_statistics_model.dart';

abstract class UserManagementRemoteDatasource {
  Future<List<CustomerModel>> getCustomers({
    String? status,
    String? searchQuery,
    String? sortBy,
    int limit = 50,
    int offset = 0,
  });

  Future<UserStatisticsModel> getUserStatistics();

  Future<CustomerModel> getCustomerDetails(String customerId);

  Future<void> approveCustomer(String customerId);

  Future<void> rejectCustomer(String customerId, String reason);
}
