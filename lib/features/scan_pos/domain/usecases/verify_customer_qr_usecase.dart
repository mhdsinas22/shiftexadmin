import 'package:shiftexadmin/features/scan_pos/domain/entities/verified_pos_customer_entity.dart';
import 'package:shiftexadmin/features/scan_pos/domain/repositories/scan_pos_repository.dart';

class VerifyCustomerQrUseCase {
  final ScanPosRepository repository;

  const VerifyCustomerQrUseCase({required this.repository});

  static final RegExp _rawUuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  Future<VerifiedPosCustomerEntity> call({
    required String qrInput,
    required ScanPosMode mode,
  }) {
    final trimmed = qrInput.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('QR payload or token code cannot be empty.');
    }
    if (_rawUuidRegex.hasMatch(trimmed)) {
      throw ArgumentError('Raw customer UUIDs are not valid Member QR codes.');
    }
    return repository.verifyCustomerQr(qrInput: trimmed, mode: mode);
  }
}
