import 'package:shiftexadmin/features/user_management/domain/entities/user_statistics_entity.dart';

class UserStatisticsModel extends UserStatisticsEntity {
  const UserStatisticsModel({
    required super.registeredCount,
    required super.pendingCount,
    required super.activeCount,
    required super.restrictedCount,
  });

  factory UserStatisticsModel.fromCounts({
    required int registered,
    required int pending,
    required int active,
    required int restricted,
  }) {
    return UserStatisticsModel(
      registeredCount: registered,
      pendingCount: pending,
      activeCount: active,
      restrictedCount: restricted,
    );
  }
}
