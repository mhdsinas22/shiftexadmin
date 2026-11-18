import 'package:shiftexadmin/features/settings/points_to_cash/data/models/points_to_cash_audit_log_model.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/data/models/points_to_cash_config_model.dart';

abstract class PointsToCashRemoteDataSource {
  Future<PointsToCashConfigModel> getActiveConfig();

  Future<PointsToCashConfigModel> updateConversionRate({
    required int pointsPerRupee,
    String? note,
  });

  Future<List<PointsToCashAuditLogModel>> getRateHistory({
    int limit = 50,
    int offset = 0,
  });
}
