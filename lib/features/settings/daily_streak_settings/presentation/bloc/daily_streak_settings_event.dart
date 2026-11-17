abstract class DailyStreakSettingsEvent {
  const DailyStreakSettingsEvent();
}

class LoadDailyStreakSettingsRequested extends DailyStreakSettingsEvent {
  const LoadDailyStreakSettingsRequested();
}

class RefreshDailyStreakSettingsRequested extends DailyStreakSettingsEvent {
  const RefreshDailyStreakSettingsRequested();
}

class ToggleDailyStreakEnabledChanged extends DailyStreakSettingsEvent {
  final bool enabled;
  const ToggleDailyStreakEnabledChanged(this.enabled);
}

class DailyStreakPointsChanged extends DailyStreakSettingsEvent {
  final String rawPoints;
  const DailyStreakPointsChanged(this.rawPoints);
}

class SelectDailyStreakPresetPoints extends DailyStreakSettingsEvent {
  final int points;
  const SelectDailyStreakPresetPoints(this.points);
}

class SaveDailyStreakSettingsRequested extends DailyStreakSettingsEvent {
  final String? note;
  const SaveDailyStreakSettingsRequested({this.note});
}

class LoadDailyStreakAuditLogsRequested extends DailyStreakSettingsEvent {
  const LoadDailyStreakAuditLogsRequested();
}
