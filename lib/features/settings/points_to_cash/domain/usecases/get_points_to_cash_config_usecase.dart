import 'package:shiftexadmin/features/settings/points_to_cash/domain/entities/points_to_cash_config_entity.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/repositories/points_to_cash_repository.dart';

class GetPointsToCashConfigUseCase {
  final PointsToCashRepository repository;

  const GetPointsToCashConfigUseCase({required this.repository});

  Stream<PointsToCashConfigEntity> get stream => repository.configStream;

  PointsToCashConfigEntity? get cached => repository.currentCachedConfig;

  Future<PointsToCashConfigEntity> call() {
    return repository.getActiveConfig();
  }
}
