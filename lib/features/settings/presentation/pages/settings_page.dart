import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/core/constants/app_texts.dart';
import 'package:shiftexadmin/core/di/injection_container.dart';
import 'package:shiftexadmin/core/routes/route_names.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/presentation/bloc/daily_streak_settings_bloc.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/presentation/bloc/daily_streak_settings_event.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/presentation/bloc/daily_streak_settings_state.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/presentation/widgets/daily_streak_config_card_widget.dart';
import 'package:shiftexadmin/features/settings/presentation/widgets/admin_identity_card_widget.dart';
import 'package:shiftexadmin/features/settings/presentation/widgets/points_to_cash_card_widget.dart';
import 'package:shiftexadmin/features/settings/presentation/widgets/settings_header_widget.dart';
import 'package:shiftexadmin/features/settings/presentation/widgets/settings_tile_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DailyStreakSettingsBloc>(
      create: (_) => sl<DailyStreakSettingsBloc>()
        ..add(const LoadDailyStreakSettingsRequested()),
      child: const SettingsView(),
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  Future<void> _signOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Sign Out'),
        content: const Text('Are you sure you want to end your admin session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purered,
              foregroundColor: AppColors.pureWhite,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
      if (context.mounted) {
        context.go(RouteNames.loginRoute);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: BlocConsumer<DailyStreakSettingsBloc, DailyStreakSettingsState>(
          listener: (context, state) {
            if (state.successMessage != null &&
                state.successMessage!.isNotEmpty) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.eifGreen,
                  content: Text(
                    state.successMessage!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: AppColors.pureWhite,
                    ),
                  ),
                ),
              );
            } else if (state.status == DailyStreakSettingsStatus.error &&
                state.errorMessage.isNotEmpty) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.purered,
                  content: Text(
                    state.errorMessage,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: AppColors.pureWhite,
                    ),
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            final bloc = context.read<DailyStreakSettingsBloc>();

            return RefreshIndicator(
              color: AppColors.linkBlue,
              onRefresh: () async {
                bloc.add(const RefreshDailyStreakSettingsRequested());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SettingsHeaderWidget(),
                    const SizedBox(height: 16),

                    // Admin Identity Card
                    AdminIdentityCardWidget(
                      email: user?.email ?? 'admin@shiftex.in',
                    ),
                    const SizedBox(height: 16),

                    // Daily Login Streak Configuration Card
                    DailyStreakConfigCardWidget(
                      state: state,
                      onToggleEnabled: (enabled) {
                        bloc.add(ToggleDailyStreakEnabledChanged(enabled));
                      },
                      onPointsChanged: (raw) {
                        bloc.add(DailyStreakPointsChanged(raw));
                      },
                      onPresetSelected: (pts) {
                        bloc.add(SelectDailyStreakPresetPoints(pts));
                      },
                      onSavePressed: () {
                        FocusScope.of(context).unfocus();
                        bloc.add(const SaveDailyStreakSettingsRequested());
                      },
                      onViewAuditHistory: () {
                        context.push(RouteNames.dailyStreakAuditRoute);
                      },
                      onRetryLoad: () {
                        bloc.add(const LoadDailyStreakSettingsRequested());
                      },
                    ),
                    const SizedBox(height: 16),

                    // Points-to-Cash Valuation Card (from reward_settings rate)
                    PointsToCashCardWidget(
                      pointsToInrRate: state.settings?.pointsToInrRate ?? 0.10,
                    ),
                    const SizedBox(height: 20),

                    // Section: Database & Backend
                    AppTexts.bold(
                      'Database & Backend',
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.pureWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Column(
                        children: [
                          SettingsTileWidget(
                            icon: Icons.cloud_done_outlined,
                            title: 'Supabase Project',
                            subtitle: 'hefscvlbskukbnigrbcz • ap-southeast-1',
                            trailing: const Text(
                              'Connected',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.eifGreen,
                              ),
                            ),
                            onTap: () {},
                          ),
                          const Divider(height: 1, indent: 56),
                          SettingsTileWidget(
                            icon: Icons.verified_user_outlined,
                            title: 'Role-Based Access Control',
                            subtitle:
                                'Admin verification via admin_users & RLS',
                            trailing: const Text(
                              'Enforced',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.eifGreen,
                              ),
                            ),
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Sign Out Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _signOut(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.purered,
                          side: const BorderSide(color: Color(0xFFFCA5A5)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          backgroundColor: const Color(0xFFFEF2F2),
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text(
                          'Log Out of Admin Console',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
