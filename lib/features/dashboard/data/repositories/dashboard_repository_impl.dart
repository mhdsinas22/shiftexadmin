import 'package:shiftexadmin/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/dashboard_overview_entity.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/master_ledger_entry_entity.dart';
import 'package:shiftexadmin/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;

  const DashboardRepositoryImpl({required this.remoteDataSource});

  @override
  Future<DashboardOverviewEntity> getDashboardOverview({
    LedgerCategoryFilter ledgerCategory = LedgerCategoryFilter.all,
  }) {
    return remoteDataSource.getDashboardOverview(
      ledgerCategory: ledgerCategory,
    );
  }

  @override
  Future<List<MasterLedgerEntryEntity>> getMasterLedger({
    LedgerCategoryFilter category = LedgerCategoryFilter.all,
    String searchQuery = '',
    int limit = 15,
    int offset = 0,
  }) {
    return remoteDataSource.getMasterLedger(
      category: category,
      searchQuery: searchQuery,
      limit: limit,
      offset: offset,
    );
  }
}
