import 'package:shiftexadmin/features/user_management/domain/entities/user_statistics_entity.dart';
import 'package:shiftexadmin/features/user_management/domain/repositories/user_management_repository.dart';

class GetUserStatisticsUseCase {
  final UserManagementRepository repository;

  const GetUserStatisticsUseCase({required this.repository});

  Future<UserStatisticsEntity> execute() {
    return repository.getUserStatistics();
  }
}
