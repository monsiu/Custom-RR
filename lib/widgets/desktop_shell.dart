import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../routes.dart';
import '../theme.dart';
import '../theme_controller.dart';
import '../util/request_project.dart';
import 'offline_notice.dart';
import 'update_banner.dart';

/// Desktop-first application shell used on Linux (and, later, Windows).
///
/// Differences from the mobile/adaptive [AppShell]:
/// - Always-pinned slim left rail (regardless of window width).
/// - Compact app bar with a left-aligned title and no surface tint.
/// - Inline status footer crediting the project + author.
///
/// The native menu bar lives at the app root (see [DesktopMenuBar] in
/// `lib/widgets/desktop_menu_bar.dart`) so it is mounted exactly once.
class DesktopShell extends StatelessWidget {
  const DesktopShell({
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

  static const String _repoUrl = 'https://github.com/monsiu/Custom-RR';
  static const String _authorUrl = 'https://github.com/monsiu';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final Widget paddedBody = bodyPadding == null
        ? OfflineNotice(child: UpdateBanner(child: body))
        : Padding(
            padding: bodyPadding!,
            child: OfflineNotice(child: UpdateBanner(child: body)),
          );

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        toolbarHeight: 44,
        titleSpacing: 12,
        centerTitle: false,
        automaticallyImplyLeading: false,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 1,
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: <Widget>[
          if (actions != null) ...actions!,
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const Divider(height: 1, thickness: 1),
            Expanded(
              child: Row(
                children: <Widget>[
                  _DesktopRail(selectedRoute: selectedRoute),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(child: paddedBody),
                ],
              ),
            ),
            // No bottom Divider here; the status bar paints its own
            // top border, so a second rule reads as a heavy doubled line.
            _DesktopStatusBar(repoUrl: _repoUrl, authorUrl: _authorUrl),
          ],
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}

class _DesktopRail extends StatefulWidget {
  const _DesktopRail({required this.selectedRoute});

  final String selectedRoute;

  static const String _repoUrl = 'https://github.com/monsiu/Custom-RR';

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
    _RailDest(
      AppRoutes.community,
      Icons.forum_outlined,
      Icons.forum,
      'Community',
    ),
  ];

  @override
  State<_DesktopRail> createState() => _DesktopRailState();
}

class _DesktopRailState extends State<_DesktopRail> {
  /// Fixed height of each rail destination button (`_RailButton` is a 56px
  /// tap target plus 3px vertical padding on each side). Pinning the extent
  /// keeps the scroll-into-view maths exact.
  static const double _itemExtent = 62;

