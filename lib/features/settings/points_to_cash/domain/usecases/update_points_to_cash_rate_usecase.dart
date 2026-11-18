import 'package:shiftexadmin/features/settings/points_to_cash/domain/entities/points_to_cash_config_entity.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/repositories/points_to_cash_repository.dart';

class UpdatePointsToCashRateUseCase {
  final PointsToCashRepository repository;

  static const int minPointsPerRupee = 1;
  static const int maxPointsPerRupee = 10000;

  const UpdatePointsToCashRateUseCase({required this.repository});

  Future<PointsToCashConfigEntity> call({
    required int pointsPerRupee,
    String? note,
  }) {
    if (pointsPerRupee < minPointsPerRupee ||
        pointsPerRupee > maxPointsPerRupee) {
      throw ArgumentError(
        'Points per ₹1.00 must be a whole number between $minPointsPerRupee and $maxPointsPerRupee.',
      );
    }

    final cleanNote = note?.trim();

    return repository.updateConversionRate(
      pointsPerRupee: pointsPerRupee,
      note: (cleanNote == null || cleanNote.isEmpty) ? null : cleanNote,
    );
  }
}
