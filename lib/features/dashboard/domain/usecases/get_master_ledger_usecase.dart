import 'package:shiftexadmin/features/dashboard/domain/entities/master_ledger_entry_entity.dart';
import 'package:shiftexadmin/features/dashboard/domain/repositories/dashboard_repository.dart';

class GetMasterLedgerUseCase {
  final DashboardRepository repository;

  const GetMasterLedgerUseCase(this.repository);

  Future<List<MasterLedgerEntryEntity>> call({
    LedgerCategoryFilter category = LedgerCategoryFilter.all,
    String searchQuery = '',
    int limit = 15,
    int offset = 0,
  }) {
    return repository.getMasterLedger(
      category: category,
      searchQuery: searchQuery,
      limit: limit,
      offset: offset,
    );
  }
}