  final ScrollController _scrollController = ScrollController();
  bool _canScrollUp = false;
  bool _canScrollDown = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollFades);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScrollFades();
      _ensureSelectedVisible();
    });
  }

  @override
  void didUpdateWidget(_DesktopRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedRoute != widget.selectedRoute) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _ensureSelectedVisible(),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollFades() {
    if (!_scrollController.hasClients) return;
    final ScrollPosition pos = _scrollController.position;
    final bool up = pos.pixels > pos.minScrollExtent + 0.5;
    final bool down = pos.pixels < pos.maxScrollExtent - 0.5;
    if (up != _canScrollUp || down != _canScrollDown) {
      setState(() {
        _canScrollUp = up;
        _canScrollDown = down;
      });
    }
  }

  /// Scrolls the destination list so the currently selected item is centered
  /// in the viewport. Near the list ends the target is clamped, so the item
  /// settles as close to the middle as possible while staying fully visible.
  /// No-op when the selected route is not a rail destination (e.g. the About
  /// page) or when the list does not scroll.
  void _ensureSelectedVisible() {
    if (!_scrollController.hasClients) return;
    final int index = _DesktopRail._destinations.indexWhere(
      (_RailDest d) => d.route == widget.selectedRoute,
    );
    if (index < 0) return;
    final ScrollPosition pos = _scrollController.position;
    final double itemCenter = index * _itemExtent + _itemExtent / 2;
    final double target = (itemCenter - pos.viewportDimension / 2)
        .clamp(pos.minScrollExtent, pos.maxScrollExtent);
    if ((target - pos.pixels).abs() < 1) return;
    _scrollController.jumpTo(target);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String selectedRoute = widget.selectedRoute;
    final int selectedIndex = _DesktopRail._destinations.indexWhere(
      (_RailDest d) => d.route == selectedRoute,
    );

    return Material(
      color: scheme.surfaceContainerLow,
      child: SizedBox(
        width: 80,
        child: Column(
          children: <Widget>[
            const SizedBox(height: 10),
            Tooltip(
              message: 'Custom RR by Monsiu  -  Home',
              waitDuration: const Duration(milliseconds: 400),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  if (selectedRoute != AppRoutes.home) {
                    context.go(AppRoutes.home);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: kBrandSeed,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Image.asset(
                          'images/generated/launcher_adaptive_fg.png',
                          width: 60,
                          height: 60,
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: NotificationListener<ScrollMetricsNotification>(
                onNotification: (ScrollMetricsNotification _) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _updateScrollFades(),
                  );
                  return false;
                },
                child: Stack(
                  children: <Widget>[
                    ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.zero,
                      itemExtent: _itemExtent,
                      itemCount: _DesktopRail._destinations.length,
                      itemBuilder: (BuildContext context, int i) {
                        final _RailDest d = _DesktopRail._destinations[i];
                        final bool selected = i == selectedIndex;
                        return _RailButton(
                          icon: selected ? d.selectedIcon : d.icon,
                          label: d.label,
                          selected: selected,
                          onTap: () {
                            if (d.route == selectedRoute) return;
                            context.go(d.route);
                          },
                        );
                      },
                    ),
                    if (_canScrollUp)
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: _ScrollEdgeFade(top: true),
                      ),
                    if (_canScrollDown)
                      const Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _ScrollEdgeFade(top: false),
                      ),
                  ],
                ),
              ),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 4),
            _RailButton(
              icon: Icons.help_outline,
              label: 'Help',
              onTap: () => _showHelpMenu(context),
            ),
            _RailButton(
              icon: selectedRoute == AppRoutes.about
                  ? Icons.info
                  : Icons.info_outline,
              label: 'About',
              selected: selectedRoute == AppRoutes.about,
              onTap: () {
                if (selectedRoute != AppRoutes.about) {
                  context.go(AppRoutes.about);
                }
              },
            ),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeController.instance,
              builder: (BuildContext context, ThemeMode mode, _) {
                return _RailButton(
                  icon: switch (mode) {
                    ThemeMode.light => Icons.light_mode_outlined,
                    ThemeMode.dark => Icons.dark_mode_outlined,
                    ThemeMode.system => Icons.brightness_auto_outlined,
                  },
                  label: 'Theme',
                  onTap: () {
                    final ThemeMode next = switch (mode) {
                      ThemeMode.system => ThemeMode.light,
                      ThemeMode.light => ThemeMode.dark,
                      ThemeMode.dark => ThemeMode.system,
                    };
                    ThemeController.instance.setMode(next);
                  },
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Help menu shown from the desktop side rail. The native menu bar only
  /// renders on macOS, so Linux and Windows need this in-window entry point
  /// for the request / report / source actions.
  void _showHelpMenu(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return SimpleDialog(
          title: const Text('Help'),
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('Request a ROM or recovery'),
              onTap: () {
                Navigator.of(ctx).pop();
                openProjectRequest(kind: 'ROM or recovery');
              },
            ),
            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: const Text('Report an issue'),
              onTap: () {
                Navigator.of(ctx).pop();
                launchUrl(
                  Uri.parse('${_DesktopRail._repoUrl}/issues/new/choose'),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('View on GitHub'),
              onTap: () {
                Navigator.of(ctx).pop();
                launchUrl(
                  Uri.parse(_DesktopRail._repoUrl),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// A short vertical gradient drawn at the top or bottom of the scrollable
/// rail destinations to signal that more items exist beyond the fold, so the
/// fixed Help/About/Theme footer does not make the rail look complete.
class _ScrollEdgeFade extends StatelessWidget {
  const _ScrollEdgeFade({required this.top});

  // Each rail item occupies 62 px including spacing; a 30 px fade
  // gives a stronger edge mask that reaches about half an item.
  static const double _fadeHeight = 30;

  final bool top;

  @override
  Widget build(BuildContext context) {
    final Color base = Theme.of(context).colorScheme.surfaceContainerLow;
    return IgnorePointer(
      child: Container(
        height: _fadeHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: top ? Alignment.topCenter : Alignment.bottomCenter,
            end: top ? Alignment.bottomCenter : Alignment.topCenter,
            colors: <Color>[base, base.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _RailButton extends StatefulWidget {
  const _RailButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  State<_RailButton> createState() => _RailButtonState();
}

class _RailButtonState extends State<_RailButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool selected = widget.selected;
    final Color fg = selected
        ? scheme.onSecondaryContainer
        : (_hover ? scheme.onSurface : scheme.onSurfaceVariant);
    final Color bg = selected
        ? scheme.secondaryContainer
        : (_hover
            ? scheme.onSurface.withValues(alpha: 0.06)
            : Colors.transparent);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Tooltip(
        message: widget.label,
        waitDuration: const Duration(milliseconds: 500),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onTap,
              child: SizedBox(
                height: 56,
                child: Stack(
                  children: <Widget>[
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      left: 0,
                      top: selected ? 14 : 24,
                      bottom: selected ? 14 : 24,
                      child: Container(
                        width: 3,
                        decoration: BoxDecoration(
                          color: selected ? scheme.primary : Colors.transparent,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(2),
                            bottomRight: Radius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(widget.icon, size: 22, color: fg),
                          const SizedBox(height: 3),
                          SizedBox(
                            width: double.infinity,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                widget.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  height: 1.1,
                                  color: fg,
                                  letterSpacing: 0.2,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopStatusBar extends StatelessWidget {
  const _DesktopStatusBar({required this.repoUrl, required this.authorUrl});

  final String repoUrl;
  final String authorUrl;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextStyle? style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontSize: 11.5,
        );
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.bolt_rounded,
            size: 13,
            color: scheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            'Custom RR',
            style: style?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(width: 6),
          Text('by', style: style),
          const SizedBox(width: 4),
          _LinkText(
            text: 'Monsiu',
            url: authorUrl,
            style: style,
          ),
          _Dot(style: style),
          _LinkText(
            text: 'github.com/monsiu/Custom-RR',
            url: repoUrl,
            style: style,
          ),
          const Spacer(),
          const _VersionLabel(),
          _Dot(style: style),
          Icon(
            Icons.desktop_windows_outlined,
            size: 13,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text('Linux desktop build', style: style),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.style});
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text('\u00b7', style: style),
    );
  }
}

class _LinkText extends StatefulWidget {
  const _LinkText({
    required this.text,
    required this.url,
    required this.style,
  });
  final String text;
  final String url;
  final TextStyle? style;

  @override
  State<_LinkText> createState() => _LinkTextState();
}

class _LinkTextState extends State<_LinkText> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = _hover ? scheme.primary : scheme.onSurfaceVariant;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => launchUrl(
          Uri.parse(widget.url),
          mode: LaunchMode.externalApplication,
        ),
        child: Text(
          widget.text,
          style: widget.style?.copyWith(
            color: color,
            decoration: _hover ? TextDecoration.underline : TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

class _VersionLabel extends StatefulWidget {
  const _VersionLabel();

  @override
  State<_VersionLabel> createState() => _VersionLabelState();
}

class _VersionLabelState extends State<_VersionLabel> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((PackageInfo info) {
      if (!mounted) return;
      setState(() => _version = 'v${info.version}');
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextStyle? style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontSize: 11.5,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
    if (_version.isEmpty) return const SizedBox.shrink();
    return Text(_version, style: style);
  }
}

class _RailDest {
  const _RailDest(this.route, this.icon, this.selectedIcon, this.label);
  final String route;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
