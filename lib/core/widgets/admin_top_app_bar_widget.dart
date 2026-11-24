import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/core/di/injection_container.dart';
import 'package:shiftexadmin/core/routes/route_names.dart';
import 'package:shiftexadmin/features/authentication/presentation/widgets/login_logo_widget.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_operator_entity.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/usecases/get_admin_access_overview_usecase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shared top application bar matching the Dashboard AppBar design across
/// Dashboard, Users, Scan POS, Ads, and Settings screens.
class AdminTopAppBarWidget extends StatelessWidget {
  final String? profileInitials;
  final bool hasUnreadNotifications;
  final VoidCallback? onLogoPressed;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onProfilePressed;
  final Key? notificationButtonKey;
  final Key? profileButtonKey;

  const AdminTopAppBarWidget({
    super.key,
    this.profileInitials,
    this.hasUnreadNotifications = false,
    this.onLogoPressed,
    this.onNotificationPressed,
    this.onProfilePressed,
    this.notificationButtonKey,
    this.profileButtonKey,
  });

  String _initialsFromText(String raw) {
    final parts = raw
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'AD';
    if (parts.length == 1) {
      return parts.first.length >= 2
          ? parts.first.substring(0, 2).toUpperCase()
          : parts.first.toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _resolveFallbackInitials() {
    if (profileInitials != null && profileInitials!.trim().isNotEmpty) {
      return profileInitials!.trim().toUpperCase();
    }
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final fullName = user.userMetadata?['full_name']?.toString() ?? '';
        if (fullName.trim().isNotEmpty) {
          return _initialsFromText(fullName);
        }
        final emailPrefix = (user.email ?? '').split('@').first.trim();
        if (emailPrefix.isNotEmpty) {
          return _initialsFromText(emailPrefix);
        }
      }
    } catch (_) {
      // Safe fallback when Supabase is not initialized (e.g. isolated widget tests).
    }
    return 'AD';
  }

  Widget _buildBar(BuildContext context, String resolvedInitials) {
    final logoWidget = Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Center(child: LoginLogoWidget(size: 40, iconSize: 16)),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (onLogoPressed != null)
          GestureDetector(
            key: const Key('app_bar_logo_button'),
            onTap: onLogoPressed,
            child: logoWidget,
          )
        else
          GestureDetector(
            key: const Key('app_bar_logo_button'),
            onTap: () {
              final router = GoRouter.maybeOf(context);
              if (router != null) {
                router.go(RouteNames.dashboardRoute);
              }
            },
            child: logoWidget,
          ),
        Row(
          children: [
            GestureDetector(
              key: notificationButtonKey,
              onTap: onNotificationPressed ?? () {},
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.pureWhite,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                    if (hasUnreadNotifications)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.purered,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              key: profileButtonKey,
              onTap:
                  onProfilePressed ??
                  () {
                    final router = GoRouter.maybeOf(context);
                    if (router != null) {
                      router.go(RouteNames.settingsRoute);
                    }
                  },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF090D16),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.pureWhite, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/admin_avatar.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFF090D16),
                        alignment: Alignment.center,
                        child: Text(
                          resolvedInitials,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pureWhite,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (profileInitials != null && profileInitials!.trim().isNotEmpty) {
      return _buildBar(context, profileInitials!.trim().toUpperCase());
    }

    if (getIt.isRegistered<GetAdminAccessOverviewUseCase>()) {
      final useCase = getIt<GetAdminAccessOverviewUseCase>();
      return StreamBuilder<AdminOperatorEntity?>(
        stream: useCase.currentAdminStream,
        initialData: useCase.cachedCurrentAdmin,
        builder: (context, snapshot) {
          final initials = snapshot.data?.initials ?? _resolveFallbackInitials();
          return _buildBar(context, initials);
        },
      );
    }

    return _buildBar(context, _resolveFallbackInitials());
  }
}
