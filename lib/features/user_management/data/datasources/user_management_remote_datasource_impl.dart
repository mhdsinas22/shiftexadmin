import 'package:shiftexadmin/core/utils/app_logger.dart';
import 'package:shiftexadmin/features/user_management/data/datasources/user_management_remote_datasource.dart';
import 'package:shiftexadmin/features/user_management/data/models/customer_model.dart';
import 'package:shiftexadmin/features/user_management/data/models/user_statistics_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserManagementRemoteDatasourceImpl
    implements UserManagementRemoteDatasource {
  final SupabaseClient supabaseClient;

  UserManagementRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<CustomerModel>> getCustomers({
    String? status,
    String? searchQuery,
    String? sortBy,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      dynamic query = supabaseClient.from('profiles').select('*');

      // Filter by approval_status
      if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
        final cleanStatus = status.toLowerCase();
        if (cleanStatus == 'verified' || cleanStatus == 'approved') {
          query = query.eq('approval_status', 'approved');
        } else if (cleanStatus == 'pending') {
          query = query.eq('approval_status', 'pending');
        } else if (cleanStatus == 'restricted') {
          query = query.inFilter('approval_status', ['rejected', 'suspended']);
        } else {
          query = query.eq('approval_status', cleanStatus);
        }
      }

      // Search by full_name, email, or mobile_number
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final term = searchQuery.trim();
        query = query.or(
          'full_name.ilike.%$term%,email.ilike.%$term%,mobile_number.ilike.%$term%',
        );
      }

      // Sort
      if (sortBy == 'oldest') {
        query = query.order('created_at', ascending: true);
      } else if (sortBy == 'name') {
        query = query.order('full_name', ascending: true);
      } else {
        query = query.order('created_at', ascending: false);
      }

      // Pagination
      query = query.range(offset, offset + limit - 1);

      final List<dynamic> response = await query;
      return response
          .map((e) => CustomerModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to get customers: $e');
      throw Exception('Could not fetch customers: $e');
    }
  }

  @override
  Future<UserStatisticsModel> getUserStatistics() async {
    try {
      final List<dynamic> response = await supabaseClient
          .from('profiles')
          .select('approval_status');

      int registered = 0;
      int pending = 0;
      int active = 0;
      int restricted = 0;

      for (final row in response) {
        final status =
            (row['approval_status'] as String? ?? '').toLowerCase();
        registered++;
        if (status == 'pending') {
          pending++;
        } else if (status == 'approved') {
          active++;
        } else if (status == 'rejected' || status == 'suspended') {
          restricted++;
        }
      }

      return UserStatisticsModel.fromCounts(
        registered: registered,
        pending: pending,
        active: active,
        restricted: restricted,
      );
    } catch (e) {
      AppLogger.error('Failed to get user statistics: $e');
      throw Exception('Could not calculate user statistics: $e');
    }
  }

  @override
  Future<CustomerModel> getCustomerDetails(String customerId) async {
    try {
      final response = await supabaseClient
          .from('profiles')
          .select('*')
          .eq('id', customerId)
          .single();

      return CustomerModel.fromJson(response);
    } catch (e) {
      AppLogger.error('Failed to get customer details: $e');
      throw Exception('Could not load customer details: $e');
    }
  }

  @override
  Future<void> approveCustomer(String customerId) async {
    final adminUser = supabaseClient.auth.currentUser;
    if (adminUser == null) {
      throw Exception('Unauthorized: Please log in as an administrator');
    }

    try {
      // 1. Try secure PostgreSQL RPC
      await supabaseClient.rpc(
        'approve_customer',
        params: {'customer_id': customerId},
      );
      AppLogger.info('Customer $customerId approved via RPC');
    } catch (rpcError) {
      AppLogger.warning('RPC approve_customer fallback: $rpcError');

      // 2. Verify admin permission in admin_users
      final adminRecord = await supabaseClient
          .from('admin_users')
          .select('user_id')
          .eq('user_id', adminUser.id)
          .maybeSingle();

      if (adminRecord == null) {
        throw Exception(
          'Unauthorized: Your account is not authorized as an administrator',
        );
      }

      await supabaseClient.from('profiles').update({
        'approval_status': 'approved',
        'approved_by': adminUser.id,
        'approved_at': DateTime.now().toUtc().toIso8601String(),
        'rejection_reason': null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', customerId);

      AppLogger.info('Customer $customerId approved via direct update');
    }
  }

  @override
  Future<void> rejectCustomer(String customerId, String reason) async {
    final adminUser = supabaseClient.auth.currentUser;
    if (adminUser == null) {
      throw Exception('Unauthorized: Please log in as an administrator');
    }

    if (reason.trim().isEmpty) {
      throw Exception('Rejection reason cannot be empty');
    }

    try {
      // 1. Try secure PostgreSQL RPC
      await supabaseClient.rpc(
        'reject_customer',
        params: {
          'customer_id': customerId,
          'reason': reason.trim(),
        },
      );
      AppLogger.info('Customer $customerId rejected via RPC');
    } catch (rpcError) {
      AppLogger.warning('RPC reject_customer fallback: $rpcError');

      // 2. Verify admin permission in admin_users
      final adminRecord = await supabaseClient
          .from('admin_users')
          .select('user_id')
          .eq('user_id', adminUser.id)
          .maybeSingle();

      if (adminRecord == null) {
        throw Exception(
          'Unauthorized: Your account is not authorized as an administrator',
        );
      }

      await supabaseClient.from('profiles').update({
        'approval_status': 'rejected',
        'approved_by': adminUser.id,
        'approved_at': DateTime.now().toUtc().toIso8601String(),
        'rejection_reason': reason.trim(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', customerId);

      AppLogger.info('Customer $customerId rejected via direct update');
    }
  }
}
