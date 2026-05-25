import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../routes.dart';
import '../util/breakpoints.dart';
import '../widgets/app_shell.dart';

class InstructionsPage extends StatelessWidget {
  const InstructionsPage({super.key});

  static const List<_PrepItem> _prep = <_PrepItem>[
    _PrepItem(
      icon: Icons.lock_open_rounded,
      title: 'Unlockable bootloader',
      detail: 'Some carriers (looking at you, US Verizon) block this. Check first.',
    ),
    _PrepItem(
      icon: Icons.cloud_upload_rounded,
      title: 'Full backup',
      detail: 'Unlocking wipes /data. Photos, 2FA seeds, signal stickers, all of it.',
    ),
    _PrepItem(
      icon: Icons.battery_charging_full_rounded,
      title: 'Battery above 50%',
      detail: 'A mid-flash power loss is the fastest path to a brick.',
    ),
    _PrepItem(
      icon: Icons.usb_rounded,
      title: 'A real USB data cable',
      detail: 'Charge-only cables silently fail. Try two if fastboot does not see the device.',
    ),
    _PrepItem(
      icon: Icons.terminal_rounded,
      title: 'adb + fastboot installed',
      detail: 'Grab Google platform-tools and add it to your PATH so commands just work.',
    ),
  ];

  static const List<_Step> _steps = <_Step>[
    _Step(
      number: 1,
      icon: Icons.lock_open_rounded,
      title: 'Unlock the bootloader',
      summary: 'Wave goodbye to the warranty seal.',
      bullets: <String>[
        'Open Settings, About phone, then tap `Build number` seven times to unlock Developer options.',
        'In Developer options, turn on `OEM unlocking` and `USB debugging`.',
        'Reboot into fastboot: `adb reboot bootloader`.',
        'Run `fastboot flashing unlock` (some OEMs use `fastboot oem unlock` or a token).',
        'Confirm on the device when prompted. The phone wipes and reboots; let it finish first-boot setup.',
      ],
    ),
    _Step(
      number: 2,
      icon: Icons.security_update_warning_rounded,
      title: 'Install a custom recovery',
      summary: 'Your launchpad for everything that follows.',
      bullets: <String>[
        'Download the recovery image (TWRP / OrangeFox / PBRP) built for your exact device codename.',
        'Boot into fastboot, then run `fastboot flash recovery recovery.img`.',
        'Some devices need `fastboot flash boot` instead, or to boot temporarily with `fastboot boot recovery.img`. Check the recovery install notes.',
        'Reboot straight into recovery: `fastboot reboot recovery`. Do not let the device boot to system in between, or the stock recovery may overwrite yours.',
      ],
    ),
    _Step(
      number: 3,
      icon: Icons.system_update_rounded,
      title: 'Flash a custom ROM',
      summary: 'The fun part.',
      bullets: <String>[
        'Sideload or copy the ROM ZIP to your device (plus an optional GApps ZIP if the ROM ships vanilla).',
        'In recovery, wipe `Data`, `Cache` and `Dalvik / ART` before switching between different ROMs.',
        'Flash in this order: ROM, then GApps (if not built-in). Do NOT flash Magisk as a ZIP here, the Magisk dev deprecated that path; root comes later via the Root section below.',
        'Reboot. First boot can take 5 to 10 minutes; do not panic if the boot logo lingers.',
      ],
    ),
  ];

