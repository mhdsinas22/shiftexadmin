import 'package:get_it/get_it.dart';
import 'package:shiftexadmin/features/user_management/data/datasources/user_management_remote_datasource.dart';
import 'package:shiftexadmin/features/user_management/data/datasources/user_management_remote_datasource_impl.dart';
import 'package:shiftexadmin/features/user_management/data/repositories/user_management_repository_impl.dart';
import 'package:shiftexadmin/features/user_management/domain/repositories/user_management_repository.dart';
import 'package:shiftexadmin/features/user_management/domain/usecases/approve_customer_usecase.dart';
import 'package:shiftexadmin/features/user_management/domain/usecases/get_customer_details_usecase.dart';
import 'package:shiftexadmin/features/user_management/domain/usecases/get_customers_usecase.dart';
import 'package:shiftexadmin/features/user_management/domain/usecases/get_top_earners_usecase.dart';
import 'package:shiftexadmin/features/user_management/domain/usecases/get_user_statistics_usecase.dart';
import 'package:shiftexadmin/features/user_management/domain/usecases/reject_customer_usecase.dart';
import 'package:shiftexadmin/features/user_management/presentation/bloc/user_management_bloc.dart';

void initUserManagementDependencies(GetIt sl) {
  // BLoC
  if (!sl.isRegistered<UserManagementBloc>()) {
    sl.registerFactory<UserManagementBloc>(
      () => UserManagementBloc(
        getCustomersUseCase: sl<GetCustomersUseCase>(),
        getUserStatisticsUseCase: sl<GetUserStatisticsUseCase>(),
        approveCustomerUseCase: sl<ApproveCustomerUseCase>(),
        rejectCustomerUseCase: sl<RejectCustomerUseCase>(),
        getCustomerDetailsUseCase: sl<GetCustomerDetailsUseCase>(),
        getTopEarnersUseCase: sl<GetTopEarnersUseCase>(),
      ),
    );
  }

  // Use cases
  if (!sl.isRegistered<GetCustomersUseCase>()) {
    sl.registerLazySingleton<GetCustomersUseCase>(
      () => GetCustomersUseCase(repository: sl<UserManagementRepository>()),
    );
  }

  if (!sl.isRegistered<GetTopEarnersUseCase>()) {
    sl.registerLazySingleton<GetTopEarnersUseCase>(
      () => GetTopEarnersUseCase(repository: sl<UserManagementRepository>()),
    );
  }

  if (!sl.isRegistered<GetUserStatisticsUseCase>()) {
    sl.registerLazySingleton<GetUserStatisticsUseCase>(
      () => GetUserStatisticsUseCase(repository: sl<UserManagementRepository>()),
    );
  }

  if (!sl.isRegistered<ApproveCustomerUseCase>()) {
    sl.registerLazySingleton<ApproveCustomerUseCase>(
      () => ApproveCustomerUseCase(repository: sl<UserManagementRepository>()),
    );
  }

  if (!sl.isRegistered<RejectCustomerUseCase>()) {
    sl.registerLazySingleton<RejectCustomerUseCase>(
      () => RejectCustomerUseCase(repository: sl<UserManagementRepository>()),
    );
  }

  if (!sl.isRegistered<GetCustomerDetailsUseCase>()) {
    sl.registerLazySingleton<GetCustomerDetailsUseCase>(
      () => GetCustomerDetailsUseCase(repository: sl<UserManagementRepository>()),
    );
  }

  // Repository
  if (!sl.isRegistered<UserManagementRepository>()) {
    sl.registerLazySingleton<UserManagementRepository>(
      () => UserManagementRepositoryImpl(
        remoteDatasource: sl<UserManagementRemoteDatasource>(),
      ),
    );
  }

  // Remote Datasource
  if (!sl.isRegistered<UserManagementRemoteDatasource>()) {
    sl.registerLazySingleton<UserManagementRemoteDatasource>(
      () => UserManagementRemoteDatasourceImpl(
        supabaseClient: sl(),
      ),
    );
  }
}
