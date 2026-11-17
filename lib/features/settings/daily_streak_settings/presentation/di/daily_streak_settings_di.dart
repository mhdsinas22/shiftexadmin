import 'package:get_it/get_it.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/data/datasources/daily_streak_settings_remote_datasource.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/data/datasources/daily_streak_settings_remote_datasource_impl.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/data/repositories/daily_streak_settings_repository_impl.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/repositories/daily_streak_settings_repository.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/usecases/get_daily_streak_audit_logs_usecase.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/usecases/get_daily_streak_settings_usecase.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/usecases/get_daily_streak_statistics_usecase.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/usecases/update_daily_streak_settings_usecase.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/presentation/bloc/daily_streak_settings_bloc.dart';

void initDailyStreakSettingsDependencies(GetIt sl) {
  // Data Source
  if (!sl.isRegistered<DailyStreakSettingsRemoteDataSource>()) {
    sl.registerLazySingleton<DailyStreakSettingsRemoteDataSource>(
      () => DailyStreakSettingsRemoteDataSourceImpl(supabaseClient: sl()),
    );
  }

  // Repository
  if (!sl.isRegistered<DailyStreakSettingsRepository>()) {
    sl.registerLazySingleton<DailyStreakSettingsRepository>(
      () => DailyStreakSettingsRepositoryImpl(remoteDataSource: sl()),
    );
  }

  // Use Cases
  if (!sl.isRegistered<GetDailyStreakSettingsUseCase>()) {
    sl.registerLazySingleton(
      () => GetDailyStreakSettingsUseCase(repository: sl()),
    );
  }
  if (!sl.isRegistered<UpdateDailyStreakSettingsUseCase>()) {
    sl.registerLazySingleton(
      () => UpdateDailyStreakSettingsUseCase(repository: sl()),
    );
  }
  if (!sl.isRegistered<GetDailyStreakStatisticsUseCase>()) {
    sl.registerLazySingleton(
      () => GetDailyStreakStatisticsUseCase(repository: sl()),
    );
  }
  if (!sl.isRegistered<GetDailyStreakAuditLogsUseCase>()) {
    sl.registerLazySingleton(
      () => GetDailyStreakAuditLogsUseCase(repository: sl()),
    );
  }

  // BLoC
  if (!sl.isRegistered<DailyStreakSettingsBloc>()) {
    sl.registerFactory(
      () => DailyStreakSettingsBloc(
        getDailyStreakSettingsUseCase: sl(),
        updateDailyStreakSettingsUseCase: sl(),
        getDailyStreakStatisticsUseCase: sl(),
        getDailyStreakAuditLogsUseCase: sl(),
      ),
    );
  }
}
