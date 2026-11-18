import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_access_overview_entity.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_operator_entity.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/repositories/admin_access_repository.dart';

class GetAdminAccessOverviewUseCase {
  final AdminAccessRepository repository;

  const GetAdminAccessOverviewUseCase(this.repository);

  Stream<AdminOperatorEntity?> get currentAdminStream =>
      repository.currentAdminStream;

  AdminOperatorEntity? get cachedCurrentAdmin => repository.cachedCurrentAdmin;

  Future<AdminAccessOverviewEntity> call() {
    return repository.getAdminAccessOverview();
  }
}
