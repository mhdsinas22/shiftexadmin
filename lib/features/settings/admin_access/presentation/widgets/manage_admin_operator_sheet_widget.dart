import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_operator_entity.dart';
import 'package:shiftexadmin/features/settings/admin_access/domain/entities/admin_permission.dart';
import 'package:shiftexadmin/features/settings/admin_access/presentation/bloc/admin_access_bloc.dart';
import 'package:shiftexadmin/features/settings/admin_access/presentation/bloc/admin_access_event.dart';

class ManageAdminOperatorSheetWidget extends StatefulWidget {
  final AdminOperatorEntity operatorItem;
  final bool canManage;
  final AdminAccessBloc bloc;

  const ManageAdminOperatorSheetWidget({
    super.key,
    required this.operatorItem,
    required this.canManage,
    required this.bloc,
  });

  static Future<void> show(
    BuildContext context, {
    required AdminOperatorEntity operatorItem,
    required bool canManage,
    required AdminAccessBloc bloc,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ManageAdminOperatorSheetWidget(
        operatorItem: operatorItem,
        canManage: canManage,
        bloc: bloc,
      ),
    );
  }

  @override
  State<ManageAdminOperatorSheetWidget> createState() =>
      _ManageAdminOperatorSheetWidgetState();
}

class _ManageAdminOperatorSheetWidgetState
    extends State<ManageAdminOperatorSheetWidget> {
  late AdminRoleType _selectedRole;
  late TextEditingController _terminalController;
  late Set<String> _selectedPermissions;
  late String _status;

  bool get _isProtectedAccount =>
      widget.operatorItem.isKeyMaster || widget.operatorItem.isCurrentUser;

  bool get _isEditable => widget.canManage && !_isProtectedAccount;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.operatorItem.role;
    _terminalController = TextEditingController(
      text: widget.operatorItem.terminalAssignment,
    );
    _selectedPermissions = Set<String>.from(widget.operatorItem.permissions);
    _status = widget.operatorItem.status;
  }

  @override
  void dispose() {
    _terminalController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (!_isEditable) return;
    widget.bloc.add(
      UpdateAdminOperatorPermissionsRequested(
        targetUserId: widget.operatorItem.userId,
        role: _selectedRole,
        terminalAssignment: _terminalController.text.trim().isNotEmpty
            ? _terminalController.text.trim()
            : _selectedRole.defaultTerminal,
        permissions: _selectedPermissions.toList(),
        status: _status,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 56),
      padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.operatorItem.displayTitle,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.operatorItem.email,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.operatorItem.displayRightBadge,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_isProtectedAccount) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 18,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.operatorItem.isKeyMaster
                            ? 'Key Master Owner Protection: This primary owner credential cannot be demoted, suspended, or locked out.'
                            : 'Self-Lockout Protection: You cannot demote or suspend your own active admin session.',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            const Text(
              'Assigned Role',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: AdminRoleType.values.map((role) {
                final isSelected = role == _selectedRole;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: role == AdminRoleType.values.last ? 0 : 8,
                    ),
                    child: InkWell(
                      onTap: !_isEditable
                          ? null
                          : () {
                              setState(() {
                                _selectedRole = role;
                                _terminalController.text = role.defaultTerminal;
                                _selectedPermissions = Set<String>.from(
                                  role.defaultPermissions,
                                );
                              });
                            },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF090D16)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF090D16)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          role.displayLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.pureWhite
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            const Text(
              'Terminal / Scope Assignment',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _terminalController,
              enabled: _isEditable,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Granular Permissions',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: AdminPermission.allPermissions.map((perm) {
                final selected = _selectedPermissions.contains(perm);
                return FilterChip(
                  label: Text(
                    AdminPermission.labelFor(perm),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.pureWhite
                          : AppColors.textPrimary,
                    ),
                  ),
                  selected: selected,
                  selectedColor: AppColors.linkBlue,
                  checkmarkColor: AppColors.pureWhite,
                  backgroundColor: const Color(0xFFF1F5F9),
                  visualDensity: VisualDensity.compact,
                  onSelected: !_isEditable
                      ? null
                      : (_) {
                          setState(() {
                            if (_selectedPermissions.contains(perm)) {
                              if (_selectedPermissions.length > 1) {
                                _selectedPermissions.remove(perm);
                              }
                            } else {
                              _selectedPermissions.add(perm);
                            }
                          });
                        },
                );
              }).toList(),
            ),
            if (_isEditable) ...[
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Operator Account Status',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Switch.adaptive(
                    value: _status == 'active',
                    activeTrackColor: AppColors.eifGreen,
                    onChanged: (val) {
                      setState(() {
                        _status = val ? 'active' : 'suspended';
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  key: const Key('save_operator_permissions_button'),
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF090D16),
                    foregroundColor: AppColors.pureWhite,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Save Operator Permissions',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
