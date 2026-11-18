import 'package:shiftexadmin/features/settings/points_to_cash/domain/entities/points_to_cash_audit_log_entity.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/entities/points_to_cash_config_entity.dart';

abstract class PointsToCashRepository {
  Stream<PointsToCashConfigEntity> get configStream;

  PointsToCashConfigEntity? get currentCachedConfig;

  void publishConfig(PointsToCashConfigEntity config);

  Future<PointsToCashConfigEntity> getActiveConfig();

  Future<PointsToCashConfigEntity> updateConversionRate({
    required int pointsPerRupee,
    String? note,
  });

  Future<List<PointsToCashAuditLogEntity>> getRateHistory({
    int limit = 50,
    int offset = 0,
  });
}
