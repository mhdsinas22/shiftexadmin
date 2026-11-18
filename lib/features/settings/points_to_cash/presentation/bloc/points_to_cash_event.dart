abstract class PointsToCashEvent {
  const PointsToCashEvent();
}

class LoadPointsToCashConfigRequested extends PointsToCashEvent {
  const LoadPointsToCashConfigRequested();
}

class RefreshPointsToCashConfigRequested extends PointsToCashEvent {
  const RefreshPointsToCashConfigRequested();
}

class PrepareRateUpdateModalRequested extends PointsToCashEvent {
  const PrepareRateUpdateModalRequested();
}

class DraftPointsPerRupeeChanged extends PointsToCashEvent {
  final String rawValue;
  const DraftPointsPerRupeeChanged(this.rawValue);
}

class DraftRateNoteChanged extends PointsToCashEvent {
  final String note;
  const DraftRateNoteChanged(this.note);
}

class SubmitPointsToCashRateUpdateRequested extends PointsToCashEvent {
  const SubmitPointsToCashRateUpdateRequested();
}

class LoadPointsToCashAuditLogsRequested extends PointsToCashEvent {
  const LoadPointsToCashAuditLogsRequested();
}
