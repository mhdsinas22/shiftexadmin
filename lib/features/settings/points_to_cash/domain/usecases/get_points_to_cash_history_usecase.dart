import 'package:shiftexadmin/features/settings/points_to_cash/domain/entities/points_to_cash_audit_log_entity.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/repositories/points_to_cash_repository.dart';

class GetPointsToCashHistoryUseCase {
  final PointsToCashRepository repository;

  const GetPointsToCashHistoryUseCase({required this.repository});

  Future<List<PointsToCashAuditLogEntity>> call({
    int limit = 50,
    int offset = 0,
  }) {
    return repository.getRateHistory(limit: limit, offset: offset);
  }
}
