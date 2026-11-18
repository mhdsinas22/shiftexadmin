import 'package:get_it/get_it.dart';
import 'package:shiftexadmin/features/settings/admin_access/data/datasources/admin_access_remote_datasource.dart';
import 'package:shiftexadmin/features/settings/admin_access/data/datasources/admin_access_remote_datasource_impl.dart';
import 'package:shiftexadmin/features/settings/admin_access/data/repositories/admin_access_repository_impl.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/repositories/admin_access_repository.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/usecases/create_admin_account_usecase.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/usecases/get_admin_access_overview_usecase.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/usecases/update_admin_operator_permissions_usecase.dart';
import 'package:shiftexadmin/features/settings/admin_access/presentation/bloc/admin_access_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void initAdminAccessDependencies(GetIt sl) {
  if (!sl.isRegistered<AdminAccessRemoteDataSource>()) {
    sl.registerLazySingleton<AdminAccessRemoteDataSource>(
      () => AdminAccessRemoteDataSourceImpl(
        supabaseClient: sl<SupabaseClient>(),
      ),
    );
  }

  if (!sl.isRegistered<AdminAccessRepository>()) {
    sl.registerLazySingleton<AdminAccessRepository>(
      () => AdminAccessRepositoryImpl(
        remoteDataSource: sl<AdminAccessRemoteDataSource>(),
      ),
    );
  }

  if (!sl.isRegistered<GetAdminAccessOverviewUseCase>()) {
    sl.registerLazySingleton<GetAdminAccessOverviewUseCase>(
      () => GetAdminAccessOverviewUseCase(sl<AdminAccessRepository>()),
    );
  }

  if (!sl.isRegistered<CreateAdminAccountUseCase>()) {
    sl.registerLazySingleton<CreateAdminAccountUseCase>(
      () => CreateAdminAccountUseCase(sl<AdminAccessRepository>()),
    );
  }

  if (!sl.isRegistered<UpdateAdminOperatorPermissionsUseCase>()) {
    sl.registerLazySingleton<UpdateAdminOperatorPermissionsUseCase>(
      () => UpdateAdminOperatorPermissionsUseCase(sl<AdminAccessRepository>()),
    );
  }

  if (!sl.isRegistered<AdminAccessBloc>()) {
    sl.registerFactory<AdminAccessBloc>(
      () => AdminAccessBloc(
        getAdminAccessOverviewUseCase: sl<GetAdminAccessOverviewUseCase>(),
        createAdminAccountUseCase: sl<CreateAdminAccountUseCase>(),
        updateAdminOperatorPermissionsUseCase:
            sl<UpdateAdminOperatorPermissionsUseCase>(),
      ),
    );
  }
}