  static const List<_Brand> _brands = <_Brand>[
    _Brand(
      name: 'Google Pixel',
      tagline: 'The reference. Easiest path; almost everything is documented.',
      icon: Icons.android_rounded,
      tips: <String>[
        'Enable `OEM unlocking` in Developer options. The toggle is greyed out without an internet connection.',
        'Unlock with `fastboot flashing unlock`, confirm on-device with Volume + Power.',
        'Pixels are A/B with seamless updates. Flash boot/init_boot with `--slot=all` to cover both slots.',
        'For Tensor (Pixel 6+) flash `init_boot.img` for Magisk root, not `boot.img`.',
        'Use Android Flash Tool in the browser if you ever need to nuke back to stock.',
      ],
    ),
    _Brand(
      name: 'Samsung Galaxy',
      tagline: 'No fastboot. You will live in Odin and Download Mode.',
      icon: Icons.phone_iphone_rounded,
      tips: <String>[
        'Use Odin (Windows) or Heimdall (Linux/macOS), not fastboot. Boot into Download Mode: power off, then Vol Down + Vol Up while plugging in USB.',
        'After enabling `OEM unlocking` you must wait 7 days before the unlock prompt shows up in Download Mode.',
        'Snapdragon variants (model code ending in U for US carrier, etc.) often have a locked bootloader and cannot be unlocked at all. Check before buying.',
        'Knox eFuse trips permanently on first unlock. Warranty void, Samsung Pay / Health / Secure Folder stop working forever.',
        'BTW: you can claw most of those Samsung apps back on a rooted setup by installing the `Knox Patcher` LSPosed module (needs Magisk + Zygisk + LSPosed). It spoofs the Knox check, so Wallet, Health, Secure Folder and friends start working again. It does not un-trip the eFuse, just papers over the software side.',
        'Flash a vbmeta with verity + verification disabled before booting a custom ROM, or you will hit an orange/red state.',
      ],
    ),
    _Brand(
      name: 'Xiaomi / Redmi / POCO',
      tagline: 'Mi Unlock Tool + a mandatory waiting period.',
      icon: Icons.layers_rounded,
      tips: <String>[
        'Bind a Mi Account on the device, sign in with the same account in Mi Unlock Tool, then start the unlock request.',
        'You must wait 168 hours (7 days) on most regions before the tool will actually unlock the device. Newer HyperOS builds may require longer.',
        'Use MiFlash and a fastboot ROM if you ever brick or need to revert to stock.',
        'Many devices need an anti-rollback (ARB) compatible firmware. Flashing an older ROM than your current ARB level will hard-brick.',
      ],
    ),
    _Brand(
      name: 'OnePlus',
      tagline: 'Easy unlock; MSM tool is your safety net.',
      icon: Icons.circle_outlined,
      tips: <String>[
        'Use `fastboot oem unlock` on older models, `fastboot flashing unlock` on newer ones.',
        'OxygenOS 13+ on global units shares a codebase with ColorOS. Make sure your ROM build matches your firmware base.',
        'If you soft-brick, the OnePlus MSM Download Tool can re-flash stock over a special EDL mode (Windows only).',
      ],
    ),
    _Brand(
      name: 'Motorola',
      tagline: 'Free unlock token from Lenovo, then standard fastboot.',
      icon: Icons.android_rounded,
      tips: <String>[
        'Run `fastboot oem get_unlock_data`, paste the output into the Motorola unlock portal, sign in, get the unlock key.',
        'Unlock with `fastboot oem unlock <KEY>`.',
        'Most Motorola devices use A/B partitions; flash to both slots when patching boot for Magisk.',
        'Some carrier variants (Verizon US) cannot be unlocked, period.',
      ],
    ),
    _Brand(
      name: 'Nothing Phone',
      tagline: 'Behaves like a Pixel. A/B, fastboot, smooth ride.',
      icon: Icons.adjust_rounded,
      tips: <String>[
        'Enable `OEM unlocking`, reboot to fastboot, run `fastboot flashing unlock`.',
        'Tools and patterns from the Pixel ecosystem mostly work as-is.',
        'Nothing OS uses a custom Glyph service. Reflash the original firmware if Glyphs misbehave after a ROM swap.',
      ],
    ),
    _Brand(
      name: 'Sony Xperia',
      tagline: 'Official unlock, but it kills DRM keys.',
      icon: Icons.phone_android_rounded,
      tips: <String>[
        'Get an unlock code from Sony developer portal: `*#*#7378423#*#*` -> Service info -> Configuration -> Rooting Status to grab your IMEI bond.',
        'Unlocking permanently destroys the DRM/TA keys. Camera quality and X-Reality features will degrade.',
        'After unlock: `fastboot -i 0x0fce oem unlock 0x<KEY>`.',
      ],
    ),
    _Brand(
      name: 'Asus ROG / Zenfone',
      tagline: 'Official unlock app, varies by region.',
      icon: Icons.sports_esports_rounded,
      tips: <String>[
        'Older models: install the Asus Unlock Device App from the Asus support page, run it once, then reboot to fastboot.',
        'Newer models (ROG Phone 7+): unlock moved into Developer options as an in-system toggle. Asus discontinued the app.',
        'Unlocking voids warranty and disables Widevine L1.',
      ],
    ),
    _Brand(
      name: 'Realme / Oppo',
      tagline: 'In-Depth Test app gates the unlock.',
      icon: Icons.smartphone_rounded,
      tips: <String>[
        'Apply for the Deep Testing / In-Depth Test app, get approved (can take days), then run the app to unlock.',
        'Many newer Realme/Oppo models are region-locked and cannot be unlocked outside China.',
        'After unlock, the standard `fastboot` flow works.',
      ],
    ),
    _Brand(
      name: 'Huawei / Honor',
      tagline: 'Officially impossible since mid-2018. Sorry.',
      icon: Icons.do_not_disturb_alt_rounded,
      tips: <String>[
        'Huawei stopped issuing bootloader unlock codes in May 2018. Honor followed suit.',
        'Only legacy devices and a handful of third-party paid services can unlock. Most paid services are scams. Tread carefully.',
        'EMUI/HarmonyOS is heavily locked; custom ROM support is sparse outside the Kirin 9-series community.',
      ],
    ),
  ];

