import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../routes.dart';
import '../util/breakpoints.dart';
import '../widgets/app_shell.dart';

/// Project Treble / GSI overview and quick-start. Treble is largely a
/// universal flow on any Android 9+ device that ships with a vendor
/// partition split out from system, so this page lives at the same
/// level as the Guide rather than being buried per-device.
class TreblePage extends StatelessWidget {
  const TreblePage({super.key});

  static const String _heroBlurb =
      'Project Treble is the Android architecture change (Android 8.0+) '
      'that split vendor-specific code into its own partition. The payoff '
      'for us: a Generic System Image (GSI) compiled once can boot on '
      'almost any Treble-compatible device, regardless of brand. Think of '
      'it as a "universal ROM".';

  static const List<_TrebleCompatCheck> _checks = <_TrebleCompatCheck>[
    _TrebleCompatCheck(
      icon: Icons.terminal_rounded,
      title: 'adb one-liner',
      body:
          'Run `adb shell getprop ro.treble.enabled`. If it prints `true`, '
          'your device supports Treble. If empty or `false`, it does not.',
    ),
    _TrebleCompatCheck(
      icon: Icons.android_rounded,
      title: 'Treble Check app',
      body:
          'Install `Treble Info` (open-source) or `Treble Check` from the '
          'Play Store. They report ABI, A/A-B status, vndk version and '
          'whether system-as-root is in play. The values you need to '
          'match a GSI are all in one screen.',
    ),
    _TrebleCompatCheck(
      icon: Icons.history_rounded,
      title: 'Rule of thumb',
      body:
          'Anything that shipped with Android 9 or newer is Treble. Most '
          'Android 8 devices got Treble in updates. Older than that, you '
          'are in the LineageOS-classic camp; pick a device-specific ROM.',
    ),
  ];

  static const List<_GsiVariant> _variants = <_GsiVariant>[
    _GsiVariant(
      label: 'A-only vs A/B',
      detail:
          'A/B devices have two slots and can flash to `system_a` and '
          '`system_b`. A-only devices have one. Pick the matching image '
          '(`arm64-ab` vs `arm64-aonly`). Wrong choice = no boot.',
    ),
    _GsiVariant(
      label: 'arm64 vs arm32_binder64',
      detail:
          'Almost all modern phones are pure 64-bit (`arm64`). A handful '
          'of older devices run 32-bit userland with a 64-bit binder '
          '(`arm32_binder64`). Check with Treble Info before flashing.',
    ),
    _GsiVariant(
      label: 'Vanilla (`vndklite`) vs gapps',
      detail:
          'Vanilla images ship AOSP only. `gapps` builds include Google '
          'apps preinstalled. `vndklite` variants strip the GSI VNDK and '
          'use the vendor VNDK, useful on devices where the official GSI '
          'has camera or audio issues.',
    ),
    _GsiVariant(
      label: 'Android version',
      detail:
          'You can usually flash one major version newer than what the '
          'device shipped with, sometimes two. A Pixel 4 (shipped Android '
          '10) happily runs Android 14 GSIs. Going much further can break '
          'modem or sensors.',
    ),
  ];

  static const List<_FlashStep> _flashSteps = <_FlashStep>[
    _FlashStep(
      title: 'Unlock the bootloader',
      body:
          'Same as any custom ROM flow: enable `OEM unlocking` in '
          'Developer options, `fastboot flashing unlock` (or the vendor '
          'equivalent). This wipes the device.',
    ),
    _FlashStep(
      title: 'Disable verified boot',
      body:
          'GSIs are not signed for your device. Patch vbmeta:\n'
          '`fastboot --disable-verity --disable-verification flash vbmeta vbmeta.img`\n'
          'Use the `vbmeta.img` from the matching stock firmware.',
    ),
    _FlashStep(
      title: 'Boot into fastbootd',
      body:
          '`fastboot reboot fastboot` drops you into userspace fastboot '
          '(fastbootd), which can write logical partitions like `system` '
          'on modern devices. Stock fastboot mode often cannot.',
    ),
    _FlashStep(
      title: 'Flash the GSI',
      body:
          '`fastboot flash system system.img`\n'
          'On A/B devices the active slot is targeted. To cover both: '
          '`fastboot --slot=all flash system system.img`.',
    ),
    _FlashStep(
      title: 'Wipe userdata',
      body:
          '`fastboot -w` (or wipe `/data` and `/cache` from recovery). '
          'GSIs almost never boot on data left over from the stock ROM.',
    ),
    _FlashStep(
      title: 'Reboot and wait',
      body:
          'First boot can take 10 minutes. If it loops, reboot to '
          'fastbootd and try `fastboot erase system` then re-flash, or '
          'try a different GSI variant (vndklite often saves the day).',
    ),
  ];

