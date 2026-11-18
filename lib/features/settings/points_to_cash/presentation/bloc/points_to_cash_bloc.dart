import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftexadmin/core/utils/app_logger.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/usecases/get_points_to_cash_config_usecase.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/usecases/get_points_to_cash_history_usecase.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/usecases/update_points_to_cash_rate_usecase.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/presentation/bloc/points_to_cash_event.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/presentation/bloc/points_to_cash_state.dart';

class PointsToCashBloc extends Bloc<PointsToCashEvent, PointsToCashState> {
  final GetPointsToCashConfigUseCase getPointsToCashConfigUseCase;
  final UpdatePointsToCashRateUseCase updatePointsToCashRateUseCase;
  final GetPointsToCashHistoryUseCase getPointsToCashHistoryUseCase;

  PointsToCashBloc({
    required this.getPointsToCashConfigUseCase,
    required this.updatePointsToCashRateUseCase,
    required this.getPointsToCashHistoryUseCase,
  }) : super(const PointsToCashState()) {
    on<LoadPointsToCashConfigRequested>(_onLoadConfig);
    on<RefreshPointsToCashConfigRequested>(_onRefreshConfig);
    on<PrepareRateUpdateModalRequested>(_onPrepareRateUpdateModal);
    on<DraftPointsPerRupeeChanged>(_onDraftPointsChanged);
    on<DraftRateNoteChanged>(_onDraftNoteChanged);
    on<SubmitPointsToCashRateUpdateRequested>(_onSubmitRateUpdate);
    on<LoadPointsToCashAuditLogsRequested>(_onLoadAuditLogs);
  }

