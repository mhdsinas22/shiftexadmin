import 'package:get_it/get_it.dart';
import 'package:shiftexadmin/features/ads/presentation/di/ads_di.dart';
import 'package:shiftexadmin/features/authentication/presentation/di/authentication_di.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/presentation/di/daily_streak_settings_di.dart';
import 'package:shiftexadmin/features/user_management/presentation/di/user_management_di.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GetIt getIt = GetIt.instance;
final GetIt sl = getIt;

Future<void> initDependencies({SupabaseClient? mockSupabaseClient}) async {
  // External - Supabase Client
  if (mockSupabaseClient != null) {
    if (getIt.isRegistered<SupabaseClient>()) {
      getIt.unregister<SupabaseClient>();
    }
    getIt.registerSingleton<SupabaseClient>(mockSupabaseClient);
  } else if (!getIt.isRegistered<SupabaseClient>()) {
    getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  }

  // Feature Dependencies - Authentication
  initAuthDependencies(getIt);

  // Feature Dependencies - User Management
  initUserManagementDependencies(getIt);

  // Feature Dependencies - Advertisements
  initAdsDependencies(getIt);

  // Feature Dependencies - Daily Streak Settings
  initDailyStreakSettingsDependencies(getIt);
}
