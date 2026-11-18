import 'package:shiftexadmin/features/dashboard/data/models/dashboard_overview_model.dart';
import 'package:shiftexadmin/features/dashboard/data/models/master_ledger_entry_model.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/master_ledger_entry_entity.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardOverviewModel> getDashboardOverview({
    LedgerCategoryFilter ledgerCategory = LedgerCategoryFilter.all,
  });

  Future<List<MasterLedgerEntryModel>> getMasterLedger({
    LedgerCategoryFilter category = LedgerCategoryFilter.all,
    String searchQuery = '',
    int limit = 15,
    int offset = 0,
  });
}