  static const List<_GsiProject> _featured = <_GsiProject>[
    _GsiProject(
      name: 'AOSP GSI',
      status: _GsiStatus.referenceQuarterly,
      pitch:
          'Google\'s own reference GSIs, signed by Google. The cleanest, '
          'most boring baseline. Best for confirming a device can run any '
          'GSI at all before you go hunting for fancier ones.',
      primary: _GsiLink(
        label: 'Releases',
        url:
            'https://developer.android.com/topic/generic-system-image/releases',
      ),
      secondary: _GsiLink(
        label: 'GSI build docs',
        url: 'https://source.android.com/docs/setup/build/gsi',
      ),
    ),
    _GsiProject(
      name: 'LineageOS GSI',
      status: _GsiStatus.activeMonthly,
      pitch:
          'Lineage-flavored GSI: AOSP plus Lineage\'s privacy and quality '
          'patches, monthly builds, vanilla and `vndklite` variants. The '
          'safest pick when you want something that just works.',
      primary: _GsiLink(
        label: 'Nightly downloads',
        url: 'https://download.lineageos.org/builds/treble_arm64_bvN/nightly',
      ),
      secondary: _GsiLink(
        label: 'LineageOS wiki',
        url: 'https://wiki.lineageos.org/',
      ),
    ),
    _GsiProject(
      name: "AndyYan's GSI builds",
      status: _GsiStatus.activeMonthly,
      pitch:
          'Long-running SourceForge archive of unofficial LineageOS GSIs '
          '(and other AOSP forks) built by AndyYan. Frequent rebuilds, '
          '`arm64_bvN` and `arm64_bgN` variants, plus older Android '
          'versions for devices stuck on legacy vendors.',
      primary: _GsiLink(
        label: 'SourceForge files',
        url: 'https://sourceforge.net/projects/andyyan-gsi/files/',
      ),
      secondary: _GsiLink(
        label: 'Project page',
        url: 'https://sourceforge.net/projects/andyyan-gsi/',
      ),
    ),
    _GsiProject(
      name: 'TrebleDroid',
      status: _GsiStatus.activeDaily,
      pitch:
          'Actively maintained successor to phh-Treble. Daily AOSP-based '
          'builds with the widest device fix list rolled into one image, '
          'including the most up-to-date `vndklite` and arm32_binder64 '
          'variants.',
      primary: _GsiLink(
        label: 'GitHub Releases',
        url:
            'https://github.com/TrebleDroid/treble_experimentations/releases',
      ),
      secondary: _GsiLink(
        label: 'GitHub org',
        url: 'https://github.com/TrebleDroid/treble_experimentations',
      ),
    ),
    _GsiProject(
      name: "MisterZtr's LineageOS GSI",
      status: _GsiStatus.activeMonthly,
      pitch:
          'GitHub-hosted LineageOS GSI builds by MisterZtr. Releases on '
          'GitHub with `arm64_bvN` images, useful when SourceForge mirrors '
          'are slow or you want versioned downloads with checksums.',
      primary: _GsiLink(
        label: 'GitHub Releases',
        url: 'https://github.com/MisterZtr/LineageOS_gsi/releases',
      ),
      secondary: _GsiLink(
        label: 'Repository',
        url: 'https://github.com/MisterZtr/LineageOS_gsi',
      ),
    ),
    _GsiProject(
      name: 'crDroid',
      status: _GsiStatus.activeMonthly,
      pitch:
          'Long-running Pixel-style ROM with a Treble GSI track. Monthly '
          'builds, fine-grained customization, mature device list.',
      primary: _GsiLink(
        label: 'Downloads (treble_arm64_bvN)',
        url: 'https://crdroid.net/downloads?model=treble_arm64_bvN',
      ),
      secondary: _GsiLink(
        label: 'GitHub org',
        url: 'https://github.com/crdroidandroid',
      ),
    ),
    _GsiProject(
      name: 'PixelOS',
      status: _GsiStatus.activeMonthly,
      pitch:
          'Clean Pixel-feel ROM with Treble GSIs alongside device builds. '
          'Sticks close to stock UX, monthly cadence.',
      primary: _GsiLink(
        label: 'Download portal',
        url: 'https://download.pixelos.net/',
      ),
      secondary: _GsiLink(
        label: 'GitHub org',
        url: 'https://github.com/PixelOS-AOSP',
      ),
    ),
    _GsiProject(
      name: 'Evolution X',
      status: _GsiStatus.activeMonthly,
      pitch:
          'Pixel-style ROM with a dedicated GSI track on SourceForge. '
          'Frequent rebuilds, `vndklite` and standard variants.',
      primary: _GsiLink(
        label: 'SourceForge GSI files',
        url: 'https://sourceforge.net/projects/evolution-x/files/GSI/',
      ),
      secondary: _GsiLink(
        label: 'Project site',
        url: 'https://evolution-x.org/',
      ),
    ),
    _GsiProject(
      name: 'DerpFest',
      status: _GsiStatus.activeMonthly,
      pitch:
          'Daily-driver friendly ROM with a long-maintained GSI track. '
          'AOSP base plus polish, monthly cadence.',
      primary: _GsiLink(
        label: 'SourceForge GSI files',
        url: 'https://sourceforge.net/projects/derpfest/files/GSI/',
      ),
      secondary: _GsiLink(
        label: 'Project site',
        url: 'https://derpfest.org/',
      ),
    ),
    _GsiProject(
      name: 'Project Elixir',
      status: _GsiStatus.activeMonthly,
      pitch:
          'Feature-rich Pixel UI ROM with regular GSI releases on '
          'SourceForge. Heavy customization, monthly cadence.',
      primary: _GsiLink(
        label: 'SourceForge GSI files',
        url: 'https://sourceforge.net/projects/projectelixir/files/GSI/',
      ),
      secondary: _GsiLink(
        label: 'Project site',
        url: 'https://projectelixiros.com/',
      ),
    ),
    _GsiProject(
      name: 'AlphaDroid',
      status: _GsiStatus.activeMonthly,
      pitch:
          'Newer Pixel-style ROM that ships Treble GSIs alongside device '
          'builds. Good fallback when bigger names skip a release.',
      primary: _GsiLink(
        label: 'SourceForge files',
        url: 'https://sourceforge.net/projects/alphadroid-project/files/',
      ),
      secondary: _GsiLink(
        label: 'SourceForge project',
        url: 'https://sourceforge.net/projects/alphadroid-project/',
      ),
    ),
    _GsiProject(
      name: '/e/ OS (Murena)',
      status: _GsiStatus.activeMonthly,
      pitch:
          'Degoogled Lineage fork with Treble GSI builds. Different niche '
          'from the Pixel-style ROMs: privacy-first, microG-based, no '
          'Google services by default.',
      primary: _GsiLink(
        label: '/e/ OS site',
        url: 'https://e.foundation/e-os/',
      ),
      secondary: _GsiLink(
        label: 'Supported devices',
        url: 'https://doc.e.foundation/devices',
      ),
    ),
    _GsiProject(
      name: 'BlissROMs',
      status: _GsiStatus.activeMonthly,
      pitch:
          'Multi-DPI focused ROM, historically strong on tablets. Ships '
          'Treble GSIs alongside device builds on SourceForge.',
      primary: _GsiLink(
        label: 'SourceForge files',
        url: 'https://sourceforge.net/projects/blissroms/files/',
      ),
      secondary: _GsiLink(
        label: 'GitHub org',
        url: 'https://github.com/BlissRoms',
      ),
    ),
    _GsiProject(
      name: 'phh-Treble (phhusson)',
      status: _GsiStatus.archivedIndexed,
      pitch:
          'The original Treble GSI project. Releases stopped and the '
          'community wiki has since moved to the TrebleDroid fork, which '
          'now hosts the canonical GSI index across every project.',
      primary: _GsiLink(
        label: 'GSI wiki list (TrebleDroid)',
        url:
            'https://github.com/TrebleDroid/treble_experimentations/wiki/Generic-System-Image-%28GSI%29-list',
      ),
      secondary: _GsiLink(
        label: 'Original releases',
        url: 'https://github.com/phhusson/treble_experimentations/releases',
      ),
    ),
    _GsiProject(
      name: 'ArrowOS',
      status: _GsiStatus.discontinued,
      pitch:
          'Minimal AOSP-plus ROM, popular for years. Project shut down: '
          'no new builds, but old GSIs still float around the GitHub org '
          'for legacy Android versions.',
      primary: _GsiLink(
        label: 'GitHub org (archive)',
        url: 'https://github.com/ArrowOS',
      ),
      secondary: _GsiLink(
        label: 'TrebleDroid GSI wiki entry',
        url:
            'https://github.com/TrebleDroid/treble_experimentations/wiki/Generic-System-Image-%28GSI%29-list',
      ),
    ),
    _GsiProject(
      name: 'DotOS',
      status: _GsiStatus.discontinued,
      pitch:
          'Colorful Pixel-style ROM, GSI track went silent. Repos are '
          'still up if you want to grab older Android 11/12 GSIs.',
      primary: _GsiLink(
        label: 'GitHub org (archive)',
        url: 'https://github.com/DotOS',
      ),
      secondary: _GsiLink(
        label: 'TrebleDroid GSI wiki entry',
        url:
            'https://github.com/TrebleDroid/treble_experimentations/wiki/Generic-System-Image-%28GSI%29-list',
      ),
    ),
    _GsiProject(
      name: 'Havoc-OS',
      status: _GsiStatus.discontinued,
      pitch:
          'Once a heavyweight customization ROM with active GSIs. No new '
          'releases for years; SourceForge mirror still hosts legacy '
          'images.',
      primary: _GsiLink(
        label: 'SourceForge files (archive)',
        url: 'https://sourceforge.net/projects/havoc-os/files/',
      ),
      secondary: _GsiLink(
        label: 'GitHub org',
        url: 'https://github.com/Havoc-OS',
      ),
    ),
    _GsiProject(
      name: 'Nusantara Project',
      status: _GsiStatus.discontinued,
      pitch:
          'Indonesia-rooted ROM with a popular GSI track in its time. '
          'Builds have stopped; SourceForge GSI folder remains for legacy '
          'Android versions.',
      primary: _GsiLink(
        label: 'SourceForge GSI files (archive)',
        url: 'https://sourceforge.net/projects/nusantara-project/files/GSI/',
      ),
      secondary: _GsiLink(
        label: 'GitHub org',
        url: 'https://github.com/NusantaraProject',
      ),
    ),
    _GsiProject(
      name: 'Project Matrixx',
      status: _GsiStatus.discontinued,
      pitch:
          'Pixel-style ROM that quietly stopped shipping. SourceForge '
          'GSI archive is the last known mirror.',
      primary: _GsiLink(
        label: 'SourceForge GSI files (archive)',
        url: 'https://sourceforge.net/projects/projectmatrixx/files/GSI/',
      ),
      secondary: _GsiLink(
        label: 'SourceForge project',
        url: 'https://sourceforge.net/projects/projectmatrixx/',
      ),
    ),
    _GsiProject(
      name: 'PixelBuilds',
      status: _GsiStatus.discontinued,
      pitch:
          'Pixel-feel ROM that maintained a Treble GSI for a while. '
          'Project page is still online, but the Treble track has been '
          'abandoned.',
      primary: _GsiLink(
        label: 'GitHub org (archive)',
        url: 'https://github.com/PixelBuildsROM',
      ),
      secondary: _GsiLink(
        label: 'Project site',
        url: 'https://pixelbuilds.org/',
      ),
    ),
  ];

