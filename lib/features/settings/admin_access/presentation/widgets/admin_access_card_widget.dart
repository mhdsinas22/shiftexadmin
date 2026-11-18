import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_operator_entity.dart';
import 'package:shiftexadmin/features/settings/admin_access/presentation/bloc/admin_access_state.dart';
import 'package:shiftexadmin/features/settings/admin_access/presentation/widgets/admin_operator_tile_widget.dart';

class AdminAccessCardWidget extends StatelessWidget {
  final AdminAccessState state;
  final VoidCallback onCreateAdminPressed;
  final ValueChanged<AdminOperatorEntity> onOperatorTapped;
  final VoidCallback onRetryLoad;

  const AdminAccessCardWidget({
    super.key,
    required this.state,
    required this.onCreateAdminPressed,
    required this.onOperatorTapped,
    required this.onRetryLoad,
  });

  @override
  Widget build(BuildContext context) {
    final count = state.operatorsCount > 0
        ? state.operatorsCount
        : state.operators.length;
    final subtitleText =
        '$count registered console ${count == 1 ? 'operator' : 'operators'}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 20,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Access',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitleText,
                      key: const Key('admin_access_operators_count_text'),
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
            ],
          ),
          const SizedBox(height: 14),
          if (state.status == AdminAccessStatus.loading &&
              !state.hasLoadedOnce)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.linkBlue,
                  ),
                ),
              ),
            )
          else if (state.status == AdminAccessStatus.error &&
              state.operators.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    state.errorMessage.isNotEmpty
                        ? state.errorMessage
                        : 'Unable to load console operators.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.purered,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onRetryLoad,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (state.operators.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No registered console operators found.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.operators.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final op = state.operators[index];
                return AdminOperatorTileWidget(
                  operatorItem: op,
                  onTap: () => onOperatorTapped(op),
                );
              },
            ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: TextButton.icon(
              key: const Key('create_admin_account_button'),
              onPressed: state.status == AdminAccessStatus.submitting
                  ? null
                  : onCreateAdminPressed,
              icon: const Icon(
                Icons.person_add_alt_1_outlined,
                size: 17,
                color: AppColors.textPrimary,
              ),
              label: const Text(
                '+ Create Admin Account',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFF1F5F9)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Multi-sig enforcement: High liability changes require 2 Super Admin approvals',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