  static const List<_FaqItem> _faqs = <_FaqItem>[
    _FaqItem(
      question: 'Stuck in a bootloop after flashing',
      answer: 'Boot back into recovery, do a clean wipe of Data + Cache + Dalvik, then reflash the ROM. If it keeps looping, try an older build or a different GApps package.',
    ),
    _FaqItem(
      question: 'No service or "missing IMEI"',
      answer: 'Flash the modem / firmware version the ROM maintainer recommends. Mismatched vendor blobs are the usual culprit.',
    ),
    _FaqItem(
      question: 'Stuck on the boot logo forever',
      answer: 'Wait at least 10 minutes for the first boot. If still frozen, reflash the ROM after a clean wipe, or revert to stock and try a newer build.',
    ),
    _FaqItem(
      question: 'Banking apps refuse to open',
      answer: 'Most root checks can be passed with Magisk DenyList plus Play Integrity Fix modules. Some apps will still complain; that is by design.',
    ),
    _FaqItem(
      question: 'Still stuck',
      answer: 'Hit the ROM official Telegram or XDA thread. Include your device codename, ROM build date, and the exact step that failed.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Guide',
      selectedRoute: AppRoutes.instructions,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: Breakpoints.readingMaxWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: <Widget>[
              const _Hero(),
              const SizedBox(height: 20),
              const _WarningBanner(),
              const SizedBox(height: 24),
              const _SectionHeader(
                icon: Icons.checklist_rtl_rounded,
                title: 'Before you begin',
                subtitle: 'Five things to sort out before the cable comes out. Tap a row to tick it off.',
              ),
              const SizedBox(height: 12),
              const _PrepCard(items: _prep),
              const SizedBox(height: 28),
              const _SectionHeader(
                icon: Icons.route_rounded,
                title: 'The flashing route',
                subtitle: 'Three numbered stops. Take them in order. Check off each line as you go.',
              ),
              const SizedBox(height: 12),
              for (int i = 0; i < _steps.length; i++)
                _StepTimelineCard(
                  step: _steps[i],
                  isLast: i == _steps.length - 1,
                ),
              const SizedBox(height: 24),
              const _SectionHeader(
                icon: Icons.smartphone_rounded,
                title: 'Device-specific quirks',
                subtitle: 'The general route works for most phones. These notes cover the gotchas per brand.',
              ),
              const SizedBox(height: 12),
              const _BrandCards(brands: _brands),
              const SizedBox(height: 28),
              const _SectionHeader(
                icon: Icons.shield_rounded,
                title: 'Going further: root',
                subtitle: 'Optional. Adds system-level powers after a ROM (or stock) is up and running.',
              ),
              const SizedBox(height: 12),
              const _RootCard(),
              const SizedBox(height: 24),
              const _SectionHeader(
                icon: Icons.handyman_rounded,
                title: 'Troubleshooting',
                subtitle: 'The hits you will probably see.',
              ),
              const SizedBox(height: 12),
              const _FaqCard(items: _faqs),
              const SizedBox(height: 28),
              const _HelpFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            scheme.primaryContainer,
            Color.alphaBlend(
              scheme.tertiaryContainer.withValues(alpha: 0.85),
              scheme.primaryContainer,
            ),
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.onPrimaryContainer.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.rocket_launch_rounded,
              size: 30,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Flash a Custom ROM',
                  style: text.headlineSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'A friendly, no-nonsense walkthrough. Pair it with the device-specific notes from your ROM maintainer.',
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 12),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _MetaPill(
                      icon: Icons.signal_cellular_alt_rounded,
                      label: 'Difficulty: Advanced',
                    ),
                    _MetaPill(
                      icon: Icons.schedule_rounded,
                      label: '~30 min hands-on',
                    ),
                    _MetaPill(
                      icon: Icons.devices_other_rounded,
                      label: 'Device-specific',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.onPrimaryContainer.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: scheme.onPrimaryContainer),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: scheme.onSecondaryContainer),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrepCard extends StatefulWidget {
  const _PrepCard({required this.items});
  final List<_PrepItem> items;

  @override
  State<_PrepCard> createState() => _PrepCardState();
}

class _PrepCardState extends State<_PrepCard> {
  final Set<int> _checked = <int>{};

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          for (int i = 0; i < widget.items.length; i++) ...<Widget>[
            CheckboxListTile(
              value: _checked.contains(i),
              onChanged: (bool? v) {
                setState(() {
                  if (v ?? false) {
                    _checked.add(i);
                  } else {
                    _checked.remove(i);
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.trailing,
              secondary: CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: Icon(widget.items[i].icon, size: 20),
              ),
              title: Text(
                widget.items[i].title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: _checked.contains(i)
                      ? TextDecoration.lineThrough
                      : null,
                  color: _checked.contains(i)
                      ? scheme.onSurfaceVariant
                      : null,
                ),
              ),
              subtitle: Text(
                widget.items[i].detail,
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            if (i != widget.items.length - 1)
              Divider(
                height: 1,
                indent: 72,
                endIndent: 16,
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
          ],
        ],
      ),
    );
  }
}

class _StepTimelineCard extends StatefulWidget {
  const _StepTimelineCard({required this.step, required this.isLast});
  final _Step step;
  final bool isLast;

  @override
  State<_StepTimelineCard> createState() => _StepTimelineCardState();
}

class _StepTimelineCardState extends State<_StepTimelineCard> {
  final Set<int> _checked = <int>{};

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final _Step step = widget.step;
    final bool isLast = widget.isLast;
    final bool allDone =
        step.bullets.isNotEmpty && _checked.length == step.bullets.length;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 44,
            child: Column(
              children: <Widget>[
                const SizedBox(height: 4),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary,
                  ),
                  alignment: Alignment.center,
                  child: allDone
                      ? Icon(
                          Icons.check_rounded,
                          color: scheme.onPrimary,
                          size: 22,
                        )
                      : Text(
                          '${step.number}',
                          style: TextStyle(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: scheme.primary.withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.45),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(step.icon, color: scheme.onPrimaryContainer),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  step.title,
                                  style: text.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (step.summary.isNotEmpty)
                                  Text(
                                    step.summary,
                                    style: text.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 16, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          for (int bi = 0; bi < step.bullets.length; bi++)
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                setState(() {
                                  if (_checked.contains(bi)) {
                                    _checked.remove(bi);
                                  } else {
                                    _checked.add(bi);
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    SizedBox(
                                      height: 28,
                                      width: 28,
                                      child: Checkbox(
                                        value: _checked.contains(bi),
                                        visualDensity: VisualDensity.compact,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        onChanged: (bool? v) {
                                          setState(() {
                                            if (v ?? false) {
                                              _checked.add(bi);
                                            } else {
                                              _checked.remove(bi);
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: _InlineMarkup(
                                          text: step.bullets[bi],
                                          base: text.bodyMedium?.copyWith(
                                            decoration:
                                                _checked.contains(bi)
                                                    ? TextDecoration
                                                        .lineThrough
                                                    : null,
                                            color: _checked.contains(bi)
                                                ? scheme.onSurfaceVariant
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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
        ],
      ),
    );
  }
}

class _InlineMarkup extends StatelessWidget {
  const _InlineMarkup({required this.text, required this.base});

  final String text;
  final TextStyle? base;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<String> parts = text.split('`');
    final List<InlineSpan> spans = <InlineSpan>[];
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      if (i.isOdd) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                parts[i],
                style: (base ?? const TextStyle()).copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                  fontSize: (base?.fontSize ?? 14) - 0.5,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
        );
      } else {
        spans.add(TextSpan(text: parts[i], style: base));
      }
    }
    return RichText(text: TextSpan(children: spans, style: base));
  }
}

class _BrandCards extends StatelessWidget {
  const _BrandCards({required this.brands});
  final List<_Brand> brands;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
        child: Column(
          children: <Widget>[
            for (final _Brand b in brands)
              ExpansionTile(
                shape: const Border(),
                collapsedShape: const Border(),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    b.icon,
                    color: scheme.onTertiaryContainer,
                    size: 22,
                  ),
                ),
                title: Text(
                  b.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  b.tagline,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedAlignment: Alignment.centerLeft,
                children: <Widget>[
                  for (final String tip in b.tips)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Icon(
                              Icons.bolt_rounded,
                              size: 18,
                              color: scheme.tertiary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _InlineMarkup(
                              text: tip,
                              base: text.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _RootCard extends StatelessWidget {
  const _RootCard();

  static const List<String> _magiskSteps = <String>[
    'This is the official `Patching Images` flow from topjohnwu. The old custom-recovery ZIP method is deprecated, do not use it.',
    'Grab the `boot.img` (or `init_boot.img` on Pixel 6+ and most GKI Android 13+ devices) that matches your *exact* ROM build. Wrong image = boot loop. NEVER use a patched image from someone else or from another device.',
    'Install the Magisk app on the phone. Open it, tap `Install`, then `Select and Patch a File`, pick the boot image, save the patched output.',
    'Copy the `magisk_patched_*.img` back to your PC. Reboot to fastboot: `adb reboot bootloader`.',
    'Flash it: `fastboot flash boot magisk_patched.img` (use `init_boot` instead if that is what you patched). On A/B devices, add `--slot=all` to cover both slots.',
    'Reboot. Open Magisk; it will run a tiny additional install and ask for one more reboot. You are rooted.',
    'Later upgrades: do NOT repeat this whole dance. Open the Magisk app, tap `Install` then `Direct Install` and reboot. The dev officially recommends Direct Install for every update after the first install.',
  ];

  static const List<_RootTip> _specialCases = <_RootTip>[
    _RootTip(
      icon: Icons.phone_android_rounded,
      title: 'Samsung devices: AP tar + Odin, not fastboot',
      body: 'Samsung phones use a different flow. Patch the `AP_*.tar.md5` from the firmware (Frija, Bifrost, samloader to download it) in the Magisk app, then flash the patched tar as `AP` in Odin together with `BL`, `CP` and `CSC` from the same firmware. First install requires a full data wipe.',
    ),
    _RootTip(
      icon: Icons.sd_storage_rounded,
      title: 'No boot ramdisk: patch `recovery.img` instead',
      body: 'If the Magisk app says `Ramdisk: No`, you must hijack recovery. Patch `recovery.img` (tick `Recovery Mode` in the app) and flash with `fastboot flash recovery`. After that, you boot the device with the recovery key combo to get into Magisk-rooted Android; normal power-on gives you a Magisk-less system.',
    ),
    _RootTip(
      icon: Icons.lock_open_rounded,
      title: 'Optional: disable verified boot (`vbmeta`)',
      body: 'If your device has a separate `vbmeta` partition and you hit dm-verity errors or a yellow/orange boot warning loop, flash: `fastboot flash vbmeta --disable-verity --disable-verification vbmeta.img`. This may wipe data. Skip on Samsung; that path is handled by Odin.',
    ),
  ];

  static const List<_RootFlavor> _flavors = <_RootFlavor>[
    _RootFlavor(
      name: 'Magisk',
      blurb: 'Systemless root. The default for most setups, widest module ecosystem.',
      icon: Icons.bolt_rounded,
    ),
    _RootFlavor(
      name: 'KernelSU',
      blurb: 'Kernel-level root. No boot patching; needs a KSU-enabled kernel.',
      icon: Icons.memory_rounded,
    ),
    _RootFlavor(
      name: 'APatch',
      blurb: 'Hybrid kernel + user-space. Newer, smaller community, growing fast.',
      icon: Icons.extension_rounded,
    ),
  ];

  static const List<_RootTip> _tips = <_RootTip>[
    _RootTip(
      icon: Icons.account_balance_rounded,
      title: 'Banking apps still nag',
      body: 'Combine Magisk DenyList with the Play Integrity Fix module. Add your banking, payment and DRM apps to DenyList. Some banks (notably revolut, US carriers) still refuse on principle.',
    ),
    _RootTip(
      icon: Icons.extension_rounded,
      title: 'Modules: handle with care',
      body: 'Install one module at a time and reboot. A bad module that runs early can soft-brick. If that happens, hold Volume Up during boot to enter Magisk safe mode (modules disabled).',
    ),
    _RootTip(
      icon: Icons.replay_rounded,
      title: 'OTA updates',
      body: 'OTAs over a rooted ROM usually fail because the boot image got modified. Re-patch the new build\'s boot image, flash it, and you are back. Magisk has an `Install to Inactive Slot` flow for A/B OTAs.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: scheme.tertiaryContainer.withValues(alpha: 0.45),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.security_rounded,
                  color: scheme.onTertiaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Root with Magisk',
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'The standard, systemless way. Works on stock ROMs and most custom ones.',
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (int i = 0; i < _magiskSteps.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 22,
                          height: 22,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.tertiary,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: scheme.onTertiary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _InlineMarkup(
                            text: _magiskSteps[i],
                            base: text.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Special cases',
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: <Widget>[
                for (final _RootTip c in _specialCases)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: scheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            c.icon,
                            size: 18,
                            color: scheme.onTertiaryContainer,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                c.title,
                                style: text.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              _InlineMarkup(
                                text: c.body,
                                base: text.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Other root flavors',
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: <Widget>[
                for (final _RootFlavor f in _flavors)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: scheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            f.icon,
                            size: 18,
                            color: scheme.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                f.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                f.blurb,
                                style: text.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final _RootTip t in _tips)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(t.icon, size: 20, color: scheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                t.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              _InlineMarkup(
                                text: t.body,
                                base: text.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RootFlavor {
  const _RootFlavor({
    required this.name,
    required this.blurb,
    required this.icon,
  });
  final String name;
  final String blurb;
  final IconData icon;
}

class _RootTip {
  const _RootTip({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;
}

class _FaqCard extends StatelessWidget {
  const _FaqCard({required this.items});
  final List<_FaqItem> items;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
        child: Column(
          children: <Widget>[
            for (int i = 0; i < items.length; i++)
              ExpansionTile(
                shape: const Border(),
                collapsedShape: const Border(),
                leading: Icon(
                  Icons.help_outline_rounded,
                  color: scheme.primary,
                ),
                title: Text(
                  items[i].question,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedAlignment: Alignment.centerLeft,
                children: <Widget>[
                  Text(items[i].answer),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: scheme.error, width: 4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Heads up',
                  style: text.titleSmall?.copyWith(
                    color: scheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Flashing custom firmware voids your warranty and can brick the device. Proceed at your own risk; we are not responsible for any damage.',
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpFooter extends StatelessWidget {
  const _HelpFooter();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        alignment: WrapAlignment.center,
        children: <Widget>[
          TextButton.icon(
            onPressed: () => launchUrl(
              Uri.parse('https://forum.xda-developers.com/'),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.forum_rounded),
            label: const Text('XDA Forums'),
          ),
          TextButton.icon(
            onPressed: () => launchUrl(
              Uri.parse('https://developer.android.com/tools/releases/platform-tools'),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Get platform-tools'),
          ),
        ],
      ),
    );
  }
}

class _PrepItem {
  const _PrepItem({
    required this.icon,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final String title;
  final String detail;
}

class _Step {
  const _Step({
    required this.number,
    required this.icon,
    required this.title,
    required this.summary,
    required this.bullets,
  });
  final int number;
  final IconData icon;
  final String title;
  final String summary;
  final List<String> bullets;
}

class _FaqItem {
  const _FaqItem({required this.question, required this.answer});
  final String question;
  final String answer;
}

class _Brand {
  const _Brand({
    required this.name,
    required this.tagline,
    required this.icon,
    required this.tips,
  });
  final String name;
  final String tagline;
  final IconData icon;
  final List<String> tips;
}