  Future<void> _onLoadConfig(
    LoadPointsToCashConfigRequested event,
    Emitter<PointsToCashState> emit,
  ) async {
    emit(
      state.copyWith(
        status: PointsToCashStatus.loading,
        errorMessage: '',
        clearValidationError: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      final config = await getPointsToCashConfigUseCase();
      emit(
        state.copyWith(
          status: PointsToCashStatus.loaded,
          config: config,
          draftPointsPerRupeeInput: config.pointsPerRupee.toString(),
          hasLoadedOnce: true,
          errorMessage: '',
        ),
      );
    } catch (e) {
      AppLogger.error('Failed to load Points-to-Cash config: $e');
      emit(
        state.copyWith(
          status: PointsToCashStatus.error,
          hasLoadedOnce: true,
          errorMessage: _cleanError(e),
        ),
      );
    }
  }

  Future<void> _onRefreshConfig(
    RefreshPointsToCashConfigRequested event,
    Emitter<PointsToCashState> emit,
  ) async {
    try {
      final config = await getPointsToCashConfigUseCase();
      emit(
        state.copyWith(
          status: PointsToCashStatus.loaded,
          config: config,
          draftPointsPerRupeeInput: config.pointsPerRupee.toString(),
          hasLoadedOnce: true,
          errorMessage: '',
          clearSuccessMessage: true,
        ),
      );
    } catch (e) {
      AppLogger.error('Failed refreshing Points-to-Cash config: $e');
      emit(
        state.copyWith(
          status: PointsToCashStatus.error,
          errorMessage: _cleanError(e),
          clearSuccessMessage: true,
        ),
      );
    }
  }

  Future<void> _onPrepareRateUpdateModal(
    PrepareRateUpdateModalRequested event,
    Emitter<PointsToCashState> emit,
  ) async {
    emit(
      state.copyWith(
        draftPointsPerRupeeInput: state.activePointsPerRupee.toString(),
        draftNoteInput: '',
        errorMessage: '',
        clearValidationError: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      final latest = await getPointsToCashConfigUseCase();
      emit(
        state.copyWith(
          status: PointsToCashStatus.loaded,
          config: latest,
          draftPointsPerRupeeInput: latest.pointsPerRupee.toString(),
          hasLoadedOnce: true,
          errorMessage: '',
          clearValidationError: true,
        ),
      );
    } catch (e) {
      AppLogger.error('Failed refreshing config before rate edit: $e');
    }
  }

  void _onDraftPointsChanged(
    DraftPointsPerRupeeChanged event,
    Emitter<PointsToCashState> emit,
  ) {
    final trimmed = event.rawValue.trim();
    String? validationError;

    if (trimmed.isEmpty) {
      validationError = 'Enter points required for ₹1.00 (1 - 10,000).';
    } else if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
      validationError = 'Use whole numbers only (e.g. 10, 20, 50).';
    } else {
      final parsed = int.tryParse(trimmed);
      if (parsed == null ||
          parsed < UpdatePointsToCashRateUseCase.minPointsPerRupee ||
          parsed > UpdatePointsToCashRateUseCase.maxPointsPerRupee) {
        validationError =
            'Points per ₹1 must be between ${UpdatePointsToCashRateUseCase.minPointsPerRupee} and ${UpdatePointsToCashRateUseCase.maxPointsPerRupee}.';
      }
    }

    emit(
      state.copyWith(
        draftPointsPerRupeeInput: event.rawValue,
        validationError: validationError,
        clearValidationError: validationError == null,
        errorMessage: '',
        clearSuccessMessage: true,
      ),
    );
  }

  void _onDraftNoteChanged(
    DraftRateNoteChanged event,
    Emitter<PointsToCashState> emit,
  ) {
    emit(state.copyWith(draftNoteInput: event.note, clearSuccessMessage: true));
  }

  Future<void> _onSubmitRateUpdate(
    SubmitPointsToCashRateUpdateRequested event,
    Emitter<PointsToCashState> emit,
  ) async {
    final parsed = state.proposedPointsPerRupee;
    if (parsed == null || !state.isProposedRateValid) {
      emit(
        state.copyWith(
          validationError:
              'Enter a valid whole number between ${UpdatePointsToCashRateUseCase.minPointsPerRupee} and ${UpdatePointsToCashRateUseCase.maxPointsPerRupee}.',
        ),
      );
      return;
    }

    if (state.config != null && parsed == state.activePointsPerRupee) {
      emit(
        state.copyWith(
          validationError:
              'Enter a new rate different from the active ${state.activePointsPerRupee} pts = ₹1.00 rate.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: PointsToCashStatus.updating,
        errorMessage: '',
        clearValidationError: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      final updated = await updatePointsToCashRateUseCase(
        pointsPerRupee: parsed,
        note: state.draftNoteInput,
      );

      final refreshed = await getPointsToCashConfigUseCase().catchError(
        (_) => updated,
      );

      emit(
        state.copyWith(
          status: PointsToCashStatus.loaded,
          config: refreshed,
          draftPointsPerRupeeInput: refreshed.pointsPerRupee.toString(),
          draftNoteInput: '',
          hasLoadedOnce: true,
          errorMessage: '',
          clearValidationError: true,
          successMessage:
              'Conversion rate updated: ${refreshed.pointsPerRupee} pts = ₹1.00',
        ),
      );
    } catch (e) {
      AppLogger.error('Failed to update Points-to-Cash rate: $e');
      emit(
        state.copyWith(
          status: PointsToCashStatus.error,
          errorMessage: _cleanError(e),
          clearSuccessMessage: true,
        ),
      );
    }
  }

  Future<void> _onLoadAuditLogs(
    LoadPointsToCashAuditLogsRequested event,
    Emitter<PointsToCashState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoadingAuditLogs: true,
        errorMessage: '',
        clearSuccessMessage: true,
      ),
    );

    try {
      final logs = await getPointsToCashHistoryUseCase();
      emit(
        state.copyWith(
          isLoadingAuditLogs: false,
          auditLogs: logs,
          errorMessage: '',
        ),
      );
    } catch (e) {
      AppLogger.error('Failed to load Points-to-Cash audit logs: $e');
      emit(
        state.copyWith(
          isLoadingAuditLogs: false,
          status: PointsToCashStatus.error,
          errorMessage: _cleanError(e),
        ),
      );
    }
  }

  String _cleanError(Object error) {
    final raw = error.toString();
    if (raw.contains('UNAUTHORIZED')) {
      return 'Admin permissions are required to update conversion rates.';
    }
    if (raw.contains('INVALID_RATE')) {
      return 'Conversion rate must be between 1 and 10,000 points per ₹1.00.';
    }
    if (raw.startsWith('Exception: ')) {
      return raw.replaceFirst('Exception: ', '');
    }
    if (raw.startsWith('Bad state: ')) {
      return raw.replaceFirst('Bad state: ', '');
    }
    if (raw.startsWith('Invalid argument(s): ')) {
      return raw.replaceFirst('Invalid argument(s): ', '');
    }
    return raw;
  }
}
