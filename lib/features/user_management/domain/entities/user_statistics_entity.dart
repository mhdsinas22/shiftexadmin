class UserStatisticsEntity {
  final int registeredCount;
  final int pendingCount;
  final int activeCount;
  final int restrictedCount;

  const UserStatisticsEntity({
    required this.registeredCount,
    required this.pendingCount,
    required this.activeCount,
    required this.restrictedCount,
  });

  factory UserStatisticsEntity.empty() {
    return const UserStatisticsEntity(
      registeredCount: 0,
      pendingCount: 0,
      activeCount: 0,
      restrictedCount: 0,
    );
  }

  UserStatisticsEntity copyWith({
    int? registeredCount,
    int? pendingCount,
    int? activeCount,
    int? restrictedCount,
  }) {
    return UserStatisticsEntity(
      registeredCount: registeredCount ?? this.registeredCount,
      pendingCount: pendingCount ?? this.pendingCount,
      activeCount: activeCount ?? this.activeCount,
      restrictedCount: restrictedCount ?? this.restrictedCount,
    );
  }
}
