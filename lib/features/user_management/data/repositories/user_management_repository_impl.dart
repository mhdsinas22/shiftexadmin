import 'package:shiftexadmin/features/user_management/data/datasources/user_management_remote_datasource.dart';
import 'package:shiftexadmin/features/user_management/domain/entities/customer_entity.dart';
import 'package:shiftexadmin/features/user_management/domain/entities/user_statistics_entity.dart';
import 'package:shiftexadmin/features/user_management/domain/repositories/user_management_repository.dart';

class UserManagementRepositoryImpl implements UserManagementRepository {
  final UserManagementRemoteDatasource remoteDatasource;

  const UserManagementRepositoryImpl({required this.remoteDatasource});

  @override
  Future<List<CustomerEntity>> getCustomers({
    String? status,
    String? searchQuery,
    String? sortBy,
    int limit = 50,
    int offset = 0,
  }) {
    return remoteDatasource.getCustomers(
      status: status,
      searchQuery: searchQuery,
      sortBy: sortBy,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<UserStatisticsEntity> getUserStatistics() {
    return remoteDatasource.getUserStatistics();
  }

  @override
  Future<CustomerEntity> getCustomerDetails(String customerId) {
    return remoteDatasource.getCustomerDetails(customerId);
  }

  @override
  Future<void> approveCustomer(String customerId) {
    return remoteDatasource.approveCustomer(customerId);
  }

  @override
  Future<void> rejectCustomer(String customerId, String reason) {
    return remoteDatasource.rejectCustomer(customerId, reason);
  }
}
