import 'dart:async';
import 'package:shiftexadmin/features/settings/points_to_cash/data/datasources/points_to_cash_remote_datasource.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/entities/points_to_cash_audit_log_entity.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/entities/points_to_cash_config_entity.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/repositories/points_to_cash_repository.dart';

class PointsToCashRepositoryImpl implements PointsToCashRepository {
  final PointsToCashRemoteDataSource remoteDataSource;
  final StreamController<PointsToCashConfigEntity> _controller =
      StreamController<PointsToCashConfigEntity>.broadcast();

  PointsToCashConfigEntity? _cachedConfig;

  PointsToCashRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<PointsToCashConfigEntity> get configStream => _controller.stream;

  @override
  PointsToCashConfigEntity? get currentCachedConfig => _cachedConfig;

  @override
  void publishConfig(PointsToCashConfigEntity config) {
    _cachedConfig = config;
    if (!_controller.isClosed) {
      _controller.add(config);
    }
  }

  @override
  Future<PointsToCashConfigEntity> getActiveConfig() async {
    final config = await remoteDataSource.getActiveConfig();
    publishConfig(config);
    return config;
  }

  @override
  Future<PointsToCashConfigEntity> updateConversionRate({
    required int pointsPerRupee,
    String? note,
  }) async {
    final updated = await remoteDataSource.updateConversionRate(
      pointsPerRupee: pointsPerRupee,
      note: note,
    );
    publishConfig(updated);
    return updated;
  }

  @override
  Future<List<PointsToCashAuditLogEntity>> getRateHistory({
    int limit = 50,
    int offset = 0,
  }) {
    return remoteDataSource.getRateHistory(limit: limit, offset: offset);
  }
}
