import 'package:shiftexadmin/features/dashboard/domain/entities/dashboard_overview_entity.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/master_ledger_entry_entity.dart';
import 'package:shiftexadmin/features/dashboard/domain/repositories/dashboard_repository.dart';

class GetDashboardOverviewUseCase {
  final DashboardRepository repository;

  const GetDashboardOverviewUseCase(this.repository);

  Future<DashboardOverviewEntity> call({
    LedgerCategoryFilter ledgerCategory = LedgerCategoryFilter.all,
  }) {
    return repository.getDashboardOverview(ledgerCategory: ledgerCategory);
  }
}