  /// Meta-resources: indexes, forums, places to ask questions. Not
  /// download sources, so they get a smaller secondary strip.
  static const List<_GsiLink> _indexes = <_GsiLink>[
    _GsiLink(
      label: 'XDA Project Treble forum',
      url: 'https://xdaforums.com/c/project-treble.7259/',
    ),
    _GsiLink(
      label: 'r/TrebleGSI',
      url: 'https://www.reddit.com/r/TrebleGSI/',
    ),
    _GsiLink(
      label: 'Search Google for more GSIs',
      url:
          'https://www.google.com/search?q=lineage+os+gsi+treble+arm64_bvN+download',
    ),
  ];

  static const List<_TrebleFaq> _faqs = <_TrebleFaq>[
    _TrebleFaq(
      q: 'GSI boots but the camera/audio is broken',
      a: 'This is the classic GSI tradeoff. Vendor blobs and the AOSP '
          'HAL do not always agree. Try the `vndklite` variant of the '
          'same GSI; it uses the vendor VNDK instead of the GSI one and '
          'usually fixes camera / Bluetooth / sound.',
    ),
    _TrebleFaq(
      q: 'No signal / no SIM',
      a: 'Some GSIs disable the IMS / radio HAL. Look for a Treble fix '
          'thread for your modem on XDA, or try a different GSI version '
          '(downgrade one major Android version is a common cure).',
    ),
    _TrebleFaq(
      q: 'Boot loops straight after flashing',
      a: 'Almost always one of: wrong A-only vs A/B, forgot to wipe '
          'userdata, vbmeta still enforced. Re-check Treble Info output '
          'and try again.',
    ),
    _TrebleFaq(
      q: 'OTAs',
      a: 'Treble GSIs do not get OTAs through the device. Manually flash '
          'the next monthly build the same way as the first install. '
          'No data wipe needed for same-version updates.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return AppShell(
      title: 'Treble & GSI',
      selectedRoute: AppRoutes.treble,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: Breakpoints.readingMaxWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: <Widget>[
              _Hero(blurb: _heroBlurb),
              const SizedBox(height: 20),
              _SectionHeader(
                icon: Icons.fact_check_rounded,
                title: 'Is my device Treble-ready?',
                subtitle: 'Two ways to find out in 30 seconds.',
              ),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < _checks.length; i++) ...<Widget>[
                      _CompatRow(check: _checks[i]),
                      if (i != _checks.length - 1)
                        Divider(height: 1, color: scheme.outlineVariant),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _SectionHeader(
                icon: Icons.tune_rounded,
                title: 'Pick the right GSI variant',
                subtitle:
                    'A GSI is "universal", the variant is not. Match these four axes.',
              ),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < _variants.length; i++) ...<Widget>[
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: scheme.secondaryContainer,
                          foregroundColor: scheme.onSecondaryContainer,
                          child: Text('${i + 1}'),
                        ),
                        title: Text(
                          _variants[i].label,
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(_variants[i].detail),
                        isThreeLine: true,
                      ),
                      if (i != _variants.length - 1)
                        Divider(height: 1, color: scheme.outlineVariant),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _SectionHeader(
                icon: Icons.cloud_download_rounded,
                title: 'Where to download GSIs',
                subtitle:
                    'Four projects worth knowing. Random Telegram links are how phones die.',
              ),
              const SizedBox(height: 12),
              for (int i = 0; i < _featured.length; i++) ...<Widget>[
                _GsiProjectCard(
                  project: _featured[i],
                  onOpen: (String url) => _open(context, url),
                ),
                if (i != _featured.length - 1) const SizedBox(height: 12),
              ],
              const SizedBox(height: 16),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.forum_outlined,
                            size: 18,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Indexes & forums',
                            style: text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Not download sources, but where the community '
                        'actually lives. Search your codename here first.',
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          for (final _GsiLink l in _indexes)
                            ActionChip(
                              avatar: const Icon(
                                Icons.open_in_new_rounded,
                                size: 16,
                              ),
                              label: Text(l.label),
                              onPressed: () => _open(context, l.url),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _SectionHeader(
                icon: Icons.bolt_rounded,
                title: 'Flash a GSI',
                subtitle: 'The whole flow in six steps. Stock firmware vbmeta ready.',
              ),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (int i = 0; i < _flashSteps.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                width: 28,
                                height: 28,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: scheme.primary,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    color: scheme.onPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      _flashSteps[i].title,
                                      style: text.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    _InlineCode(
                                      text: _flashSteps[i].body,
                                      base: text.bodyMedium,
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
              ),
              const SizedBox(height: 28),
              _SectionHeader(
                icon: Icons.help_outline_rounded,
                title: 'Common GSI pitfalls',
                subtitle: 'The four headaches that account for most of the pain.',
              ),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: Column(
                    children: <Widget>[
                      for (final _TrebleFaq f in _faqs)
                        ExpansionTile(
                          leading: Icon(
                            Icons.help_outline_rounded,
                            color: scheme.primary,
                          ),
                          title: Text(
                            f.q,
                            style: text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            16,
                          ),
                          children: <Widget>[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(f.a),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Card(
                color: scheme.errorContainer.withValues(alpha: 0.55),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        Icons.warning_amber_rounded,
                        color: scheme.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Same disclaimer as the Guide',
                              style: text.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.onErrorContainer,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Flashing a GSI is the same kind of risk as '
                              'flashing a custom ROM: bootloops, broken '
                              'sensors, dead modems are all possible. '
                              'Back up, take notes, and have a stock '
                              'firmware ready to restore from.',
                              style: text.bodySmall?.copyWith(
                                color: scheme.onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    final bool ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.blurb});
  final String blurb;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            scheme.primaryContainer,
            scheme.tertiaryContainer,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.layers_rounded,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Project Treble & GSIs',
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            blurb,
            style: text.bodyMedium?.copyWith(
              color: scheme.onPrimaryContainer,
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: scheme.onSecondaryContainer),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
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

class _CompatRow extends StatelessWidget {
  const _CompatRow({required this.check});
  final _TrebleCompatCheck check;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(check.icon, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  check.title,
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                _InlineCode(text: check.body, base: text.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Per-project featured card: name + status chip, what it's good for,
/// and primary + secondary action buttons. Used in the "Where to
/// download GSIs" section.
class _GsiProjectCard extends StatelessWidget {
  const _GsiProjectCard({
    required this.project,
    required this.onOpen,
  });

  final _GsiProject project;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final (Color bg, Color fg, IconData icon) = _statusStyle(project.status, scheme);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    project.name,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(icon, size: 14, color: fg),
                      const SizedBox(width: 6),
                      Text(
                        project.status.label,
                        style: text.labelSmall?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _InlineCode(text: project.pitch, base: text.bodyMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.tonalIcon(
                  onPressed: () => onOpen(project.primary.url),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text(project.primary.label),
                ),
                OutlinedButton.icon(
                  onPressed: () => onOpen(project.secondary.url),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(project.secondary.label),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  (Color, Color, IconData) _statusStyle(_GsiStatus s, ColorScheme scheme) {
    switch (s) {
      case _GsiStatus.activeDaily:
        return (
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
          Icons.bolt_rounded,
        );
      case _GsiStatus.activeMonthly:
        return (
          scheme.secondaryContainer,
          scheme.onSecondaryContainer,
          Icons.calendar_month_rounded,
        );
      case _GsiStatus.referenceQuarterly:
        return (
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
          Icons.verified_rounded,
        );
      case _GsiStatus.archivedIndexed:
        return (
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant,
          Icons.archive_outlined,
        );
      case _GsiStatus.discontinued:
        return (
          scheme.errorContainer,
          scheme.onErrorContainer,
          Icons.do_disturb_on_outlined,
        );
    }
  }
}

/// Splits a string on backticks and renders odd parts as inline code chips,
/// matching the look used in the Guide page.
class _InlineCode extends StatelessWidget {
  const _InlineCode({required this.text, this.base});
  final String text;
  final TextStyle? base;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<String> parts = text.split('`');
    final List<InlineSpan> spans = <InlineSpan>[];
    for (int i = 0; i < parts.length; i++) {
      if (i.isEven) {
        spans.add(TextSpan(text: parts[i]));
      } else {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Text(
                parts[i],
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: (base?.fontSize ?? 14) - 1,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
        );
      }
    }
    return RichText(
      text: TextSpan(style: base, children: spans),
    );
  }
}

class _TrebleCompatCheck {
  const _TrebleCompatCheck({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;
}

class _GsiVariant {
  const _GsiVariant({required this.label, required this.detail});
  final String label;
  final String detail;
}

class _FlashStep {
  const _FlashStep({required this.title, required this.body});
  final String title;
  final String body;
}

class _GsiProject {
  const _GsiProject({
    required this.name,
    required this.status,
    required this.pitch,
    required this.primary,
    required this.secondary,
  });
  final String name;
  final _GsiStatus status;
  final String pitch;
  final _GsiLink primary;
  final _GsiLink secondary;
}

enum _GsiStatus {
  activeDaily('Active, daily'),
  activeMonthly('Active, monthly'),
  referenceQuarterly('Reference, quarterly'),
  archivedIndexed('Archived but indexed'),
  discontinued('Discontinued');

  const _GsiStatus(this.label);
  final String label;
}

class _GsiLink {
  const _GsiLink({required this.label, required this.url});
  final String label;
  final String url;
}

class _TrebleFaq {
  const _TrebleFaq({required this.q, required this.a});
  final String q;
  final String a;
}
