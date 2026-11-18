import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/presentation/bloc/daily_streak_settings_state.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/presentation/widgets/daily_streak_card_shimmer_widget.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/presentation/widgets/daily_streak_fixed_rules_widget.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/presentation/widgets/daily_streak_performance_card_widget.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/presentation/widgets/daily_streak_points_input_widget.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/presentation/widgets/daily_streak_presets_row_widget.dart';

class DailyStreakConfigCardWidget extends StatelessWidget {
  final DailyStreakSettingsState state;
  final int? activePointsPerRupee;
  final ValueChanged<bool> onToggleEnabled;
  final ValueChanged<String> onPointsChanged;
  final ValueChanged<int> onPresetSelected;
  final VoidCallback onSavePressed;
  final VoidCallback onViewAuditHistory;
  final VoidCallback? onRetryLoad;

  const DailyStreakConfigCardWidget({
    super.key,
    required this.state,
    this.activePointsPerRupee,
    required this.onToggleEnabled,
    required this.onPointsChanged,
    required this.onPresetSelected,
    required this.onSavePressed,
    required this.onViewAuditHistory,
    this.onRetryLoad,
  });

  @override
  Widget build(BuildContext context) {
    final isInitialLoading =
        !state.hasLoadedOnce &&
        (state.status == DailyStreakSettingsStatus.initial ||
            state.status == DailyStreakSettingsStatus.loading);
    final isSaving = state.status == DailyStreakSettingsStatus.saving;
    final settings = state.settings;
    final int pointsPerRupee =
        activePointsPerRupee ?? settings?.effectivePointsPerRupee ?? 10;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon, Title/Subtitle, Enable/Disable Switch
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  size: 22,
                  color: AppColors.purple,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Login Streak',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Loyalty cadence & yield rule',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: state.draftEnabled,
                activeThumbColor: AppColors.pureWhite,
                activeTrackColor: AppColors.linkBlue,
                onChanged: (isInitialLoading || isSaving)
                    ? null
                    : onToggleEnabled,
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (isInitialLoading)
            const DailyStreakCardShimmerWidget()
          else if (settings == null &&
              state.status == DailyStreakSettingsStatus.error)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Unable to load Daily Streak configuration',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.purered,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.errorMessage,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (onRetryLoad != null) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: onRetryLoad,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Retry'),
                    ),
                  ],
                ],
              ),
            )
          else ...[
            DailyStreakPointsInputWidget(
              pointsText: state.draftPointsInput,
              pointsPerRupee: pointsPerRupee,
              enabled: state.draftEnabled,
              validationError: state.validationError,
              onChanged: onPointsChanged,
            ),
            const SizedBox(height: 12),

            DailyStreakPresetsRowWidget(
              selectedPoints: state.parsedDraftPoints,
              onPresetSelected: onPresetSelected,
            ),
            const SizedBox(height: 14),

            DailyStreakFixedRulesWidget(
              eligibilityScansPerCycle: settings?.eligibilityScansPerCycle ?? 1,
              streakDurationDays: settings?.streakDurationDays ?? 7,
              lockDurationDays: settings?.lockDurationDays ?? 7,
              resetHourLabel:
                  settings?.formattedResetHour ?? '06:00 AM IST (UTC+05:30)',
            ),
            const SizedBox(height: 14),

            DailyStreakPerformanceCardWidget(
              statistics: state.statistics,
              pointsPerRupee: pointsPerRupee,
              isStreakEnabled: state.draftEnabled,
              onViewAuditHistory: onViewAuditHistory,
            ),
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : onSavePressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.linkBlue,
                  disabledBackgroundColor: AppColors.linkBlue.withValues(
                    alpha: 0.55,
                  ),
                  foregroundColor: AppColors.pureWhite,
                  disabledForegroundColor: AppColors.pureWhite,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.pureWhite,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: Text(
                  isSaving ? 'Saving Rule Changes...' : 'Save Rule Changes',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
