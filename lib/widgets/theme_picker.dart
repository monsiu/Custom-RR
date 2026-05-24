import 'package:flutter/material.dart';

import '../theme_controller.dart';

/// Bottom-sheet picker that lets the user switch between System / Light / Dark.
Future<void> showThemePicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext sheetContext) {
      return SafeArea(
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeController.instance,
          builder: (BuildContext context, ThemeMode current, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                    child: Text(
                      'Appearance',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  _ThemeOption(
                    icon: Icons.brightness_auto_outlined,
                    label: 'System default',
                    subtitle: 'Match the device theme',
                    mode: ThemeMode.system,
                    current: current,
                  ),
                  _ThemeOption(
                    icon: Icons.light_mode_outlined,
                    label: 'Light',
                    subtitle: 'Always use light theme',
                    mode: ThemeMode.light,
                    current: current,
                  ),
                  _ThemeOption(
                    icon: Icons.dark_mode_outlined,
                    label: 'Dark',
                    subtitle: 'Always use dark theme',
                    mode: ThemeMode.dark,
                    current: current,
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  ValueListenableBuilder<bool>(
                    valueListenable: ThemeController.instance.amoled,
                    builder: (BuildContext context, bool amoled, _) {
                      final MediaQueryData mq = MediaQuery.of(context);
                      final bool effectiveDark = current == ThemeMode.dark ||
                          (current == ThemeMode.system &&
                              mq.platformBrightness == Brightness.dark);
                      return SwitchListTile(
                        secondary: const Icon(Icons.contrast),
                        title: const Text('AMOLED true black'),
                        subtitle: Text(
                          effectiveDark
                              ? 'Pure-black surfaces in dark mode'
                              : 'Applies when dark mode is active',
                        ),
                        value: amoled,
                        onChanged: (bool v) =>
                            ThemeController.instance.setAmoled(v),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.mode,
    required this.current,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final ThemeMode mode;
  final ThemeMode current;

  @override
  Widget build(BuildContext context) {
    final bool selected = mode == current;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(subtitle),
      selected: selected,
      trailing: selected
          ? Icon(Icons.check_circle, color: scheme.primary)
          : const Icon(Icons.circle_outlined),
      onTap: () async {
        await ThemeController.instance.setMode(mode);
        if (context.mounted) Navigator.of(context).pop();
      },
    );
  }
}
