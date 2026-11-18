import 'package:shiftexadmin/features/dashboard/domain/entities/dashboard_overview_entity.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/master_ledger_entry_entity.dart';

abstract class DashboardRepository {
  Future<DashboardOverviewEntity> getDashboardOverview({
    LedgerCategoryFilter ledgerCategory = LedgerCategoryFilter.all,
  });

  Future<List<MasterLedgerEntryEntity>> getMasterLedger({
    LedgerCategoryFilter category = LedgerCategoryFilter.all,
    String searchQuery = '',
    int limit = 15,
    int offset = 0,
  });
}
