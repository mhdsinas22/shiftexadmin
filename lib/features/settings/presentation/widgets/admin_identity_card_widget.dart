import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_operator_entity.dart';

class AdminIdentityCardWidget extends StatelessWidget {
  final String email;
  final AdminOperatorEntity? currentAdmin;

  const AdminIdentityCardWidget({
    super.key,
    required this.email,
    this.currentAdmin,
  });

  String get _resolvedEmail {
    if (currentAdmin != null && currentAdmin!.email.trim().isNotEmpty) {
      return currentAdmin!.email.trim();
    }
    return email;
  }

  String get _displayName {
    if (currentAdmin != null && currentAdmin!.fullName.trim().isNotEmpty) {
      return currentAdmin!.fullName.trim();
    }
    final prefix = _resolvedEmail.split('@').first;
    if (prefix.isEmpty) return 'ShiftEx Admin';
    final parts = prefix
        .split(RegExp(r'[._-]+'))
        .where((p) => p.isNotEmpty)
        .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
        .toList();
    return parts.isEmpty ? 'ShiftEx Admin' : parts.join(' ');
  }

  String get _roleBadge {
    if (currentAdmin != null) {
      return currentAdmin!.isKeyMaster
          ? 'Owner'
          : currentAdmin!.role.displayLabel;
    }
    return 'Owner';
  }

  String get _initials {
    if (currentAdmin != null) {
      return currentAdmin!.initials;
    }
    final words = _displayName.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    if (words.isNotEmpty && words.first.length >= 2) {
      return words.first.substring(0, 2).toUpperCase();
    }
    return 'AD';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(18),
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
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: AppColors.darkNavy,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _initials,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.pureWhite,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.eifGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.pureWhite,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 8,
                        color: AppColors.pureWhite,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _roleBadge,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.purple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _resolvedEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.vpn_key_outlined,
                  size: 15,
                  color: AppColors.linkBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentAdmin != null
                        ? 'Hardware Key HSM • ${currentAdmin!.terminalAssignment} • Validated'
                        : 'Supabase Auth & admin_users • Verified',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.linkBlue,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
