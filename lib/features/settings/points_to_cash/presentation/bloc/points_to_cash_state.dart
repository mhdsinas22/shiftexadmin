import 'package:shiftexadmin/features/settings/points_to_cash/domain/entities/points_to_cash_audit_log_entity.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/entities/points_to_cash_config_entity.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/usecases/update_points_to_cash_rate_usecase.dart';

enum PointsToCashStatus { initial, loading, loaded, updating, error }

class PointsToCashState {
  final PointsToCashStatus status;
  final PointsToCashConfigEntity? config;
  final List<PointsToCashAuditLogEntity> auditLogs;
  final bool isLoadingAuditLogs;
  final String draftPointsPerRupeeInput;
  final String draftNoteInput;
  final String? validationError;
  final String errorMessage;
  final String? successMessage;
  final bool hasLoadedOnce;

  const PointsToCashState({
    this.status = PointsToCashStatus.initial,
    this.config,
    this.auditLogs = const [],
    this.isLoadingAuditLogs = false,
    this.draftPointsPerRupeeInput = '10',
    this.draftNoteInput = '',
    this.validationError,
    this.errorMessage = '',
    this.successMessage,
    this.hasLoadedOnce = false,
  });

  int get activePointsPerRupee => config?.pointsPerRupee ?? 10;

  double get activePointsToInrRate =>
      PointsToCashConfigEntity.ratePerPoint(activePointsPerRupee);

  int? get proposedPointsPerRupee {
    final trimmed = draftPointsPerRupeeInput.trim();
    if (trimmed.isEmpty || !RegExp(r'^\d+$').hasMatch(trimmed)) {
      return null;
    }
    return int.tryParse(trimmed);
  }

  bool get isProposedRateValid {
    final v = proposedPointsPerRupee;
    return v != null &&
        v >= UpdatePointsToCashRateUseCase.minPointsPerRupee &&
        v <= UpdatePointsToCashRateUseCase.maxPointsPerRupee;
  }

  double? get proposedCashPerPoint => isProposedRateValid
      ? PointsToCashConfigEntity.ratePerPoint(proposedPointsPerRupee!)
      : null;

  double proposedInrFor(int points) {
    final ptsPerRupee = proposedPointsPerRupee;
    if (ptsPerRupee == null || !isProposedRateValid) return 0.0;
    return PointsToCashConfigEntity.inrFromPoints(
      points: points,
      pointsPerRupee: ptsPerRupee,
    );
  }

  bool get isRateChanged =>
      isProposedRateValid &&
      (config == null || proposedPointsPerRupee != activePointsPerRupee);

  bool get canSubmitRateUpdate =>
      isProposedRateValid &&
      isRateChanged &&
      status != PointsToCashStatus.updating;

  PointsToCashState copyWith({
    PointsToCashStatus? status,
    PointsToCashConfigEntity? config,
    List<PointsToCashAuditLogEntity>? auditLogs,
    bool? isLoadingAuditLogs,
    String? draftPointsPerRupeeInput,
    String? draftNoteInput,
    String? validationError,
    String? errorMessage,
    String? successMessage,
    bool? hasLoadedOnce,
    bool clearValidationError = false,
    bool clearSuccessMessage = false,
  }) {
    return PointsToCashState(
      status: status ?? this.status,
      config: config ?? this.config,
      auditLogs: auditLogs ?? this.auditLogs,
      isLoadingAuditLogs: isLoadingAuditLogs ?? this.isLoadingAuditLogs,
      draftPointsPerRupeeInput:
          draftPointsPerRupeeInput ?? this.draftPointsPerRupeeInput,
      draftNoteInput: draftNoteInput ?? this.draftNoteInput,
      validationError: clearValidationError
          ? null
          : (validationError ?? this.validationError),
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
    );
  }
}
