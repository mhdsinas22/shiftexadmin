import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftexadmin/core/utils/app_logger.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/entities/daily_streak_statistics_entity.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/usecases/get_daily_streak_audit_logs_usecase.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/usecases/get_daily_streak_settings_usecase.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/usecases/get_daily_streak_statistics_usecase.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/usecases/update_daily_streak_settings_usecase.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/presentation/bloc/daily_streak_settings_event.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/presentation/bloc/daily_streak_settings_state.dart';

class DailyStreakSettingsBloc
    extends Bloc<DailyStreakSettingsEvent, DailyStreakSettingsState> {
  final GetDailyStreakSettingsUseCase getDailyStreakSettingsUseCase;
  final UpdateDailyStreakSettingsUseCase updateDailyStreakSettingsUseCase;
  final GetDailyStreakStatisticsUseCase getDailyStreakStatisticsUseCase;
  final GetDailyStreakAuditLogsUseCase getDailyStreakAuditLogsUseCase;

  DailyStreakSettingsBloc({
    required this.getDailyStreakSettingsUseCase,
    required this.updateDailyStreakSettingsUseCase,
    required this.getDailyStreakStatisticsUseCase,
    required this.getDailyStreakAuditLogsUseCase,
  }) : super(const DailyStreakSettingsState()) {
    on<LoadDailyStreakSettingsRequested>(_onLoadSettings);
    on<RefreshDailyStreakSettingsRequested>(_onRefreshSettings);
    on<ToggleDailyStreakEnabledChanged>(_onToggleEnabled);
    on<DailyStreakPointsChanged>(_onPointsChanged);
    on<SelectDailyStreakPresetPoints>(_onPresetSelected);
    on<SaveDailyStreakSettingsRequested>(_onSaveSettings);
    on<LoadDailyStreakAuditLogsRequested>(_onLoadAuditLogs);
  }

  Future<void> _onLoadSettings(
    LoadDailyStreakSettingsRequested event,
    Emitter<DailyStreakSettingsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: DailyStreakSettingsStatus.loading,
        errorMessage: '',
        clearValidationError: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      final settings = await getDailyStreakSettingsUseCase();
      DailyStreakStatisticsEntity statistics =
          DailyStreakStatisticsEntity.empty();

      try {
        statistics = await getDailyStreakStatisticsUseCase();
      } catch (statsError) {
        AppLogger.warning(
          'Daily streak statistics unavailable on load: $statsError',
        );
      }

      emit(
        state.copyWith(
          status: DailyStreakSettingsStatus.loaded,
          settings: settings,
          statistics: statistics,
          draftEnabled: settings.dailyLoginEnabled,
          draftPointsInput: settings.dailyLoginPoints.toString(),
          hasLoadedOnce: true,
          errorMessage: '',
          clearValidationError: true,
        ),
      );
    } catch (e) {
      AppLogger.error('Failed to load daily streak settings: $e');
      emit(
        state.copyWith(
          status: DailyStreakSettingsStatus.error,
          hasLoadedOnce: true,
          errorMessage: _cleanErrorMessage(e),
        ),
      );
    }
  }

  Future<void> _onRefreshSettings(
    RefreshDailyStreakSettingsRequested event,
    Emitter<DailyStreakSettingsState> emit,
  ) async {
    try {
      final settings = await getDailyStreakSettingsUseCase();
      DailyStreakStatisticsEntity statistics = state.statistics;

      try {
        statistics = await getDailyStreakStatisticsUseCase();
      } catch (statsError) {
        AppLogger.warning('Failed refreshing streak statistics: $statsError');
      }

      emit(
        state.copyWith(
          status: DailyStreakSettingsStatus.loaded,
          settings: settings,
          statistics: statistics,
          draftEnabled: settings.dailyLoginEnabled,
          draftPointsInput: settings.dailyLoginPoints.toString(),
          hasLoadedOnce: true,
          errorMessage: '',
          clearValidationError: true,
          clearSuccessMessage: true,
        ),
      );
    } catch (e) {
      AppLogger.error('Error refreshing daily streak settings: $e');
      emit(
        state.copyWith(
          status: DailyStreakSettingsStatus.error,
          errorMessage: _cleanErrorMessage(e),
          clearSuccessMessage: true,
        ),
      );
    }
  }

  void _onToggleEnabled(
    ToggleDailyStreakEnabledChanged event,
    Emitter<DailyStreakSettingsState> emit,
  ) {
    emit(
      state.copyWith(
        status: state.settings != null
            ? DailyStreakSettingsStatus.loaded
            : state.status,
        draftEnabled: event.enabled,
        clearSuccessMessage: true,
        errorMessage: '',
      ),
    );
  }

  void _onPointsChanged(
    DailyStreakPointsChanged event,
    Emitter<DailyStreakSettingsState> emit,
  ) {
    final validation = _validatePointsString(event.rawPoints);
    emit(
      state.copyWith(
        status: state.settings != null
            ? DailyStreakSettingsStatus.loaded
            : state.status,
        draftPointsInput: event.rawPoints,
        validationError: validation,
        clearValidationError: validation == null,
        clearSuccessMessage: true,
        errorMessage: '',
      ),
    );
  }

  void _onPresetSelected(
    SelectDailyStreakPresetPoints event,
    Emitter<DailyStreakSettingsState> emit,
  ) {
    final raw = event.points.toString();
    final validation = _validatePointsString(raw);
    emit(
      state.copyWith(
        status: state.settings != null
            ? DailyStreakSettingsStatus.loaded
            : state.status,
        draftPointsInput: raw,
        validationError: validation,
        clearValidationError: validation == null,
        clearSuccessMessage: true,
        errorMessage: '',
      ),
    );
  }

  Future<void> _onSaveSettings(
    SaveDailyStreakSettingsRequested event,
    Emitter<DailyStreakSettingsState> emit,
  ) async {
    final validation = _validatePointsString(state.draftPointsInput);
    if (validation != null) {
      emit(
        state.copyWith(
          validationError: validation,
          clearSuccessMessage: true,
        ),
      );
      return;
    }

    final points = int.parse(state.draftPointsInput.trim());

    emit(
      state.copyWith(
        status: DailyStreakSettingsStatus.saving,
        errorMessage: '',
        clearValidationError: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      final updated = await updateDailyStreakSettingsUseCase(
        enabled: state.draftEnabled,
        pointsPerCheckin: points,
        note: event.note,
      );

      DailyStreakStatisticsEntity statistics = state.statistics;
      try {
        statistics = await getDailyStreakStatisticsUseCase();
      } catch (_) {}

      emit(
        state.copyWith(
          status: DailyStreakSettingsStatus.loaded,
          settings: updated,
          statistics: statistics,
          draftEnabled: updated.dailyLoginEnabled,
          draftPointsInput: updated.dailyLoginPoints.toString(),
          errorMessage: '',
          clearValidationError: true,
          successMessage:
              'Daily streak rules saved (${updated.dailyLoginEnabled ? 'Enabled' : 'Disabled'}, ${updated.dailyLoginPoints} pts/check-in).',
        ),
      );
    } catch (e) {
      AppLogger.error('Error saving daily streak settings: $e');
      emit(
        state.copyWith(
          status: DailyStreakSettingsStatus.error,
          errorMessage: _cleanErrorMessage(e),
        ),
      );
    }
  }

  Future<void> _onLoadAuditLogs(
    LoadDailyStreakAuditLogsRequested event,
    Emitter<DailyStreakSettingsState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoadingAuditLogs: true,
        errorMessage: '',
      ),
    );

    try {
      final logs = await getDailyStreakAuditLogsUseCase(limit: 50);
      emit(
        state.copyWith(
          auditLogs: logs,
          isLoadingAuditLogs: false,
        ),
      );
    } catch (e) {
      AppLogger.error('Error loading daily streak audit logs: $e');
      emit(
        state.copyWith(
          isLoadingAuditLogs: false,
          errorMessage: _cleanErrorMessage(e),
        ),
      );
    }
  }

  String? _validatePointsString(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return 'Points per daily check-in is required.';
    }
    final value = int.tryParse(trimmed);
    if (value == null) {
      return 'Enter a valid whole number for points.';
    }
    if (value < UpdateDailyStreakSettingsUseCase.minPointsPerCheckin ||
        value > UpdateDailyStreakSettingsUseCase.maxPointsPerCheckin) {
      return 'Points must be between ${UpdateDailyStreakSettingsUseCase.minPointsPerCheckin} and ${UpdateDailyStreakSettingsUseCase.maxPointsPerCheckin}.';
    }
    return null;
  }

  String _cleanErrorMessage(Object error) {
    return error
        .toString()
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceFirst(RegExp(r'^Invalid argument\(s\):\s*'), '');
  }
}
