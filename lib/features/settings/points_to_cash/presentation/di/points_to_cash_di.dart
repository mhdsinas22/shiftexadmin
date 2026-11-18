import 'package:get_it/get_it.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/data/datasources/points_to_cash_remote_datasource.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/data/datasources/points_to_cash_remote_datasource_impl.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/data/repositories/points_to_cash_repository_impl.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/repositories/points_to_cash_repository.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/usecases/get_points_to_cash_config_usecase.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/usecases/get_points_to_cash_history_usecase.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/usecases/update_points_to_cash_rate_usecase.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/presentation/bloc/points_to_cash_bloc.dart';

void initPointsToCashDependencies(GetIt sl) {
  if (!sl.isRegistered<PointsToCashRemoteDataSource>()) {
    sl.registerLazySingleton<PointsToCashRemoteDataSource>(
      () => PointsToCashRemoteDataSourceImpl(supabaseClient: sl()),
    );
  }

  if (!sl.isRegistered<PointsToCashRepository>()) {
    sl.registerLazySingleton<PointsToCashRepository>(
      () => PointsToCashRepositoryImpl(remoteDataSource: sl()),
    );
  }

  if (!sl.isRegistered<GetPointsToCashConfigUseCase>()) {
    sl.registerLazySingleton(
      () => GetPointsToCashConfigUseCase(repository: sl()),
    );
  }

  if (!sl.isRegistered<UpdatePointsToCashRateUseCase>()) {
    sl.registerLazySingleton(
      () => UpdatePointsToCashRateUseCase(repository: sl()),
    );
  }

  if (!sl.isRegistered<GetPointsToCashHistoryUseCase>()) {
    sl.registerLazySingleton(
      () => GetPointsToCashHistoryUseCase(repository: sl()),
    );
  }

  if (!sl.isRegistered<PointsToCashBloc>()) {
    sl.registerFactory(
      () => PointsToCashBloc(
        getPointsToCashConfigUseCase: sl(),
        updatePointsToCashRateUseCase: sl(),
        getPointsToCashHistoryUseCase: sl(),
      ),
    );
  }
}
