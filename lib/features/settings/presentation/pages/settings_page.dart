import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/core/di/injection_container.dart';
import 'package:shiftexadmin/core/routes/route_names.dart';
import 'package:shiftexadmin/features/settings/admin_access/presentation/bloc/admin_access_bloc.dart';
import 'package:shiftexadmin/features/settings/admin_access/presentation/bloc/admin_access_event.dart';
import 'package:shiftexadmin/features/settings/admin_access/presentation/bloc/admin_access_state.dart';
import 'package:shiftexadmin/features/settings/admin_access/presentation/widgets/admin_access_card_widget.dart';
import 'package:shiftexadmin/features/settings/admin_access/presentation/widgets/create_admin_account_sheet_widget.dart';
import 'package:shiftexadmin/features/settings/admin_access/presentation/widgets/manage_admin_operator_sheet_widget.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/presentation/bloc/daily_streak_settings_bloc.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/presentation/bloc/daily_streak_settings_event.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/presentation/bloc/daily_streak_settings_state.dart';
import 'package:shiftexadmin/features/settings/daily_streak_settings/presentation/widgets/daily_streak_config_card_widget.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/presentation/bloc/points_to_cash_bloc.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/presentation/bloc/points_to_cash_event.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/presentation/bloc/points_to_cash_state.dart';
import 'package:shiftexadmin/features/settings/presentation/widgets/admin_identity_card_widget.dart';
import 'package:shiftexadmin/features/settings/presentation/widgets/settings_header_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DailyStreakSettingsBloc>(
          create: (_) =>
              sl<DailyStreakSettingsBloc>()
                ..add(const LoadDailyStreakSettingsRequested()),
        ),
        BlocProvider<PointsToCashBloc>(
          create: (_) =>
              sl<PointsToCashBloc>()
                ..add(const LoadPointsToCashConfigRequested()),
        ),
        BlocProvider<AdminAccessBloc>(
          create: (_) =>
              sl<AdminAccessBloc>()..add(const LoadAdminAccessRequested()),
        ),
      ],
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
        backgroundColor: AppColors.pureWhite,
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
    User? user;
    try {
      user = Supabase.instance.client.auth.currentUser;
    } catch (_) {}

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: MultiBlocListener(
          listeners: [
            BlocListener<DailyStreakSettingsBloc, DailyStreakSettingsState>(
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
            ),
            BlocListener<PointsToCashBloc, PointsToCashState>(
              listenWhen: (previous, current) {
                final successChanged =
                    current.successMessage != null &&
                    current.successMessage!.isNotEmpty &&
                    previous.successMessage != current.successMessage;
                final errorChanged =
                    current.status == PointsToCashStatus.error &&
                    current.errorMessage.isNotEmpty &&
                    previous.errorMessage != current.errorMessage;
                return successChanged || errorChanged;
              },
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
                  context.read<DailyStreakSettingsBloc>().add(
                    const RefreshDailyStreakSettingsRequested(),
                  );
                } else if (state.status == PointsToCashStatus.error &&
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
            ),
            BlocListener<AdminAccessBloc, AdminAccessState>(
              listenWhen: (previous, current) {
                final successChanged =
                    current.successMessage != null &&
                    current.successMessage!.isNotEmpty &&
                    previous.successMessage != current.successMessage;
                final errorChanged =
                    current.status == AdminAccessStatus.error &&
                    current.errorMessage.isNotEmpty &&
                    previous.errorMessage != current.errorMessage;
                return successChanged || errorChanged;
              },
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
                } else if (state.status == AdminAccessStatus.error &&
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
            ),
          ],
          child: BlocBuilder<DailyStreakSettingsBloc, DailyStreakSettingsState>(
            builder: (context, streakState) {
              final streakBloc = context.read<DailyStreakSettingsBloc>();
              final rateBloc = context.read<PointsToCashBloc>();
              final adminAccessBloc = context.read<AdminAccessBloc>();

              return RefreshIndicator(
                color: AppColors.linkBlue,
                onRefresh: () async {
                  streakBloc.add(const RefreshDailyStreakSettingsRequested());
                  rateBloc.add(const RefreshPointsToCashConfigRequested());
                  adminAccessBloc.add(const RefreshAdminAccessRequested());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BlocBuilder<AdminAccessBloc, AdminAccessState>(
                        buildWhen: (prev, curr) =>
                            prev.currentAdmin != curr.currentAdmin,
                        builder: (context, accessState) {
                          return SettingsHeaderWidget(
                            profileInitials: accessState.currentAdmin?.initials,
                            onNotificationPressed: () {
                              streakBloc.add(
                                const RefreshDailyStreakSettingsRequested(),
                              );
                              rateBloc.add(
                                const RefreshPointsToCashConfigRequested(),
                              );
                              adminAccessBloc.add(
                                const RefreshAdminAccessRequested(),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Settings & terminal rules synced.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            onProfilePressed: () {
                              adminAccessBloc.add(
                                const RefreshAdminAccessRequested(),
                              );
                              final name =
                                  accessState.currentAdmin?.fullName ??
                                  user?.email ??
                                  'Admin Operator';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Signed in as $name'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Admin Identity Card synced with AdminAccessBloc
                      BlocBuilder<AdminAccessBloc, AdminAccessState>(
                        buildWhen: (prev, curr) =>
                            prev.currentAdmin != curr.currentAdmin,
                        builder: (context, accessState) {
                          return AdminIdentityCardWidget(
                            email: user?.email ?? 'admin@shiftex.in',
                            currentAdmin: accessState.currentAdmin,
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Daily Login Streak Configuration Card
                      BlocBuilder<PointsToCashBloc, PointsToCashState>(
                        buildWhen: (prev, curr) =>
                            prev.config?.pointsPerRupee !=
                            curr.config?.pointsPerRupee,
                        builder: (context, rateState) {
                          return DailyStreakConfigCardWidget(
                            state: streakState,
                            activePointsPerRupee:
                                rateState.config?.pointsPerRupee,
                            onToggleEnabled: (enabled) {
                              streakBloc.add(
                                ToggleDailyStreakEnabledChanged(enabled),
                              );
                            },
                            onPointsChanged: (raw) {
                              streakBloc.add(DailyStreakPointsChanged(raw));
                            },
                            onPresetSelected: (pts) {
                              streakBloc.add(
                                SelectDailyStreakPresetPoints(pts),
                              );
                            },
                            onSavePressed: () {
                              FocusScope.of(context).unfocus();
                              streakBloc.add(
                                const SaveDailyStreakSettingsRequested(),
                              );
                            },
                            onViewAuditHistory: () {
                              context.push(RouteNames.dailyStreakAuditRoute);
                            },
                            onRetryLoad: () {
                              streakBloc.add(
                                const LoadDailyStreakSettingsRequested(),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Admin Access & Permission Management Card
                      BlocBuilder<AdminAccessBloc, AdminAccessState>(
                        builder: (context, accessState) {
                          return AdminAccessCardWidget(
                            state: accessState,
                            onCreateAdminPressed: () {
                              if (!accessState.canCreateAdminAccount) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Only authorized Super Admins can create new Admin accounts.',
                                    ),
                                    backgroundColor: AppColors.purered,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
                              CreateAdminAccountSheetWidget.show(
                                context,
                                bloc: adminAccessBloc,
                              );
                            },
                            onOperatorTapped: (operatorItem) {
                              ManageAdminOperatorSheetWidget.show(
                                context,
                                operatorItem: operatorItem,
                                canManage: accessState.canManageAdmins,
                                bloc: adminAccessBloc,
                              );
                            },
                            onRetryLoad: () {
                              adminAccessBloc.add(
                                const LoadAdminAccessRequested(),
                              );
                            },
                          );
                        },
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
                      const SizedBox(height: 10),
                      const Center(
                        child: Text(
                          'Encrypted terminal session token expires automatically after 15\nmin idle.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10.5,
                            color: AppColors.textSecondary,
                            height: 1.35,
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
      ),
    );
  }
}
