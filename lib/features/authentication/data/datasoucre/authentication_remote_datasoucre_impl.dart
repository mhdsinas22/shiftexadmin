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
      final response = await supabaseClient.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw Exception('Authentication failed');
      }

      // 1. Verify admin status & claim any pending invitation via secure RPC
      try {
        await supabaseClient.rpc('verify_and_sync_admin_session');
        AppLogger.info('Admin session verified via RPC');
        return;
      } on PostgrestException catch (rpcError) {
        final msg = rpcError.message;
        if (msg.contains('UNAUTHORIZED') || msg.contains('ACCOUNT_SUSPENDED')) {
          await supabaseClient.auth.signOut();
          throw Exception(
            msg.replaceFirst(
              RegExp(r'^(UNAUTHORIZED|ACCOUNT_SUSPENDED):\s*'),
              '',
            ),
          );
        }
        AppLogger.warning('verify_and_sync_admin_session fallback: $msg');
      } catch (e) {
        AppLogger.warning('verify_and_sync_admin_session fallback: $e');
      }

      // 2. Fallback check against admin_users table
      final admin = await supabaseClient
          .from('admin_users')
          .select('user_id, status')
          .eq('user_id', user.id)
          .maybeSingle();

      if (admin == null ||
          (admin['status'] != null &&
              admin['status'].toString().toLowerCase() != 'active')) {
        await supabaseClient.auth.signOut();
        throw Exception('You are not authorized to access the admin panel');
      }
      AppLogger.info('User Logged in Successfully');
    } catch (e) {
      AppLogger.error('User Login Have Some Issue: ${e.toString()}');
      throw Exception(e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''));
    }
  }
}
