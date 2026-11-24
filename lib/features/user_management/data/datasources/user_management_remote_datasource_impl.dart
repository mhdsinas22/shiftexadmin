import 'dart:convert';
import 'package:shiftexadmin/core/utils/app_logger.dart';
import 'package:shiftexadmin/features/user_management/data/datasources/user_management_remote_datasource.dart';
import 'package:shiftexadmin/features/user_management/data/models/customer_model.dart';
import 'package:shiftexadmin/features/user_management/data/models/user_statistics_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserManagementRemoteDatasourceImpl
    implements UserManagementRemoteDatasource {
  final SupabaseClient supabaseClient;

  UserManagementRemoteDatasourceImpl({required this.supabaseClient});

  Future<int> _getActivePointsPerRupee() async {
    try {
      final row = await supabaseClient
          .from('reward_settings')
          .select('points_per_rupee')
          .eq('singleton_key', 'global')
          .maybeSingle();
      final val = (row?['points_per_rupee'] as num?)?.toInt() ?? 10;
      return val > 0 ? val : 10;
    } catch (_) {
      return 10;
    }
  }

  Future<List<CustomerModel>> _enrichCustomersWithWallets(
    List<Map<String, dynamic>> profileRows,
  ) async {
    if (profileRows.isEmpty) return const [];

    final ptsPerRupee = await _getActivePointsPerRupee();
    final userIds = profileRows
        .map((r) => r['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    final Map<String, Map<String, dynamic>> walletsByUserId = {};
    if (userIds.isNotEmpty) {
      try {
        final List<dynamic> walletRows = await supabaseClient
            .from('customer_wallets')
            .select(
              'user_id, customer_code, membership_tier, available_points, locked_points, lifetime_earned_points',
            )
            .inFilter('user_id', userIds);

        for (final w in walletRows) {
          if (w is Map) {
            final uid = w['user_id']?.toString() ?? '';
            if (uid.isNotEmpty) {
              walletsByUserId[uid] = Map<String, dynamic>.from(w);
            }
          }
        }
      } catch (e) {
        AppLogger.warning('Could not batch-fetch customer wallets: $e');
      }
    }

    return profileRows.map((row) {
      final uid = row['id']?.toString() ?? '';
      final wallet = walletsByUserId[uid];
      final merged = <String, dynamic>{
        ...row,
        'points_per_rupee': ptsPerRupee,
        if (wallet != null) ...{
          'customer_code': wallet['customer_code'],
          'membership_tier': wallet['membership_tier'],
          'instant_points': wallet['available_points'] ?? 0,
          'future_points': wallet['locked_points'] ?? 0,
          'lifetime_earned_points': wallet['lifetime_earned_points'] ?? 0,
        },
      };
      return CustomerModel.fromJson(merged);
    }).toList();
  }

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
      if (status != null &&
          status.isNotEmpty &&
          status.toLowerCase() != 'all') {
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
      final profileMaps = response
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final customers = await _enrichCustomersWithWallets(profileMaps);

      if (sortBy == 'points') {
        customers.sort(
          (a, b) => (b.instantPoints + b.futurePoints).compareTo(
            a.instantPoints + a.futurePoints,
          ),
        );
      }

      return customers;
    } catch (e) {
      AppLogger.error('Failed to get customers: $e');
      throw Exception('Could not fetch customers: $e');
    }
  }

  @override
  Future<List<CustomerModel>> getTopEarners({
    String range = 'weekly',
    int limit = 3,
  }) async {
    final cleanRange = range.trim().toLowerCase();
    try {
      final response = await supabaseClient.rpc(
        'get_user_management_top_earners',
        params: {'p_range': cleanRange, 'p_limit': limit},
      );

      if (response is List) {
        return response
            .whereType<Map>()
            .map((e) => CustomerModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (rpcError) {
      AppLogger.warning(
        'get_user_management_top_earners RPC fallback ($cleanRange): $rpcError',
      );
    }

    // Fallback: compute top earners from approved profiles + customer_wallets
    try {
      final customers = await getCustomers(status: 'approved', limit: 50);
      final withPoints =
          customers.where((c) => c.displayTopEarnerPoints > 0).toList()..sort(
            (a, b) =>
                b.displayTopEarnerPoints.compareTo(a.displayTopEarnerPoints),
          );
      return withPoints.take(limit).toList();
    } catch (e) {
      AppLogger.error('Failed to get top earners fallback: $e');
      return const [];
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
        final status = (row['approval_status'] as String? ?? '').toLowerCase();
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

      final enriched = await _enrichCustomersWithWallets([
        Map<String, dynamic>.from(response),
      ]);
      return enriched.first;
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
      await supabaseClient.rpc(
        'approve_customer',
        params: {'customer_id': customerId},
      );
      AppLogger.info('Customer $customerId approved via RPC');
    } catch (rpcError) {
      AppLogger.warning('RPC approve_customer fallback: $rpcError');

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

      await supabaseClient
          .from('profiles')
          .update({
            'approval_status': 'approved',
            'approved_by': adminUser.id,
            'approved_at': DateTime.now().toUtc().toIso8601String(),
            'rejection_reason': null,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', customerId);

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
      await supabaseClient.rpc(
        'reject_customer',
        params: {'customer_id': customerId, 'reason': reason.trim()},
      );
      AppLogger.info('Customer $customerId rejected via RPC');
    } catch (rpcError) {
      AppLogger.warning('RPC reject_customer fallback: $rpcError');

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

      await supabaseClient
          .from('profiles')
          .update({
            'approval_status': 'rejected',
            'approved_by': adminUser.id,
            'approved_at': DateTime.now().toUtc().toIso8601String(),
            'rejection_reason': reason.trim(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', customerId);

      AppLogger.info('Customer $customerId rejected via direct update');
    }
  }

  String _cleanServerError(String raw) {
    final clean = raw.replaceFirst(
      RegExp(
        r'^(UNAUTHORIZED|UNAUTHENTICATED|INVALID_NAME|INVALID_EMAIL|INVALID_MOBILE|INVALID_PASSWORD|INVALID_STATUS|INVALID_POINTS|DUPLICATE_EMAIL|DUPLICATE_MOBILE|DUPLICATE_ACCOUNT|MOBILE_ALREADY_REGISTERED|AUTH_CREATE_FAILED|CUSTOMER_PROVISION_FAILED|SERVER_MISCONFIGURED):\s*',
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
    return _cleanServerError(
      e.reasonPhrase ?? 'Failed to create customer account.',
    );
  }

  @override
  Future<CustomerModel> createCustomer({
    required String fullName,
    required String email,
    required String mobileNumber,
    required String password,
    String approvalStatus = 'approved',
    String membershipTier = 'Pebble Black Member',
    int initialPoints = 0,
  }) async {
    final adminUser = supabaseClient.auth.currentUser;
    if (adminUser == null) {
      throw Exception('Unauthorized: Please log in as an administrator.');
    }

    try {
      final response = await supabaseClient.functions.invoke(
        'create-customer-account',
        body: {
          'full_name': fullName.trim(),
          'email': email.trim().toLowerCase(),
          'mobile_number': mobileNumber.trim(),
          'password': password,
          'approval_status': approvalStatus.trim().toLowerCase(),
          'membership_tier': membershipTier.trim(),
          'initial_points': initialPoints,
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
        final err =
            parsedMap?['error']?.toString() ??
            'Failed to create customer account (status ${response.status}).';
        throw Exception(_cleanServerError(err));
      }

      if (parsedMap != null) {
        if (parsedMap['error'] != null) {
          throw Exception(_cleanServerError(parsedMap['error'].toString()));
        }
        return CustomerModel.fromJson(parsedMap);
      }

      throw Exception(
        'Invalid response from create-customer-account function.',
      );
    } on FunctionException catch (e) {
      final msg = _extractFunctionError(e);
      AppLogger.error('Edge Function create-customer-account error: $msg');
      throw Exception(msg);
    } on PostgrestException catch (e) {
      AppLogger.error('Postgrest error creating customer account: ${e.message}');
      throw Exception(_cleanServerError(e.message));
    } catch (e) {
      AppLogger.error('Error creating customer account: $e');
      rethrow;
    }
  }
}
