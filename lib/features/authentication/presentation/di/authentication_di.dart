import 'package:get_it/get_it.dart';
import 'package:shiftexadmin/features/authentication/data/datasoucre/authentication_remote_datasoucre.dart';
import 'package:shiftexadmin/features/authentication/data/datasoucre/authentication_remote_datasoucre_impl.dart';
import 'package:shiftexadmin/features/authentication/data/repositories/authentication_repository_impl.dart';
import 'package:shiftexadmin/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:shiftexadmin/features/authentication/domain/usecases/login.dart';
import 'package:shiftexadmin/features/authentication/presentation/bloc/authentication_bloc.dart';

void initAuthDependencies(GetIt getIt) {
  // BLoC
  if (!getIt.isRegistered<AuthenticationBloc>()) {
    getIt.registerFactory<AuthenticationBloc>(
      () => AuthenticationBloc(login: getIt<Login>()),
    );
  }

  // Use cases
  if (!getIt.isRegistered<Login>()) {
    getIt.registerLazySingleton<Login>(
      () => Login(repository: getIt<AuthenticationRepository>()),
    );
  }

  // Repositories
  if (!getIt.isRegistered<AuthenticationRepository>()) {
    getIt.registerLazySingleton<AuthenticationRepository>(
      () => AuthenticationRepositoryImpl(
        authRemoteDatasoucre: getIt<AuthenticationRemoteDatasoucre>(),
      ),
    );
  }

  // Data sources
  if (!getIt.isRegistered<AuthenticationRemoteDatasoucre>()) {
    getIt.registerLazySingleton<AuthenticationRemoteDatasoucre>(
      () => AuthenticationRemoteDatasoucreImpl(
        supabaseClient: getIt(),
      ),
    );
  }
}
