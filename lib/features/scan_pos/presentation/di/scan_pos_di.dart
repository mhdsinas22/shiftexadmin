import 'package:get_it/get_it.dart';
import 'package:shiftexadmin/features/scan_pos/data/datasources/scan_pos_remote_datasource.dart';
import 'package:shiftexadmin/features/scan_pos/data/datasources/scan_pos_remote_datasource_impl.dart';
import 'package:shiftexadmin/features/scan_pos/data/repositories/scan_pos_repository_impl.dart';
import 'package:shiftexadmin/features/scan_pos/domain/repositories/scan_pos_repository.dart';
import 'package:shiftexadmin/features/scan_pos/domain/usecases/allocate_pos_points_usecase.dart';
import 'package:shiftexadmin/features/scan_pos/domain/usecases/get_pos_customer_wallet_usecase.dart';
import 'package:shiftexadmin/features/scan_pos/domain/usecases/get_pos_recent_transactions_usecase.dart';
import 'package:shiftexadmin/features/scan_pos/domain/usecases/redeem_customer_claim_qr_usecase.dart';
import 'package:shiftexadmin/features/scan_pos/domain/usecases/reject_or_flag_claim_qr_usecase.dart';
import 'package:shiftexadmin/features/scan_pos/domain/usecases/search_pos_customers_usecase.dart';
import 'package:shiftexadmin/features/scan_pos/domain/usecases/verify_customer_qr_usecase.dart';
import 'package:shiftexadmin/features/scan_pos/presentation/bloc/scan_pos_bloc.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/usecases/get_points_to_cash_config_usecase.dart';

void initScanPosDependencies(GetIt sl) {
  if (!sl.isRegistered<ScanPosRemoteDataSource>()) {
    sl.registerLazySingleton<ScanPosRemoteDataSource>(
      () => ScanPosRemoteDataSourceImpl(supabaseClient: sl()),
    );
  }

  if (!sl.isRegistered<ScanPosRepository>()) {
    sl.registerLazySingleton<ScanPosRepository>(
      () => ScanPosRepositoryImpl(remoteDataSource: sl()),
    );
  }

  if (!sl.isRegistered<VerifyCustomerQrUseCase>()) {
    sl.registerLazySingleton(
      () => VerifyCustomerQrUseCase(repository: sl()),
    );
  }
  if (!sl.isRegistered<SearchPosCustomersUseCase>()) {
    sl.registerLazySingleton(
      () => SearchPosCustomersUseCase(repository: sl()),
    );
  }
  if (!sl.isRegistered<GetPosCustomerWalletUseCase>()) {
    sl.registerLazySingleton(
      () => GetPosCustomerWalletUseCase(repository: sl()),
    );
  }
  if (!sl.isRegistered<AllocatePosPointsUseCase>()) {
    sl.registerLazySingleton(
      () => AllocatePosPointsUseCase(repository: sl()),
    );
  }
  if (!sl.isRegistered<RedeemCustomerClaimQrUseCase>()) {
    sl.registerLazySingleton(
      () => RedeemCustomerClaimQrUseCase(repository: sl()),
    );
  }
  if (!sl.isRegistered<RejectOrFlagClaimQrUseCase>()) {
    sl.registerLazySingleton(
      () => RejectOrFlagClaimQrUseCase(sl()),
    );
  }
  if (!sl.isRegistered<GetPosRecentTransactionsUseCase>()) {
    sl.registerLazySingleton(
      () => GetPosRecentTransactionsUseCase(repository: sl()),
    );
  }

  if (!sl.isRegistered<ScanPosBloc>()) {
    sl.registerFactory(
      () => ScanPosBloc(
        verifyCustomerQrUseCase: sl(),
        searchPosCustomersUseCase: sl(),
        getPosCustomerWalletUseCase: sl(),
        allocatePosPointsUseCase: sl(),
        redeemCustomerClaimQrUseCase: sl(),
        rejectOrFlagClaimQrUseCase: sl<RejectOrFlagClaimQrUseCase>(),
        getPosRecentTransactionsUseCase: sl(),
        getPointsToCashConfigUseCase: sl<GetPointsToCashConfigUseCase>(),
      ),
    );
  }
}
