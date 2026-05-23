import 'package:flutter/material.dart';

import 'app_nav_list.dart';

/// Modal navigation drawer used on compact (phone) widths.
///
/// Wide widths use the same content via [AppNavList] embedded directly
/// into [AppShell] without this Drawer wrapper.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, this.currentRoute});

  final String? currentRoute;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: AppNavList(
          currentRoute: currentRoute,
          onNavigate: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
