import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'routes.dart';
import 'theme.dart';
import 'theme_controller.dart';
import 'util/platform_shell.dart';
import 'widgets/desktop_menu_bar.dart';

class CustomRrApp extends StatefulWidget {
  const CustomRrApp({super.key});

  @override
  State<CustomRrApp> createState() => _CustomRrAppState();
}

class _CustomRrAppState extends State<CustomRrApp> {
  final _router = buildRouter();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (BuildContext context, ThemeMode mode, _) {
        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            return MaterialApp.router(
              title: 'Custom RR',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(dynamicScheme: lightDynamic),
              darkTheme: AppTheme.dark(dynamicScheme: darkDynamic),
              themeMode: mode,
              routerConfig: _router,
              builder: (BuildContext context, Widget? child) {
                final Brightness brightness = Theme.of(context).brightness;
                final bool isDark = brightness == Brightness.dark;
                final Widget content = child ?? const SizedBox.shrink();
                final Widget wrapped = useDesktopShell
                    ? DesktopMenuBar(router: _router, child: content)
                    : content;
                return AnnotatedRegion<SystemUiOverlayStyle>(
                  value: SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    systemNavigationBarColor: Colors.transparent,
                    systemNavigationBarDividerColor: Colors.transparent,
                    systemNavigationBarContrastEnforced: false,
                    statusBarIconBrightness:
                        isDark ? Brightness.light : Brightness.dark,
                    statusBarBrightness: brightness,
                    systemNavigationBarIconBrightness:
                        isDark ? Brightness.light : Brightness.dark,
                  ),
                  child: wrapped,
                );
              },
            );
          },
        );
      },
    );
  }
}
