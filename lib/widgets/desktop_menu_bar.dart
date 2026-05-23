import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../routes.dart';
import '../theme_controller.dart';
import 'about_dialog.dart';

/// Wraps [child] in a single, app-wide [PlatformMenuBar].
///
/// Must be mounted exactly once (the Flutter framework locks the menu
/// delegate to one context). Place it in `MaterialApp.router`'s
/// `builder:` so it persists across every route navigation.
class DesktopMenuBar extends StatelessWidget {
  const DesktopMenuBar({
    super.key,
    required this.child,
    required this.router,
  });

  final Widget child;
  final GoRouter router;

  static const String _repoUrl = 'https://github.com/monsiu/Custom-RR';

  @override
  Widget build(BuildContext context) {
    return PlatformMenuBar(
      menus: <PlatformMenuItem>[
        PlatformMenu(
          label: 'File',
          menus: <PlatformMenuItem>[
            PlatformMenuItem(
              label: 'Quit Custom RR',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyQ,
                control: true,
              ),
              onSelected: () => SystemNavigator.pop(),
            ),
          ],
        ),
        PlatformMenu(
          label: 'View',
          menus: <PlatformMenuItem>[
            PlatformMenuItem(
              label: 'Home',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.digit1,
                control: true,
              ),
              onSelected: () => router.go(AppRoutes.home),
            ),
            PlatformMenuItem(
              label: 'Custom ROMs',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.digit2,
                control: true,
              ),
              onSelected: () => router.go(AppRoutes.roms),
            ),
            PlatformMenuItem(
              label: 'Custom Recoveries',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.digit3,
                control: true,
              ),
              onSelected: () => router.go(AppRoutes.recoveries),
            ),
            PlatformMenuItem(
              label: 'Devices',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.digit4,
                control: true,
              ),
              onSelected: () => router.go(AppRoutes.devices),
            ),
            PlatformMenuItem(
              label: 'Guide',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.digit5,
                control: true,
              ),
              onSelected: () => router.go(AppRoutes.instructions),
            ),
            PlatformMenuItem(
              label: 'Light theme',
              onSelected: () =>
                  ThemeController.instance.setMode(ThemeMode.light),
            ),
            PlatformMenuItem(
              label: 'Dark theme',
              onSelected: () =>
                  ThemeController.instance.setMode(ThemeMode.dark),
            ),
            PlatformMenuItem(
              label: 'System theme',
              onSelected: () =>
                  ThemeController.instance.setMode(ThemeMode.system),
            ),
          ],
        ),
        PlatformMenu(
          label: 'Help',
          menus: <PlatformMenuItem>[
            PlatformMenuItem(
              label: 'About Custom RR',
              onSelected: () => showCustomAboutDialog(context),
            ),
            PlatformMenuItem(
              label: 'View on GitHub',
              onSelected: () => launchUrl(
                Uri.parse(_repoUrl),
                mode: LaunchMode.externalApplication,
              ),
            ),
            PlatformMenuItem(
              label: 'Report an issue',
              onSelected: () => launchUrl(
                Uri.parse('$_repoUrl/issues/new/choose'),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ],
        ),
      ],
      child: child,
    );
  }
}
