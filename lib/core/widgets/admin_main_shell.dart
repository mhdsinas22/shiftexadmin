import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftexadmin/features/user_management/presentation/widgets/admin_bottom_nav_bar_widget.dart';

class AdminMainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AdminMainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AdminBottomNavBarWidget(
        currentIndex: navigationShell.currentIndex,
        onTabSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
