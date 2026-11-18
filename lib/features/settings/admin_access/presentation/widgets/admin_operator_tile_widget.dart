import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_operator_entity.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_permission.dart';

class AdminOperatorTileWidget extends StatelessWidget {
  final AdminOperatorEntity operatorItem;
  final VoidCallback? onTap;

  const AdminOperatorTileWidget({
    super.key,
    required this.operatorItem,
    this.onTap,
  });

  Color get _avatarBgColor {
    if (operatorItem.isKeyMaster || operatorItem.isCurrentUser) {
      return const Color(0xFF090D16);
    }
    switch (operatorItem.role) {
      case AdminRoleType.superAdmin:
        return const Color(0xFF1E293B);
      case AdminRoleType.storeManager:
        return const Color(0xFFE0E7FF);
      case AdminRoleType.auditor:
        return const Color(0xFFF3E8FF);
    }
  }

  Color get _avatarTextColor {
    if (operatorItem.isKeyMaster ||
        operatorItem.isCurrentUser ||
        operatorItem.role == AdminRoleType.superAdmin) {
      return AppColors.pureWhite;
    }
    switch (operatorItem.role) {
      case AdminRoleType.superAdmin:
        return AppColors.pureWhite;
      case AdminRoleType.storeManager:
        return const Color(0xFF1D4ED8);
      case AdminRoleType.auditor:
        return const Color(0xFF7E22CE);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyMasterBadge = operatorItem.isKeyMaster;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('admin_operator_tile_${operatorItem.userId}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _avatarBgColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  operatorItem.initials,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _avatarTextColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      operatorItem.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      operatorItem.displaySubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 0,
                child: isKeyMasterBadge
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.pureWhite,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          operatorItem.displayRightBadge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      )
                    : Text(
                        operatorItem.displayRightBadge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: operatorItem.isActive
                              ? AppColors.textSecondary
                              : AppColors.purered,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
