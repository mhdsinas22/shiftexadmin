import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/data/models/daily_streak_audit_log_model.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/data/models/daily_streak_settings_model.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/data/models/daily_streak_statistics_model.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/entities/daily_streak_audit_log_entity.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/entities/daily_streak_settings_entity.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/entities/daily_streak_statistics_entity.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/repositories/daily_streak_settings_repository.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/usecases/get_daily_streak_audit_logs_usecase.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/usecases/get_daily_streak_settings_usecase.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/usecases/get_daily_streak_statistics_usecase.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/domain/usecases/update_daily_streak_settings_usecase.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/presentation/bloc/daily_streak_settings_bloc.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/presentation/bloc/daily_streak_settings_event.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/presentation/bloc/daily_streak_settings_state.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/presentation/widgets/daily_streak_audit_log_item_widget.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/presentation/widgets/daily_streak_card_shimmer_widget.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/presentation/widgets/daily_streak_config_card_widget.dart';

class FakeDailyStreakSettingsRepository
    implements DailyStreakSettingsRepository {
  DailyStreakSettingsEntity storedSettings = DailyStreakSettingsEntity(
    id: 'cfg-1',
    dailyLoginEnabled: true,
    dailyLoginPoints: 15,
    streakDurationDays: 7,
    lockDurationDays: 7,
    eligibilityScansPerCycle: 1,
    timezone: 'Asia/Kolkata',
    dailyResetTime: '06:00:00',
    pointsToInrRate: 0.10,
    updatedAt: DateTime(2026, 11, 17, 9, 0),
  );

  DailyStreakStatisticsEntity storedStats = DailyStreakStatisticsEntity.empty();
  List<DailyStreakAuditLogEntity> storedAuditLogs = [];

  Object? getSettingsError;
  Object? updateSettingsError;
  Object? getStatsError;
  int updateCallCount = 0;

  @override
  Future<DailyStreakSettingsEntity> getDailyStreakSettings() async {
    if (getSettingsError != null) throw getSettingsError!;
    return storedSettings;
  }

  @override
  Future<DailyStreakSettingsEntity> updateDailyStreakSettings({
    required bool enabled,
    required int pointsPerCheckin,
    String? note,
  }) async {
    updateCallCount++;
    if (updateSettingsError != null) throw updateSettingsError!;

    final updated = storedSettings.copyWith(
      dailyLoginEnabled: enabled,
      dailyLoginPoints: pointsPerCheckin,
      updatedAt: DateTime.now(),
    );
    storedAuditLogs.insert(
      0,
      DailyStreakAuditLogEntity(
        id: 'audit-$updateCallCount',
        settingKey: 'daily_login_streak',
        previousEnabled: storedSettings.dailyLoginEnabled,
        newEnabled: enabled,
        previousPoints: storedSettings.dailyLoginPoints,
        newPoints: pointsPerCheckin,
        changedByEmail: 'admin@shiftex.in',
        note: note,
        createdAt: DateTime.now(),
      ),
    );
    storedSettings = updated;
    return updated;
  }

  @override
  Future<DailyStreakStatisticsEntity> getDailyStreakStatistics() async {
    if (getStatsError != null) throw getStatsError!;
    return storedStats;
  }

  @override
  Future<List<DailyStreakAuditLogEntity>> getAuditLogs({int limit = 50}) async {
    return storedAuditLogs.take(limit).toList();
  }
}

DailyStreakSettingsBloc _createBloc(FakeDailyStreakSettingsRepository repo) {
  return DailyStreakSettingsBloc(
    getDailyStreakSettingsUseCase:
        GetDailyStreakSettingsUseCase(repository: repo),
    updateDailyStreakSettingsUseCase:
        UpdateDailyStreakSettingsUseCase(repository: repo),
    getDailyStreakStatisticsUseCase:
        GetDailyStreakStatisticsUseCase(repository: repo),
    getDailyStreakAuditLogsUseCase:
        GetDailyStreakAuditLogsUseCase(repository: repo),
  );
}

