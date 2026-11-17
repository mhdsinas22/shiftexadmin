import 'package:get_it/get_it.dart';
import 'package:shiftexadmin/features/ads/data/datasources/advertisement_remote_datasource.dart';
import 'package:shiftexadmin/features/ads/data/datasources/advertisement_remote_datasource_impl.dart';
import 'package:shiftexadmin/features/ads/data/repositories/advertisement_repository_impl.dart';
import 'package:shiftexadmin/features/ads/domain/repositories/advertisement_repository.dart';
import 'package:shiftexadmin/features/ads/domain/usecases/create_advertisement_usecase.dart';
import 'package:shiftexadmin/features/ads/domain/usecases/deactivate_advertisement_usecase.dart';
import 'package:shiftexadmin/features/ads/domain/usecases/delete_advertisement_usecase.dart';
import 'package:shiftexadmin/features/ads/domain/usecases/get_active_customer_advertisements_usecase.dart';
import 'package:shiftexadmin/features/ads/domain/usecases/get_advertisement_statistics_usecase.dart';
import 'package:shiftexadmin/features/ads/domain/usecases/get_advertisements_usecase.dart';
import 'package:shiftexadmin/features/ads/domain/usecases/publish_advertisement_usecase.dart';
import 'package:shiftexadmin/features/ads/domain/usecases/schedule_advertisement_usecase.dart';
import 'package:shiftexadmin/features/ads/domain/usecases/track_advertisement_event_usecase.dart';
import 'package:shiftexadmin/features/ads/domain/usecases/update_advertisement_usecase.dart';
import 'package:shiftexadmin/features/ads/presentation/bloc/advertisement_bloc.dart';

void initAdsDependencies(GetIt sl) {
  // Data Source
  if (!sl.isRegistered<AdvertisementRemoteDataSource>()) {
    sl.registerLazySingleton<AdvertisementRemoteDataSource>(
      () => AdvertisementRemoteDataSourceImpl(supabaseClient: sl()),
    );
  }

  // Repository
  if (!sl.isRegistered<AdvertisementRepository>()) {
    sl.registerLazySingleton<AdvertisementRepository>(
      () => AdvertisementRepositoryImpl(remoteDataSource: sl()),
    );
  }

  // Use Cases
  if (!sl.isRegistered<GetAdvertisementsUseCase>()) {
    sl.registerLazySingleton(
        () => GetAdvertisementsUseCase(repository: sl()));
  }
  if (!sl.isRegistered<GetAdvertisementStatisticsUseCase>()) {
    sl.registerLazySingleton(
        () => GetAdvertisementStatisticsUseCase(repository: sl()));
  }
  if (!sl.isRegistered<CreateAdvertisementUseCase>()) {
    sl.registerLazySingleton(
        () => CreateAdvertisementUseCase(repository: sl()));
  }
  if (!sl.isRegistered<UpdateAdvertisementUseCase>()) {
    sl.registerLazySingleton(
        () => UpdateAdvertisementUseCase(repository: sl()));
  }
  if (!sl.isRegistered<PublishAdvertisementUseCase>()) {
    sl.registerLazySingleton(
        () => PublishAdvertisementUseCase(repository: sl()));
  }
  if (!sl.isRegistered<ScheduleAdvertisementUseCase>()) {
    sl.registerLazySingleton(
        () => ScheduleAdvertisementUseCase(repository: sl()));
  }
  if (!sl.isRegistered<DeactivateAdvertisementUseCase>()) {
    sl.registerLazySingleton(
        () => DeactivateAdvertisementUseCase(repository: sl()));
  }
  if (!sl.isRegistered<DeleteAdvertisementUseCase>()) {
    sl.registerLazySingleton(
        () => DeleteAdvertisementUseCase(repository: sl()));
  }
  if (!sl.isRegistered<GetActiveCustomerAdvertisementsUseCase>()) {
    sl.registerLazySingleton(
        () => GetActiveCustomerAdvertisementsUseCase(repository: sl()));
  }
  if (!sl.isRegistered<TrackAdvertisementEventUseCase>()) {
    sl.registerLazySingleton(
        () => TrackAdvertisementEventUseCase(repository: sl()));
  }

  // Bloc
  if (!sl.isRegistered<AdvertisementBloc>()) {
    sl.registerFactory(
      () => AdvertisementBloc(
        getAdvertisementsUseCase: sl(),
        getAdvertisementStatisticsUseCase: sl(),
        createAdvertisementUseCase: sl(),
        updateAdvertisementUseCase: sl(),
        publishAdvertisementUseCase: sl(),
        scheduleAdvertisementUseCase: sl(),
        deactivateAdvertisementUseCase: sl(),
        deleteAdvertisementUseCase: sl(),
        trackAdvertisementEventUseCase: sl(),
      ),
    );
  }
}
