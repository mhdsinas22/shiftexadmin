import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/core/routes/route_names.dart';
import 'package:shiftexadmin/core/widgets/pos_scanner_modal_widget.dart';

class AdminBottomNavBarWidget extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTabSelected;

  const AdminBottomNavBarWidget({
    super.key,
    required this.currentIndex,
    this.onTabSelected,
  });

  void handleTabTap(BuildContext context, int index) {
    if (onTabSelected != null) {
      onTabSelected!(index);
      return;
    }

    if (index == 99) {
      PosScannerModalWidget.show(context);
      return;
    }

    if (index == currentIndex) return;

    switch (index) {
      case 0:
        context.go(RouteNames.dashboardRoute);
        break;
      case 1:
        context.go(RouteNames.userManagementRoute);
        break;
      case 2:
        context.go(RouteNames.adsRoute);
        break;
      case 3:
        context.go(RouteNames.settingsRoute);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0)),
        boxShadow: [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildNavItem(
                  context: context,
                  index: 0,
                  label: 'Dashboard',
                  icon: Icons.grid_view_outlined,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context: context,
                  index: 1,
                  label: 'Users',
                  icon: Icons.people_outline_rounded,
                ),
              ),
              Expanded(child: _buildCenterScanButton(context)),
              Expanded(
                child: _buildNavItem(
                  context: context,
                  index: 2,
                  label: 'Ads',
                  icon: Icons.campaign_outlined,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context: context,
                  index: 3,
                  label: 'Settings',
                  icon: Icons.settings_outlined,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected ? AppColors.darkNavy : const Color(0xFF64748B);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => handleTabTap(context, index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 30,
            child: Center(child: Icon(icon, size: 22, color: color)),
          ),
          const SizedBox(height: 3),
          SizedBox(
            height: 14,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterScanButton(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => handleTabTap(context, 99),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 30,
            child: OverflowBox(
              maxHeight: 46,
              maxWidth: 46,
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.linkBlue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x332563EB),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 22,
                    color: AppColors.pureWhite,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          const SizedBox(
            height: 14,
            child: Text(
              'Scan POS',
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