void main() {
  group('Daily Streak Models & UseCase Validation Tests', () {
    test('Models deserialize Supabase JSON safely with fixed 7-day defaults', () {
      final settingsModel = DailyStreakSettingsModel.fromJson({
        'id': 'row-1',
        'daily_login_enabled': false,
        'daily_login_points': 25,
        'streak_duration_days': 7,
        'lock_duration_days': 7,
        'eligibility_scans_per_cycle': 1,
        'timezone': 'Asia/Kolkata',
        'daily_reset_time': '06:00:00',
        'points_to_inr_rate': '0.1000',
        'updated_at': '2026-11-17T04:13:38.6159Z',
      });

      expect(settingsModel.dailyLoginEnabled, false);
      expect(settingsModel.dailyLoginPoints, 25);
      expect(settingsModel.streakDurationDays, 7);
      expect(settingsModel.timezone, 'Asia/Kolkata');
      expect(settingsModel.equivalentInrFor(25), 2.5);

      final statsModel = DailyStreakStatisticsModel.fromJson({
        'total_points_distributed': 50000,
        'distributed_points_30d': 48290,
        'active_streakers': 3140,
        'completion_rate_7d': '64.2',
        'completed_streaks_30d': 2016,
        'total_checkins_count': 28500,
        'analytics_available': true,
      });

      expect(statsModel.distributedPoints30d, 48290);
      expect(statsModel.activeStreakers, 3140);
      expect(statsModel.completionRate7d, 64.2);
      expect(statsModel.analyticsAvailable, true);

      final logModel = DailyStreakAuditLogModel.fromJson({
        'id': 'log-1',
        'setting_key': 'daily_login_streak',
        'previous_enabled': true,
        'new_enabled': false,
        'previous_points': 15,
        'new_points': 25,
        'changed_by_email': 'owner@shiftex.in',
        'created_at': '2026-11-17T04:13:38.6159Z',
      });

      expect(logModel.previousPoints, 15);
      expect(logModel.newPoints, 25);
      expect(logModel.newEnabled, false);
      expect(logModel.changedByEmail, 'owner@shiftex.in');
    });

    test('UpdateDailyStreakSettingsUseCase rejects invalid points', () async {
      final repo = FakeDailyStreakSettingsRepository();
      final useCase = UpdateDailyStreakSettingsUseCase(repository: repo);

      expect(
        () => useCase(enabled: true, pointsPerCheckin: 0),
        throwsArgumentError,
      );
      expect(
        () => useCase(enabled: true, pointsPerCheckin: -10),
        throwsArgumentError,
      );
      expect(
        () => useCase(enabled: true, pointsPerCheckin: 1001),
        throwsArgumentError,
      );
      expect(repo.updateCallCount, 0);
    });
  });

  group('DailyStreakSettingsBloc Tests', () {
    test('loads existing settings and statistics cleanly', () async {
      final repo = FakeDailyStreakSettingsRepository()
        ..storedStats = const DailyStreakStatisticsEntity(
          totalPointsDistributed: 1200,
          distributedPoints30d: 900,
          activeStreakers: 45,
          completionRate7d: 55.5,
          totalCheckinsCount: 60,
          analyticsAvailable: true,
        );
      final bloc = _createBloc(repo);

      bloc.add(const LoadDailyStreakSettingsRequested());
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<DailyStreakSettingsState>(
            (s) =>
                s.status == DailyStreakSettingsStatus.loaded &&
                s.hasLoadedOnce &&
                s.settings?.dailyLoginPoints == 15 &&
                s.draftPointsInput == '15' &&
                s.statistics.distributedPoints30d == 900 &&
                s.statistics.activeStreakers == 45 &&
                s.statistics.completionRate7d == 55.5,
          ),
        ),
      );
      await bloc.close();
    });

    test('toggles enable/disable, updates points via preset, saves & reloads',
        () async {
      final repo = FakeDailyStreakSettingsRepository();
      final bloc = _createBloc(repo);

      bloc.add(const LoadDailyStreakSettingsRequested());
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<DailyStreakSettingsState>(
            (s) => s.status == DailyStreakSettingsStatus.loaded,
          ),
        ),
      );

      bloc.add(const ToggleDailyStreakEnabledChanged(false));
      bloc.add(const SelectDailyStreakPresetPoints(25));
      bloc.add(const SaveDailyStreakSettingsRequested());

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<DailyStreakSettingsState>(
            (s) =>
                s.status == DailyStreakSettingsStatus.loaded &&
                s.settings?.dailyLoginEnabled == false &&
                s.settings?.dailyLoginPoints == 25 &&
                s.successMessage != null,
          ),
        ),
      );

      expect(repo.storedSettings.dailyLoginEnabled, false);
      expect(repo.storedSettings.dailyLoginPoints, 25);

      // Reload configuration and confirm persisted values
      bloc.add(const RefreshDailyStreakSettingsRequested());
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<DailyStreakSettingsState>(
            (s) =>
                s.status == DailyStreakSettingsStatus.loaded &&
                s.draftEnabled == false &&
                s.draftPointsInput == '25',
          ),
        ),
      );

      bloc.add(const LoadDailyStreakAuditLogsRequested());
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<DailyStreakSettingsState>(
            (s) => !s.isLoadingAuditLogs && s.auditLogs.length == 1,
          ),
        ),
      );

      await bloc.close();
    });

    test('rejects invalid point values without calling repository', () async {
      final repo = FakeDailyStreakSettingsRepository();
      final bloc = _createBloc(repo);

      bloc.add(const LoadDailyStreakSettingsRequested());
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<DailyStreakSettingsState>(
            (s) => s.status == DailyStreakSettingsStatus.loaded,
          ),
        ),
      );

      bloc.add(const DailyStreakPointsChanged('0'));
      bloc.add(const SaveDailyStreakSettingsRequested());

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<DailyStreakSettingsState>(
            (s) => s.validationError != null && !s.isDraftPointsValid,
          ),
        ),
      );

      expect(repo.updateCallCount, 0);
      await bloc.close();
    });

    test('handles unauthorized update and network errors properly', () async {
      final repo = FakeDailyStreakSettingsRepository()
        ..getSettingsError = Exception('SocketException: Network unreachable');
      final bloc = _createBloc(repo);

      bloc.add(const LoadDailyStreakSettingsRequested());
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<DailyStreakSettingsState>(
            (s) =>
                s.status == DailyStreakSettingsStatus.error &&
                s.errorMessage.contains('Network unreachable'),
          ),
        ),
      );

      repo.getSettingsError = null;
      bloc.add(const LoadDailyStreakSettingsRequested());
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<DailyStreakSettingsState>(
            (s) => s.status == DailyStreakSettingsStatus.loaded,
          ),
        ),
      );

      repo.updateSettingsError = Exception(
        'Unauthorized: Only authorized administrators can update streak rules.',
      );
      bloc.add(const SelectDailyStreakPresetPoints(10));
      bloc.add(const SaveDailyStreakSettingsRequested());

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<DailyStreakSettingsState>(
            (s) =>
                s.status == DailyStreakSettingsStatus.error &&
                s.errorMessage.contains('Unauthorized'),
          ),
        ),
      );

      await bloc.close();
    });
  });

  group('DailyStreakSettings Mobile UI Widget Tests', () {
    testWidgets(
        'renders on narrow 320px mobile screen without overflow and handles empty/populated stats',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 780));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool toggledValue = true;
      int? selectedPreset;
      bool savedTapped = false;
      bool auditTapped = false;

      final emptyState = DailyStreakSettingsState(
        status: DailyStreakSettingsStatus.loaded,
        hasLoadedOnce: true,
        draftEnabled: true,
        draftPointsInput: '15',
        settings: DailyStreakSettingsEntity(
          id: 'cfg-1',
          dailyLoginEnabled: true,
          dailyLoginPoints: 15,
          updatedAt: DateTime(2026, 11, 17),
        ),
        statistics: DailyStreakStatisticsEntity.empty(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: DailyStreakConfigCardWidget(
                state: emptyState,
                onToggleEnabled: (v) => toggledValue = v,
                onPointsChanged: (_) {},
                onPresetSelected: (p) => selectedPreset = p,
                onSavePressed: () => savedTapped = true,
                onViewAuditHistory: () => auditTapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Daily Login Streak'), findsOneWidget);
      expect(find.text('Awaiting Check-ins'), findsOneWidget);
      expect(
        find.text(
          'Analytics unavailable: no customer streak check-ins recorded yet.',
        ),
        findsOneWidget,
      );
      expect(find.text('06:00 AM IST (UTC+05:30)'), findsOneWidget);

      await tester.tap(find.text('+25 pts'));
      expect(selectedPreset, 25);

      await tester.tap(find.byType(Switch));
      expect(toggledValue, false);

      await tester.ensureVisible(find.text('View Detailed Audit History'));
      await tester.tap(find.text('View Detailed Audit History'));
      expect(auditTapped, true);

      await tester.ensureVisible(find.text('Save Rule Changes'));
      await tester.tap(find.text('Save Rule Changes'));
      expect(savedTapped, true);

      // Verify populated statistics state
      final populatedState = emptyState.copyWith(
        statistics: const DailyStreakStatisticsEntity(
          totalPointsDistributed: 50000,
          distributedPoints30d: 48290,
          activeStreakers: 3140,
          completionRate7d: 64.2,
          analyticsAvailable: true,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: DailyStreakConfigCardWidget(
                state: populatedState,
                onToggleEnabled: (_) {},
                onPointsChanged: (_) {},
                onPresetSelected: (_) {},
                onSavePressed: () {},
                onViewAuditHistory: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Healthy'), findsOneWidget);
      expect(find.text('3,140'), findsOneWidget);
      expect(find.text('64.2% 7d completion'), findsOneWidget);
    });

    testWidgets('shimmer and audit log widgets render cleanly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const DailyStreakCardShimmerWidget(),
                  const SizedBox(height: 16),
                  DailyStreakAuditLogItemWidget(
                    log: DailyStreakAuditLogEntity(
                      id: '1',
                      settingKey: 'daily_login_streak',
                      previousEnabled: true,
                      newEnabled: true,
                      previousPoints: 10,
                      newPoints: 15,
                      changedByEmail: 'admin@shiftex.in',
                      createdAt: DateTime(2026, 11, 17, 9, 30),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(DailyStreakCardShimmerWidget), findsOneWidget);
      expect(
        find.text('Points updated: 10 pts → 15 pts / login'),
        findsOneWidget,
      );
    });
  });
}
