import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/core/di/injection_container.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/presentation/bloc/points_to_cash_bloc.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/presentation/bloc/points_to_cash_event.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/presentation/bloc/points_to_cash_state.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/presentation/widgets/points_to_cash_audit_log_item_widget.dart';

class PointsToCashAuditPage extends StatelessWidget {
  const PointsToCashAuditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PointsToCashBloc>(
      create: (_) =>
          sl<PointsToCashBloc>()
            ..add(const LoadPointsToCashAuditLogsRequested()),
      child: const PointsToCashAuditView(),
    );
  }
}

class PointsToCashAuditView extends StatelessWidget {
  const PointsToCashAuditView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.pureWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Points-to-Cash Rate History',
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
        child: BlocBuilder<PointsToCashBloc, PointsToCashState>(
          builder: (context, state) {
            if (state.isLoadingAuditLogs && state.auditLogs.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.linkBlue),
              );
            }

            if (state.auditLogs.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<PointsToCashBloc>().add(
                    const LoadPointsToCashAuditLogsRequested(),
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
                            'No Rate Amendments Yet',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Every Points-to-Cash conversion rate amendment appears here with immutable before/after values.',
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
                context.read<PointsToCashBloc>().add(
                  const LoadPointsToCashAuditLogsRequested(),
                );
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(16),
                itemCount: state.auditLogs.length,
                itemBuilder: (context, index) {
                  return PointsToCashAuditLogItemWidget(
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
