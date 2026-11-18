import 'package:shiftexadmin/features/scan_pos/domain/entities/verified_pos_customer_entity.dart';
import 'package:shiftexadmin/features/scan_pos/domain/repositories/scan_pos_repository.dart';

class SearchPosCustomersUseCase {
  final ScanPosRepository repository;

  const SearchPosCustomersUseCase({required this.repository});

  Future<List<VerifiedPosCustomerEntity>> call({
    required String query,
    int limit = 10,
  }) {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      return Future.value(const []);
    }
    return repository.searchCustomers(query: trimmed, limit: limit);
  }
}
