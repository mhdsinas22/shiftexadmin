import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/core/di/injection_container.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/presentation/bloc/daily_streak_settings_bloc.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/presentation/bloc/daily_streak_settings_event.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/presentation/bloc/daily_streak_settings_state.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/presentation/widgets/daily_streak_audit_log_item_widget.dart';

class DailyStreakAuditPage extends StatelessWidget {
  const DailyStreakAuditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DailyStreakSettingsBloc>(
      create: (_) => sl<DailyStreakSettingsBloc>()
        ..add(const LoadDailyStreakAuditLogsRequested()),
      child: const DailyStreakAuditView(),
    );
  }
}

class DailyStreakAuditView extends StatelessWidget {
  const DailyStreakAuditView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.pureWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Daily Streak Audit History',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: BlocBuilder<DailyStreakSettingsBloc, DailyStreakSettingsState>(
          builder: (context, state) {
            if (state.isLoadingAuditLogs && state.auditLogs.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.linkBlue),
              );
            }

            if (state.auditLogs.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<DailyStreakSettingsBloc>().add(
                        const LoadDailyStreakAuditLogsRequested(),
                      );
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 60),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.pureWhite,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.history_toggle_off_rounded,
                            size: 44,
                            color: AppColors.textHint,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No Rule Amendments Yet',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Every admin change to Daily Login Streak rules will appear here with before/after values and timestamp.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<DailyStreakSettingsBloc>().add(
                      const LoadDailyStreakAuditLogsRequested(),
                    );
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(16),
                itemCount: state.auditLogs.length,
                itemBuilder: (context, index) {
                  return DailyStreakAuditLogItemWidget(
                    log: state.auditLogs[index],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
