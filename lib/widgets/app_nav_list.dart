import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../routes.dart';
import '../theme_controller.dart';
import 'about_dialog.dart';
import 'support_dialog.dart';
import 'theme_picker.dart';
import 'update_nav_tile.dart';

/// Shared list of navigation tiles used by both the modal [AppDrawer]
/// (compact width) and the permanent side panel on expanded widths.
class AppNavList extends StatelessWidget {
  const AppNavList({
    super.key,
    required this.currentRoute,
    this.onNavigate,
  });

  final String? currentRoute;

  /// Called before each navigation action. Used by the modal drawer to
  /// pop itself before pushing a new route.
  final VoidCallback? onNavigate;

  void _go(BuildContext context, String route) {
    onNavigate?.call();
    if (currentRoute == route) return;
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Column(
      children: <Widget>[
        DrawerHeader(
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
          ),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 32,
                backgroundColor: scheme.surface,
                backgroundImage: const AssetImage('images/launcher.png'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Custom RR',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Custom ROMs & Recoveries',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: <Widget>[
              _NavTile(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'Home',
                route: AppRoutes.home,
                currentRoute: currentRoute,
                onTap: () => _go(context, AppRoutes.home),
              ),
              _NavTile(
                icon: Icons.android_outlined,
                selectedIcon: Icons.android,
                label: 'Custom ROMs',
                route: AppRoutes.roms,
                currentRoute: currentRoute,
                onTap: () => _go(context, AppRoutes.roms),
              ),
              _NavTile(
                icon: Icons.restore,
                selectedIcon: Icons.restore,
                label: 'Custom Recoveries',
                route: AppRoutes.recoveries,
                currentRoute: currentRoute,
                onTap: () => _go(context, AppRoutes.recoveries),
              ),
              _NavTile(
                icon: Icons.shield_outlined,
                selectedIcon: Icons.shield,
                label: 'Root',
                route: AppRoutes.roots,
                currentRoute: currentRoute,
                onTap: () => _go(context, AppRoutes.roots),
              ),
              _NavTile(
                icon: Icons.smartphone_outlined,
                selectedIcon: Icons.smartphone,
                label: 'Devices',
                route: AppRoutes.devices,
                currentRoute: currentRoute,
                onTap: () => _go(context, AppRoutes.devices),
              ),
              _NavTile(
                icon: Icons.travel_explore_outlined,
                selectedIcon: Icons.travel_explore,
                label: 'Find my phone',
                route: AppRoutes.findPhone,
                currentRoute: currentRoute,
                onTap: () => _go(context, AppRoutes.findPhone),
              ),
              _NavTile(
                icon: Icons.star_outline_rounded,
                selectedIcon: Icons.star_rounded,
                label: 'My Devices',
                route: AppRoutes.wishlist,
                currentRoute: currentRoute,
                onTap: () => _go(context, AppRoutes.wishlist),
              ),
              _NavTile(
                icon: Icons.terminal_outlined,
                selectedIcon: Icons.terminal,
                label: 'Flash script',
                route: AppRoutes.flashScript,
                currentRoute: currentRoute,
                onTap: () => _go(context, AppRoutes.flashScript),
              ),
              _NavTile(
                icon: Icons.menu_book_outlined,
                selectedIcon: Icons.menu_book,
                label: 'Instructions',
                route: AppRoutes.instructions,
                currentRoute: currentRoute,
                onTap: () => _go(context, AppRoutes.instructions),
              ),
              _NavTile(
                icon: Icons.layers_outlined,
                selectedIcon: Icons.layers,
                label: 'Treble & GSI',
                route: AppRoutes.treble,
                currentRoute: currentRoute,
                onTap: () => _go(context, AppRoutes.treble),
              ),
              _NavTile(
                icon: Icons.forum_outlined,
                selectedIcon: Icons.forum,
                label: 'Community',
                route: AppRoutes.community,
                currentRoute: currentRoute,
                onTap: () => _go(context, AppRoutes.community),
              ),
              const Divider(),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeController.instance,
                builder: (BuildContext context, ThemeMode mode, _) {
                  return ListTile(
                    leading: Icon(_themeIcon(mode)),
                    title: const Text('Appearance'),
                    subtitle: Text(_themeLabel(mode)),
                    onTap: () {
                      onNavigate?.call();
                      showThemePicker(context);
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite_outline),
                title: const Text('Support Us'),
                onTap: () {
                  onNavigate?.call();
                  showSupportDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Share the app'),
                onTap: () async {
                  onNavigate?.call();
                  await SharePlus.instance.share(
                    ShareParams(
                      text:
                          'Check out Custom RR: discover Android custom ROMs and recoveries! '
                          'Open source on GitHub: https://github.com/monsiu/Custom-RR',
                      subject: 'Custom RR',
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: const Text('Contact Us'),
                onTap: () async {
                  onNavigate?.call();
                  final Uri uri = Uri(
                    scheme: 'mailto',
                    path: 'contactmonsiu@gmail.com',
                    query: 'subject=Custom RR Feedback',
                  );
                  await launchUrl(uri);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About'),
                onTap: () {
                  onNavigate?.call();
                  showCustomAboutDialog(context);
                },
              ),
              UpdateNavTile(onNavigate: onNavigate),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
    required this.currentRoute,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;
  final String? currentRoute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool selected = currentRoute == route;
    return ListTile(
      leading: Icon(selected ? selectedIcon : icon),
      title: Text(label),
      selected: selected,
      onTap: onTap,
    );
  }
}

IconData _themeIcon(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return Icons.light_mode_outlined;
    case ThemeMode.dark:
      return Icons.dark_mode_outlined;
    case ThemeMode.system:
      return Icons.brightness_auto_outlined;
  }
}

String _themeLabel(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'Light';
    case ThemeMode.dark:
      return 'Dark';
    case ThemeMode.system:
      return 'System default';
  }
}
