import 'package:shiftexadmin/core/utils/app_logger.dart';
import 'package:shiftexadmin/features/authentication/data/datasoucre/authentication_remote_datasoucre.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthenticationRemoteDatasoucreImpl
    implements AuthenticationRemoteDatasoucre {
  final SupabaseClient supabaseClient;
  AuthenticationRemoteDatasoucreImpl({required this.supabaseClient});

  @override
  Future<void> login(String email, String password) async {
    try {
      // Step 1 Authencation user
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw Exception('Authentication failed');
      }
      final admin = await supabaseClient
          .from("admin_users")
          .select("user_id")
          .eq("user_id", user.id)
          .maybeSingle();
      if (admin == null) {
        await supabaseClient.auth.signOut();
        throw Exception('You are not authorized to access the admin panel');
      }
      AppLogger.info("User Logged in Successfully");
    } catch (e) {
      AppLogger.error("User Login Have Some Issue: ${e.toString()}");
      throw Exception(e.toString());
    }
  }
}
