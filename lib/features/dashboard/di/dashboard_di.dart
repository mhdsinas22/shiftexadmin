import 'package:get_it/get_it.dart';
import 'package:shiftexadmin/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:shiftexadmin/features/dashboard/data/datasources/dashboard_remote_datasource_impl.dart';
import 'package:shiftexadmin/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:shiftexadmin/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:shiftexadmin/features/dashboard/domain/usecases/get_dashboard_overview_usecase.dart';
import 'package:shiftexadmin/features/dashboard/domain/usecases/get_master_ledger_usecase.dart';
import 'package:shiftexadmin/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/usecases/get_points_to_cash_config_usecase.dart';
import 'package:shiftexadmin/features/user_management/domain/usecases/approve_customer_usecase.dart';
import 'package:shiftexadmin/features/user_management/domain/usecases/reject_customer_usecase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void initDashboardDi(GetIt sl) {
  if (!sl.isRegistered<DashboardRemoteDataSource>()) {
    sl.registerLazySingleton<DashboardRemoteDataSource>(
      () => DashboardRemoteDataSourceImpl(
        supabaseClient: sl<SupabaseClient>(),
      ),
    );
  }

  if (!sl.isRegistered<DashboardRepository>()) {
    sl.registerLazySingleton<DashboardRepository>(
      () => DashboardRepositoryImpl(
        remoteDataSource: sl<DashboardRemoteDataSource>(),
      ),
    );
  }

  if (!sl.isRegistered<GetDashboardOverviewUseCase>()) {
    sl.registerLazySingleton<GetDashboardOverviewUseCase>(
      () => GetDashboardOverviewUseCase(sl<DashboardRepository>()),
    );
  }

  if (!sl.isRegistered<GetMasterLedgerUseCase>()) {
    sl.registerLazySingleton<GetMasterLedgerUseCase>(
      () => GetMasterLedgerUseCase(sl<DashboardRepository>()),
    );
  }

  if (!sl.isRegistered<DashboardBloc>()) {
    sl.registerFactory<DashboardBloc>(
      () => DashboardBloc(
        getDashboardOverviewUseCase: sl<GetDashboardOverviewUseCase>(),
        getMasterLedgerUseCase: sl<GetMasterLedgerUseCase>(),
        approveCustomerUseCase: sl<ApproveCustomerUseCase>(),
        rejectCustomerUseCase: sl.isRegistered<RejectCustomerUseCase>()
            ? sl<RejectCustomerUseCase>()
            : null,
        getPointsToCashConfigUseCase:
            sl.isRegistered<GetPointsToCashConfigUseCase>()
            ? sl<GetPointsToCashConfigUseCase>()
            : null,
      ),
    );
  }
}
