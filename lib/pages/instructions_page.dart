import 'package:flutter/material.dart';

import '../routes.dart';
import '../util/breakpoints.dart';
import '../widgets/app_shell.dart';

class InstructionsPage extends StatelessWidget {
  const InstructionsPage({super.key});

  static const List<_Section> _sections = <_Section>[
    _Section(
      title: 'Before you begin',
      body: <String>[
        'Custom ROMs and recoveries require an unlocked bootloader. The unlock process wipes all data on your device, so back up everything important first.',
        'Make sure your battery is charged above 50% and that you have a working USB cable.',
      ],
    ),
    _Section(
      title: 'Step 1: Unlock the bootloader',
      body: <String>[
        'Enable Developer Options by tapping Build Number 7 times in Settings → About Phone.',
        'In Developer Options, enable OEM Unlocking and USB Debugging.',
        'Boot the device into fastboot mode and run `fastboot flashing unlock` (or the manufacturer-specific command).',
      ],
    ),
    _Section(
      title: 'Step 2: Install a custom recovery',
      body: <String>[
        'Download the recovery image (TWRP / OrangeFox / PBRP, etc.) for your exact device model.',
        'In fastboot, run: `fastboot flash recovery recovery.img` and then reboot into recovery with `fastboot reboot recovery`.',
      ],
    ),
    _Section(
      title: 'Step 3: Flash a custom ROM',
      body: <String>[
        'Copy the ROM ZIP (and optional GApps / Magisk ZIPs) to your device storage.',
        'In your custom recovery, wipe Data, Cache and Dalvik/ART before flashing a different ROM.',
        'Flash the ROM ZIP, followed by GApps and Magisk if desired, then reboot.',
      ],
    ),
    _Section(
      title: 'Troubleshooting',
      body: <String>[
        'Bootloop? Boot back into recovery and perform a clean wipe before flashing again.',
        'No service / IMEI lost? Make sure you flashed the firmware version recommended by the ROM\'s maintainer.',
        'Still stuck? Visit the official ROM forum or Telegram group for device-specific help.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return AppShell(
      title: 'Instructions',
      selectedRoute: AppRoutes.instructions,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: Breakpoints.readingMaxWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Text(
                'Flashing Custom ROMs & Recoveries',
                style: text.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'A high-level overview of the steps required to install a custom '
                'ROM. Always follow the device-specific guide from the ROM '
                'maintainer.',
                style: text.bodyLarge,
              ),
              const SizedBox(height: 24),
              for (final _Section section in _sections) ...<Widget>[
                Text(section.title, style: text.titleLarge),
                const SizedBox(height: 8),
                for (final String paragraph in section.body)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(paragraph, style: text.bodyLarge),
                  ),
                const SizedBox(height: 20),
              ],
              Card(
                color: scheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        Icons.warning_amber_outlined,
                        color: scheme.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Flashing custom firmware voids your warranty and can '
                          'brick the device. Proceed at your own risk; we are '
                          'not responsible for any damage.',
                          style: text.bodyMedium?.copyWith(
                            color: scheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section {
  const _Section({required this.title, required this.body});
  final String title;
  final List<String> body;
}
