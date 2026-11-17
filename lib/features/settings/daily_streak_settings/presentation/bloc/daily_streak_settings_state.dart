import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/entities/daily_streak_audit_log_entity.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/entities/daily_streak_settings_entity.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/entities/daily_streak_statistics_entity.dart';

enum DailyStreakSettingsStatus {
  initial,
  loading,
  loaded,
  saving,
  error,
}

class DailyStreakSettingsState {
  final DailyStreakSettingsStatus status;
  final DailyStreakSettingsEntity? settings;
  final DailyStreakStatisticsEntity statistics;
  final List<DailyStreakAuditLogEntity> auditLogs;
  final bool isLoadingAuditLogs;
  final bool hasLoadedOnce;
  final bool draftEnabled;
  final String draftPointsInput;
  final String? validationError;
  final String errorMessage;
  final String? successMessage;

  const DailyStreakSettingsState({
    this.status = DailyStreakSettingsStatus.initial,
    this.settings,
    this.statistics = const DailyStreakStatisticsEntity(
      totalPointsDistributed: 0,
      distributedPoints30d: 0,
      activeStreakers: 0,
      completionRate7d: 0.0,
      analyticsAvailable: false,
    ),
    this.auditLogs = const [],
    this.isLoadingAuditLogs = false,
    this.hasLoadedOnce = false,
    this.draftEnabled = true,
    this.draftPointsInput = '15',
    this.validationError,
    this.errorMessage = '',
    this.successMessage,
  });

  int? get parsedDraftPoints => int.tryParse(draftPointsInput.trim());

  int get effectivePreviewPoints =>
      parsedDraftPoints ?? settings?.dailyLoginPoints ?? 0;

  bool get isDraftPointsValid {
    final pts = parsedDraftPoints;
    return pts != null && pts >= 1 && pts <= 1000;
  }

  bool get hasUnsavedChanges {
    final current = settings;
    if (current == null) return false;
    return draftEnabled != current.dailyLoginEnabled ||
        parsedDraftPoints != current.dailyLoginPoints;
  }

  DailyStreakSettingsState copyWith({
    DailyStreakSettingsStatus? status,
    DailyStreakSettingsEntity? settings,
    DailyStreakStatisticsEntity? statistics,
    List<DailyStreakAuditLogEntity>? auditLogs,
    bool? isLoadingAuditLogs,
    bool? hasLoadedOnce,
    bool? draftEnabled,
    String? draftPointsInput,
    String? validationError,
    String? errorMessage,
    String? successMessage,
    bool clearValidationError = false,
    bool clearSuccessMessage = false,
  }) {
    return DailyStreakSettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      statistics: statistics ?? this.statistics,
      auditLogs: auditLogs ?? this.auditLogs,
      isLoadingAuditLogs: isLoadingAuditLogs ?? this.isLoadingAuditLogs,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
      draftEnabled: draftEnabled ?? this.draftEnabled,
      draftPointsInput: draftPointsInput ?? this.draftPointsInput,
      validationError: clearValidationError
          ? null
          : (validationError ?? this.validationError),
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
    );
  }
}
