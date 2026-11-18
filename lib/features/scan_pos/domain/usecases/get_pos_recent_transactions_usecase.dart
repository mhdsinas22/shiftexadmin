import 'package:shiftexadmin/features/scan_pos/domain/entities/pos_transaction_entity.dart';
import 'package:shiftexadmin/features/scan_pos/domain/repositories/scan_pos_repository.dart';

class GetPosRecentTransactionsUseCase {
  final ScanPosRepository repository;

  const GetPosRecentTransactionsUseCase({required this.repository});

  Future<List<PosTransactionEntity>> call({
    int limit = 15,
    int offset = 0,
  }) {
    return repository.getRecentTransactions(limit: limit, offset: offset);
  }
}
