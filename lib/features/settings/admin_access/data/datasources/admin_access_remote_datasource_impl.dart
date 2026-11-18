import 'dart:convert';
import 'package:shiftexadmin/core/utils/app_logger.dart';
import 'package:shiftexadmin/features/settings/admin_access/data/datasources/admin_access_remote_datasource.dart';
import 'package:shiftexadmin/features/settings/admin_access/data/models/admin_access_overview_model.dart';
import 'package:shiftexadmin/features/settings/admin_access/data/models/admin_operator_model.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_permission.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminAccessRemoteDataSourceImpl implements AdminAccessRemoteDataSource {
  final SupabaseClient supabaseClient;

  AdminAccessRemoteDataSourceImpl({required this.supabaseClient});

  void _ensureSignedIn() {
    if (supabaseClient.auth.currentUser == null) {
      throw Exception('Unauthorized: Please sign in to the Admin Console.');
    }
  }

  String _cleanServerError(String raw) {
    final clean = raw.replaceFirst(
      RegExp(
        r'^(UNAUTHORIZED|UNAUTHENTICATED|INVALID_NAME|INVALID_EMAIL|INVALID_PASSWORD|INVALID_ROLE|INVALID_STATUS|DUPLICATE_EMAIL|DUPLICATE_ADMIN|OPERATOR_NOT_FOUND|OWNER_PROTECTED|SELF_LOCKOUT_PREVENTED|ACCOUNT_SUSPENDED|AUTH_CREATE_FAILED|PROFILE_CREATION_FAILED|SERVER_MISCONFIGURED):\s*',
      ),
      '',
    );
    return clean.isNotEmpty ? clean : raw;
  }

  String _extractFunctionError(FunctionException e) {
    final details = e.details;
    if (details is Map && details['error'] != null) {
      return _cleanServerError(details['error'].toString());
    }
    if (details is String && details.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(details);
        if (decoded is Map && decoded['error'] != null) {
          return _cleanServerError(decoded['error'].toString());
        }
      } catch (_) {}
      return _cleanServerError(details);
    }
    return _cleanServerError(e.reasonPhrase ?? 'Failed to create Admin account.');
  }

  @override
  Future<AdminAccessOverviewModel> getAdminAccessOverview() async {
    try {
      _ensureSignedIn();
      final response = await supabaseClient.rpc('get_admin_access_overview');
      if (response is Map) {
        return AdminAccessOverviewModel.fromJson(
          Map<String, dynamic>.from(response),
        );
      }
      throw Exception('Invalid Admin Access response from server.');
    } on PostgrestException catch (e) {
      AppLogger.error('Error loading Admin Access overview: ${e.message}');
      throw Exception(_cleanServerError(e.message));
    } catch (e) {
      AppLogger.error('Error loading Admin Access overview: $e');
      rethrow;
    }
  }

  @override
  Future<AdminOperatorModel> createAdminAccount({
    required String fullName,
    required String email,
    required String password,
    required AdminRoleType role,
    required String terminalAssignment,
    required List<String> permissions,
  }) async {
    try {
      _ensureSignedIn();
      final response = await supabaseClient.functions.invoke(
        'create-admin-account',
        body: {
          'full_name': fullName.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
          'role': role.dbValue,
          'terminal_assignment': terminalAssignment.trim(),
          'permissions': permissions,
        },
      );

      final data = response.data;
      Map<String, dynamic>? parsedMap;
      if (data is Map) {
        parsedMap = Map<String, dynamic>.from(data);
      } else if (data is String && data.trim().isNotEmpty) {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          parsedMap = Map<String, dynamic>.from(decoded);
        }
      }

      if (response.status >= 400) {
        final err = parsedMap?['error']?.toString() ??
            'Failed to create Admin account (status ${response.status}).';
        throw Exception(_cleanServerError(err));
      }

      if (parsedMap != null) {
        if (parsedMap['error'] != null) {
          throw Exception(_cleanServerError(parsedMap['error'].toString()));
        }
        return AdminOperatorModel.fromJson(parsedMap);
      }

      throw Exception('Invalid response from create-admin-account function.');
    } on FunctionException catch (e) {
      final msg = _extractFunctionError(e);
      AppLogger.error('Edge Function create-admin-account error: $msg');
      throw Exception(msg);
    } on PostgrestException catch (e) {
      AppLogger.error('Postgrest error creating admin account: ${e.message}');
      throw Exception(_cleanServerError(e.message));
    } catch (e) {
      AppLogger.error('Error creating admin account: $e');
      rethrow;
    }
  }

  @override
  Future<AdminOperatorModel> updateOperatorPermissions({
    required String targetUserId,
    required AdminRoleType role,
    required String terminalAssignment,
    required List<String> permissions,
    String status = 'active',
  }) async {
    try {
      _ensureSignedIn();
      final response = await supabaseClient.rpc(
        'update_admin_operator_permissions',
        params: {
          'p_target_user_id': targetUserId,
          'p_role': role.dbValue,
          'p_terminal_assignment': terminalAssignment.trim(),
          'p_permissions': permissions,
          'p_status': status.trim().toLowerCase(),
        },
      );

      if (response is Map) {
        return AdminOperatorModel.fromJson(Map<String, dynamic>.from(response));
      }
      throw Exception('Invalid operator update response from server.');
    } on PostgrestException catch (e) {
      AppLogger.error('Error updating operator permissions: ${e.message}');
      throw Exception(_cleanServerError(e.message));
    } catch (e) {
      AppLogger.error('Error updating operator permissions: $e');
      rethrow;
    }
  }
}
