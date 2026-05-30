import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routes.dart';
import '../theme_controller.dart';
import '../util/breakpoints.dart';
import '../util/platform_shell.dart';
import 'app_actions.dart';
import 'app_drawer.dart';
import 'app_nav_list.dart';
import 'desktop_shell.dart';
import 'offline_notice.dart';
import 'theme_picker.dart';
import 'update_banner.dart';

/// Adaptive application shell.
///
/// Implements the Material 3 layout guidance:
/// - Compact (< 600 dp): standard modal navigation drawer
/// - Medium (600-839 dp): permanent [NavigationRail] on the left
/// - Expanded (>= 840 dp): permanent navigation drawer on the left
///
/// Pages should wrap their body in [AppShell] rather than build their own
/// [Scaffold] + [AppBar] + drawer.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.body,
    required this.selectedRoute,
    this.actions,
    this.floatingActionButton,
    this.bodyPadding,
  });

  final String title;
  final Widget body;
  final String selectedRoute;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final EdgeInsetsGeometry? bodyPadding;

  @override
  Widget build(BuildContext context) {
    if (useDesktopShell) {
      return DesktopShell(
        title: title,
        body: body,
        selectedRoute: selectedRoute,
        actions: actions,
        floatingActionButton: floatingActionButton,
        bodyPadding: bodyPadding,
      );
    }

    final List<Widget> appBarActions = <Widget>[
      ...?actions,
      const AppShareMenu(),
    ];

    final Widget wrappedBody = OfflineNotice(child: UpdateBanner(child: body));

    if (Breakpoints.isCompact(context)) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: appBarActions,
        ),
        drawer: AppDrawer(currentRoute: selectedRoute),
        body: _padded(wrappedBody),
        floatingActionButton: floatingActionButton,
      );
    }

    if (Breakpoints.isMedium(context)) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: appBarActions,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Row(
            children: <Widget>[
              _AppRail(selectedRoute: selectedRoute),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(child: _padded(wrappedBody)),
            ],
          ),
        ),
        floatingActionButton: floatingActionButton,
      );
    }

    // Expanded: permanent drawer
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: appBarActions,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 280,
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: AppNavList(currentRoute: selectedRoute),
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: _padded(wrappedBody)),
          ],
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _padded(Widget child) {
    if (bodyPadding == null) return child;
    return Padding(padding: bodyPadding!, child: child);
  }
}

class _AppRail extends StatelessWidget {
  const _AppRail({required this.selectedRoute});

  final String selectedRoute;

  static const List<_RailDest> _destinations = <_RailDest>[
    _RailDest(AppRoutes.home, Icons.home_outlined, Icons.home, 'Home'),
    _RailDest(AppRoutes.roms, Icons.android_outlined, Icons.android, 'ROMs'),
    _RailDest(
      AppRoutes.recoveries,
      Icons.restore,
      Icons.restore,
      'Recoveries',
    ),
    _RailDest(
      AppRoutes.roots,
      Icons.shield_outlined,
      Icons.shield,
      'Root',
    ),
    _RailDest(
      AppRoutes.devices,
      Icons.smartphone_outlined,
      Icons.smartphone,
      'Devices',
    ),
    _RailDest(
      AppRoutes.instructions,
      Icons.menu_book_outlined,
      Icons.menu_book,
      'Guide',
    ),
    _RailDest(
      AppRoutes.treble,
      Icons.layers_outlined,
      Icons.layers,
      'Treble',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = _destinations.indexWhere(
      (_RailDest d) => d.route == selectedRoute,
    );
    return NavigationRail(
      selectedIndex: selectedIndex >= 0 ? selectedIndex : 0,
      labelType: NavigationRailLabelType.all,
      onDestinationSelected: (int i) {
        final String route = _destinations[i].route;
        if (route == selectedRoute) return;
        context.go(route);
      },
      destinations: <NavigationRailDestination>[
        for (final _RailDest d in _destinations)
          NavigationRailDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: Text(d.label),
          ),
      ],
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeController.instance,
              builder: (BuildContext context, ThemeMode mode, _) {
                return IconButton(
                  tooltip: 'Appearance',
                  icon: Icon(_railThemeIcon(mode)),
                  onPressed: () => showThemePicker(context),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

IconData _railThemeIcon(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return Icons.light_mode_outlined;
    case ThemeMode.dark:
      return Icons.dark_mode_outlined;
    case ThemeMode.system:
      return Icons.brightness_auto_outlined;
  }
}

class _RailDest {
  const _RailDest(this.route, this.icon, this.selectedIcon, this.label);
  final String route;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
