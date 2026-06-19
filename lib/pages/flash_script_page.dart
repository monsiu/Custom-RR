import 'dart:io' show Directory, File, Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/catalog_repository.dart';
import '../models.dart';
import '../routes.dart';
import '../util/breakpoints.dart';
import '../widgets/app_shell.dart';

/// Stable upstream download link for Magisk, surfaced as a chip and inside
/// the generated script so users do not have to copy a URL out of a comment.
const String kMagiskReleasesUrl =
    'https://github.com/topjohnwu/Magisk/releases';

/// Generates a copy-pasteable shell script for flashing a chosen
/// ROM + recovery onto a chosen (brand, codename) device.
///
/// The generator is intentionally conservative: it emits commented-out
/// steps for partition flashes (so the user understands them) and prints
/// the fastboot / adb sequence in order. It does NOT execute anything.
class FlashScriptPage extends StatefulWidget {
  const FlashScriptPage({
    super.key,
    this.initialBrand,
    this.initialCodename,
    this.initialRomId,
    this.initialRecoveryId,
  });

  final String? initialBrand;
  final String? initialCodename;
  final String? initialRomId;
  final String? initialRecoveryId;

  @override
  State<FlashScriptPage> createState() => _FlashScriptPageState();
}

class _FlashScriptPageState extends State<FlashScriptPage> {
  String? _brand;
  String? _codename;
  String? _romId;
  String? _recoveryId;
  bool _wantsGapps = true;
  bool _wantsMagisk = false;
  bool _wipeData = true;
  bool _gsiMode = false;

  @override
  void initState() {
    super.initState();
    _brand = widget.initialBrand;
    _codename = widget.initialCodename;
    _romId = widget.initialRomId;
    _recoveryId = widget.initialRecoveryId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowGuideWarning();
    });
  }

  /// Shows a one-time heads-up modal the first time the generator opens,
  /// steering users to the more detailed Guide and asking testers to file
  /// GitHub issues. Suppressed once the user ticks "Don't show this again".
  Future<void> _maybeShowGuideWarning() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kSuppressFlashGuideWarningKey) ?? false) return;
    if (!mounted) return;
    final _FlashGuideAction? action = await showDialog<_FlashGuideAction>(
      context: context,
      builder: (BuildContext _) => const _FlashGuideWarningDialog(),
    );
    if (!mounted) return;
    switch (action) {
      case _FlashGuideAction.readGuide:
        context.push(AppRoutes.instructions);
        break;
      case _FlashGuideAction.reportIssue:
        await _openFeedbackIssue();
        break;
      case _FlashGuideAction.dismiss:
      case null:
        break;
    }
  }

  /// Opens the GitHub bug-report form so testers can report a step that is
  /// wrong or missing for their device.
  Future<void> _openFeedbackIssue() async {
    final Uri uri = Uri.https(
      'github.com',
      '/monsiu/Custom-RR/issues/new',
      <String, String>{
        'template': 'bug_report.yml',
        'title': 'Flash script generator: ',
      },
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Clears every selection and option back to defaults.
  void _reset() {
    setState(() {
      _brand = null;
      _codename = null;
      _romId = null;
      _recoveryId = null;
      _wantsGapps = true;
      _wantsMagisk = false;
      _wipeData = true;
      _gsiMode = false;
    });
  }

  /// Explains when GSI / Treble mode is the right choice: it is the universal
  /// fallback for devices that are not in the catalog. Users whose device is
  /// already catalogued are pointed at the device-specific ROM instead.
  Future<void> _showGsiHelp() async {
    final TextTheme text = Theme.of(context).textTheme;
    final bool? browse = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        icon: const Icon(Icons.help_outline),
        title: const Text('When to use GSI / Treble mode'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'This mode is the universal fallback for any device that is not '
              'in the catalog. A Generic System Image (GSI) boots on almost '
              'any Treble-compatible device (Android 9 or newer), so you do '
              'not need a build made for your exact model.',
              style: text.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'First check whether your device is already in the catalog. If '
              'it is, a device-specific ROM is usually the better fit, so '
              'flash that instead of a GSI.',
              style: text.bodyMedium,
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Got it'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.smartphone_outlined, size: 18),
            label: const Text('Browse devices'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (browse ?? false) context.push(AppRoutes.devices);
  }

  List<DeviceRef> _devicesForBrand(String? brand) {
    if (brand == null) return const <DeviceRef>[];
    final CatalogRepository repo = CatalogRepository.instance;
    final Map<String, DeviceRef> seen = <String, DeviceRef>{};
    for (final CatalogEntry e in <CatalogEntry>[
      ...repo.roms,
      ...repo.recoveries,
    ]) {
      for (final DeviceRef d in e.devices) {
        if (d.brand != brand || d.codename.isEmpty) continue;
        seen.putIfAbsent(d.codename, () => d);
      }
    }
    final List<DeviceRef> out = seen.values.toList()
      ..sort(
        (DeviceRef a, DeviceRef b) =>
            a.model.toLowerCase().compareTo(b.model.toLowerCase()),
      );
    return out;
  }

  /// Recoveries catalogued for any device of [brand]. Used by GSI mode, which
  /// has no codename to filter on, to keep the optional recovery list scoped
  /// to the brand instead of listing the whole catalog.
  List<CatalogEntry> _recoveriesForBrand(String brand) {
    return CatalogRepository.instance.recoveries
        .where(
          (CatalogEntry e) =>
              e.devices.any((DeviceRef d) => d.brand == brand),
        )
        .toList();
  }

  String _generate() {
    final CatalogRepository repo = CatalogRepository.instance;
    final CatalogEntry? rom = _romId == null ? null : repo.romById(_romId!);
    final CatalogEntry? rec =
        _recoveryId == null ? null : repo.recoveryById(_recoveryId!);
    final String device = '$_brand $_codename';
    final StringBuffer b = StringBuffer();
    b.writeln('#!/usr/bin/env bash');
    b.writeln('# Generated by Custom RR · flash-script helper');
    b.writeln('# Author : Monsiu (https://github.com/monsiu)');
    b.writeln('# Source : https://github.com/monsiu/Custom-RR');
    b.writeln('# Device : $device');
    if (rom != null) b.writeln('# ROM    : ${rom.name} (${rom.downloadUrl})');
    if (rec != null) {
      b.writeln('# Recovery: ${rec.name} (${rec.downloadUrl})');
    }
    b.writeln('# Options: gapps=$_wantsGapps, magisk=$_wantsMagisk, '
        'wipeData=$_wipeData');
    b.writeln('#');
    b.writeln('# REVIEW EVERY STEP BEFORE RUNNING. Flashing the wrong file');
    b.writeln('# WILL BRICK YOUR PHONE. Make a full backup first.');
    b.writeln('#');
    b.writeln('# This is a STEP-BY-STEP CHECKLIST, not an unattended');
    b.writeln('# installer. The phone reboots and switches USB modes between');
    b.writeln('# steps, so running the whole file at once will fail. Run one');
    b.writeln('# block at a time and confirm the phone is in the expected mode');
    b.writeln('# (bootloader / recovery) before continuing.');
    b.writeln('set -euo pipefail');
    b.writeln();
    b.writeln('# Helper: block until the phone is back in fastboot (bootloader');
    b.writeln('# or fastbootd) instead of a fixed sleep, so slow and fast');
    b.writeln('# devices both work.');
    b.writeln(
      'wait_fastboot() { until fastboot devices | grep -q .; do sleep 1; done; }',
    );
    b.writeln();
    b.writeln('# 1. Prereqs (host machine):');
    b.writeln('#    - platform-tools (adb + fastboot) installed and on PATH');
    b.writeln(
      '#    - USB debugging + OEM unlocking enabled in Developer Options',
    );
    b.writeln('#    - Bootloader unlocked for $_brand $_codename');
    b.writeln('#      (see the manufacturer\'s official instructions; some');
    b.writeln('#       brands need a server-side unlock token first.)');
    b.writeln();
    b.writeln('# 2. Place these files in the current directory:');
    if (rec != null) {
      b.writeln(
        '#    - recovery.img       (downloaded from ${rec.downloadUrl})',
      );
    }
    if (rom != null) {
      b.writeln(
        '#    - rom.zip            (downloaded from ${rom.downloadUrl})',
      );
    }
    if (_wantsGapps) {
      b.writeln(
        '#    - gapps.zip          (e.g. MindTheGapps or NikGApps for your Android version)',
      );
    }
    if (_wantsMagisk) {
      b.writeln(
        '#    - magisk.zip         (from $kMagiskReleasesUrl)',
      );
    }
    b.writeln();
    b.writeln('echo "==> Reboot to bootloader"');
    b.writeln('adb reboot bootloader');
    b.writeln('wait_fastboot');
    b.writeln();
    if (rec != null) {
      b.writeln('echo "==> Flash custom recovery (${rec.name})"');
      b.writeln(
        '# On A/B devices most projects recommend `fastboot boot` first',
      );
      b.writeln('# to verify the recovery image actually boots before making');
      b.writeln('# it permanent.');
      b.writeln('fastboot boot recovery.img');
      b.writeln(
        '# Once you have confirmed the recovery boots cleanly, you can',
      );
      b.writeln('# flash it permanently from inside the recovery itself, or:');
      b.writeln('#   fastboot flash boot recovery.img      # A/B devices');
      b.writeln('#   fastboot flash recovery recovery.img  # A-only devices');
      b.writeln();
    }
    b.writeln(
      'echo "==> Inside ${rec?.name ?? 'recovery'}, perform these steps"',
    );
    int step = 1;
    if (_wipeData) {
      b.writeln('#   ${step++}) Wipe -> Format Data (yes/erase encryption)');
      b.writeln(
        '#   ${step++}) Wipe -> Advanced Wipe -> Dalvik / ART Cache + Cache',
      );
    } else {
      b.writeln(
        '#   ${step++}) (Optional) Wipe -> Dalvik / Cache to clear stale runtime data',
      );
    }
    b.writeln('#   ${step++}) Reboot to recovery again if asked');
    b.writeln('#   ${step++}) Install -> rom.zip');
    if (_wantsGapps) {
      b.writeln('#   ${step++}) Install -> gapps.zip (do not reboot in between)');
    }
    if (_wantsMagisk) {
      b.writeln(
        '#   ${step++}) Install -> magisk.zip (last, so it patches the freshly-flashed boot image)',
      );
    }
    b.writeln('#   ${step++}) Reboot system');
    b.writeln();
    b.writeln('# 3. Alternative ADB sideload (if you prefer):');
    b.writeln('#    adb sideload rom.zip');
    if (_wantsGapps) b.writeln('#    adb sideload gapps.zip');
    if (_wantsMagisk) b.writeln('#    adb sideload magisk.zip');
    b.writeln();
    b.writeln(
      '# 4. First boot can take 5-15 minutes while Android optimises apps.',
    );
    b.writeln('#    Do NOT pull the battery / cable during this step.');
    b.writeln();
    b.writeln(
      'echo "==> Done. Verify the build with: getprop ro.build.version.release"',
    );
    return b.toString();
  }

  /// Generates a GSI / Treble flow: unlock, disable Verified Boot, then flash
  /// a generic system.img from fastbootd. Samsung devices use Download mode
  /// (Heimdall/Odin) + TWRP to reach fastbootd instead of a normal bootloader.
  String _generateGsi() {
    final CatalogRepository repo = CatalogRepository.instance;
    final CatalogEntry? rec =
        _recoveryId == null ? null : repo.recoveryById(_recoveryId!);
    final bool samsung = (_brand ?? '').toLowerCase() == 'samsung';
    final StringBuffer b = StringBuffer();
    b.writeln('#!/usr/bin/env bash');
    b.writeln('# Generated by Custom RR · flash-script helper (GSI / Treble)');
    b.writeln('# Author : Monsiu (https://github.com/monsiu)');
    b.writeln('# Source : https://github.com/monsiu/Custom-RR');
    b.writeln('# Target : ${(_brand ?? '').isEmpty ? 'Any' : _brand} '
        'Project Treble device (the GSI flow is the same across the brand)');
    if (samsung && rec != null) {
      b.writeln('# Recovery: ${rec.name} (${rec.downloadUrl})');
    }
    b.writeln('# Options: gapps=$_wantsGapps, magisk=$_wantsMagisk, '
        'wipeData=$_wipeData');
    b.writeln('#');
    b.writeln('# A GSI (Generic System Image) is one system.img that boots on');
    b.writeln('# any Treble device. Download an arm64 GSI from the Treble hub in');
    b.writeln('# Custom RR and match its layout to your device (usually A-only');
    b.writeln('# for Samsung/Unisoc, A/B for most others).');
    b.writeln('#');
    b.writeln('# REVIEW EVERY STEP. Unlocking the bootloader WILL ERASE the');
    b.writeln('# device, and a wrong image can brick it. Back up first.');
    b.writeln('#');
    b.writeln('# This is a STEP-BY-STEP CHECKLIST, not an unattended');
    b.writeln('# installer. The phone reboots and switches USB modes between');
    b.writeln('# steps (bootloader, recovery, fastbootd), so running the whole');
    b.writeln('# file at once will fail. Run one block at a time and confirm');
    b.writeln('# the phone is in the expected mode before continuing.');
    b.writeln('set -euo pipefail');
    b.writeln();
    b.writeln('# Helper: block until the phone is back in fastboot instead of a');
    b.writeln('# fixed sleep, so slow and fast devices both work.');
    b.writeln(
      'wait_fastboot() { until fastboot devices | grep -q .; do sleep 1; done; }',
    );
    if (samsung) {
      b.writeln('# Samsung: wait for Download mode the same way.');
      b.writeln(
        'wait_download() { until heimdall detect >/dev/null 2>&1; do sleep 1; done; }',
      );
    }
    b.writeln();
    b.writeln('# 1. Host prereqs: platform-tools (adb + fastboot) on PATH.');
    if (samsung) {
      b.writeln('#    Samsung also needs Heimdall (Linux/macOS) or Odin');
      b.writeln('#    (Windows) for Download-mode flashing, plus USB drivers.');
    }
    b.writeln('#');
    b.writeln('# 2. Put these files in the current directory:');
    b.writeln('#    - system.img    (the arm64 GSI; unzip/unxz it first)');
    b.writeln('#    - vbmeta.img    (empty vbmeta with verification disabled)');
    if (samsung) {
      b.writeln(
        rec != null
            ? '#    - recovery.img  (${rec.name}, from ${rec.downloadUrl})'
            : '#    - recovery.img  (a TWRP/OrangeFox built for your device)',
      );
    }
    if (_wantsGapps) {
      b.writeln('#    - gapps.zip     (only if the GSI is vanilla, no Google)');
    }
    if (_wantsMagisk) {
      b.writeln('#    - magisk.zip    (rename Magisk-vXX.apk to magisk.zip)');
    }
    b.writeln();
    b.writeln('# 3. On the device: enable Developer options, then turn ON');
    b.writeln('#    "OEM unlocking" and "USB debugging".');
    if (samsung) {
      b.writeln('#    Samsung: if "OEM unlocking" is greyed out, keep the device');
      b.writeln('#    online and wait up to 7 days (the KG / RMM state lock).');
    }
    b.writeln();
    if (samsung) {
      b.writeln(
        '# 4. Unlock the bootloader in Download mode (ERASES the device):',
      );
      b.writeln('#    a. Power off the device.');
      b.writeln('#    b. Hold Volume-Up + Volume-Down, then plug in USB to enter');
      b.writeln('#       Download mode.');
      b.writeln('#    c. Long-press Volume-Up to unlock and confirm. It resets.');
      b.writeln('#    d. Boot to Android, redo setup, re-enable USB debugging.');
      b.writeln();
      b.writeln('echo "==> Reboot to Download mode"');
      b.writeln('adb reboot download');
      b.writeln('wait_download');
      if (rec != null) {
        b.writeln('echo "==> Flash recovery (${rec.name}); do NOT auto-reboot"');
        b.writeln('heimdall flash --RECOVERY recovery.img --no-reboot');
        b.writeln('#   Odin users: load the recovery .tar in AP, UNCHECK Auto');
        b.writeln('#   Reboot, then Start. Immediately hold Volume-Up + Power to');
        b.writeln('#   boot into recovery so stock cannot restore itself.');
      } else {
        b.writeln('#   Flash a TWRP/OrangeFox recovery built for your device');
        b.writeln('#   (see the Recoveries section in Custom RR or its XDA');
        b.writeln('#   thread): heimdall flash --RECOVERY recovery.img');
        b.writeln('#   --no-reboot  (or Odin: AP slot, Auto Reboot OFF), then');
        b.writeln('#   boot straight into it.');
      }
      b.writeln();
      b.writeln('# 5. In recovery (TWRP): disable Verified Boot and wipe.');
      if (_wipeData) {
        b.writeln('#    - Wipe > Format Data > type "yes" (removes encryption).');
      }
      b.writeln('#    - Install > Install Image > vbmeta.img > flash it to the');
      b.writeln('#      "vbmeta" partition.');
      b.writeln();
      b.writeln('# 6. Flash the GSI from fastbootd.');
      b.writeln('echo "==> From TWRP: Reboot > fastbootd (or run the line below)"');
      b.writeln('adb reboot fastboot   # fastbootD (userspace), NOT bootloader');
    } else {
      b.writeln('# 4. Unlock the bootloader (ERASES the device):');
      b.writeln('echo "==> Reboot to bootloader"');
      b.writeln('adb reboot bootloader');
      b.writeln('wait_fastboot');
      b.writeln('echo "==> Unlock (confirm on-device with Volume + Power)"');
      b.writeln('fastboot flashing unlock || fastboot oem unlock');
      b.writeln();
      b.writeln('# 5. Disable Verified Boot so the GSI will boot.');
      b.writeln('echo "==> Flash empty vbmeta with verification disabled"');
      b.writeln(
        'fastboot --disable-verity --disable-verification flash vbmeta vbmeta.img',
      );
      b.writeln();
      b.writeln('# 6. Flash the GSI from fastbootd.');
      b.writeln('echo "==> Reboot to fastbootd"');
      b.writeln('adb reboot fastboot   # fastbootD (userspace), NOT bootloader');
    }
    b.writeln('wait_fastboot');
    b.writeln('echo "==> Flash the GSI to the system partition"');
    b.writeln('fastboot flash system system.img');
    if (_wipeData) {
      b.writeln('echo "==> Wipe data for a clean first boot"');
      b.writeln('fastboot -w');
    }
    b.writeln('echo "==> Reboot"');
    b.writeln('fastboot reboot');
    b.writeln();
    if (_wantsGapps || _wantsMagisk) {
      if (samsung) {
        b.writeln('# 7. Optional extras (boot back into your recovery):');
        if (_wantsGapps) {
          b.writeln('#    - gapps.zip   (skip if you used a GApps/GMS GSI build)');
        }
        if (_wantsMagisk) {
          b.writeln('#    - magisk.zip  (flash LAST so it patches the new system)');
        }
      } else {
        b.writeln('# 7. Optional extras. This flow installs NO custom recovery,');
        b.writeln('#    so you cannot just flash a zip:');
        if (_wantsGapps) {
          b.writeln('#    - GApps: use a GApps/GMS GSI build instead of flashing');
          b.writeln('#      gapps.zip, or flash a custom recovery first.');
        }
        if (_wantsMagisk) {
          b.writeln('#    - Magisk: boot the GSI once, install the Magisk app,');
          b.writeln('#      use "Install > Select and Patch a File" on your stock');
          b.writeln('#      boot.img, then from fastboot:');
          b.writeln('#      fastboot flash boot magisk_patched.img');
        }
      }
      b.writeln();
    }
    b.writeln('# First boot takes 5-15 minutes. If it bootloops, recheck: data');
    b.writeln('# was formatted, vbmeta verification is disabled, and the GSI is');
    b.writeln('# the right arch (arm64) and layout (A-only vs A/B) for the phone.');
    b.writeln(
      'echo "==> Done. Verify with: adb shell getprop ro.build.version.release"',
    );
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final CatalogRepository repo = CatalogRepository.instance;
    final List<String> brands =
        repo.devices.map((DeviceEntry d) => d.name).toList();
    final List<DeviceRef> models = _devicesForBrand(_brand);
    final List<CatalogEntry> roms = _brand == null || _codename == null
        ? repo.roms
        : repo.romsForCodename(_brand!, _codename!);
    // GSI mode has no codename, so scope recoveries to the brand rather than
    // listing every recovery in the catalog.
    final List<CatalogEntry> recs = _gsiMode
        ? (_brand == null ? repo.recoveries : _recoveriesForBrand(_brand!))
        : (_brand == null || _codename == null
            ? repo.recoveries
            : repo.recoveriesForCodename(_brand!, _codename!));
    final bool ready = _gsiMode
        ? (_brand != null)
        : (_brand != null &&
            _codename != null &&
            _romId != null &&
            _recoveryId != null);
    final CatalogEntry? selectedRom =
        _romId == null ? null : repo.romById(_romId!);
    final CatalogEntry? selectedRec =
        _recoveryId == null ? null : repo.recoveryById(_recoveryId!);

    return AppShell(
      title: 'Flash script generator',
      selectedRoute: AppRoutes.flashScript,
      actions: <Widget>[
        IconButton(
          tooltip: 'Reset selections',
          icon: const Icon(Icons.restart_alt),
          onPressed: _reset,
        ),
      ],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: Breakpoints.readingMaxWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Text(
                'Pick your phone and the projects you want to flash. A shell '
                'script appears below as a step-by-step checklist. Review and '
                'run each block yourself; it is not a one-tap installer.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _LabelledDropdown<String>(
                label: 'Brand',
                value: _brand,
                items: brands,
                itemLabel: (String s) => s,
                onChanged: (String? v) => setState(() {
                  _brand = v;
                  _codename = null;
                }),
              ),
              const SizedBox(height: 12),
              if (!_gsiMode) ...<Widget>[
                _LabelledDropdown<String>(
                  label: 'Model / codename',
                  value: _codename,
                  items: models.map((DeviceRef d) => d.codename).toList(),
                  itemLabel: (String c) {
                    final DeviceRef d = models.firstWhere(
                      (DeviceRef m) => m.codename == c,
                      orElse: () =>
                          DeviceRef(brand: _brand ?? '', model: c, codename: c),
                    );
                    return '${d.model}  ·  $c';
                  },
                  onChanged: models.isEmpty
                      ? null
                      : (String? v) => setState(() => _codename = v),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.push(AppRoutes.findPhone),
                    icon: const Icon(Icons.help_outline, size: 16),
                    label: const Text("Don't know your codename?"),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
              SwitchListTile(
                title: Row(
                  children: <Widget>[
                    const Flexible(child: Text('GSI / Treble mode')),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.help_outline, size: 18),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'When to use GSI / Treble mode',
                      onPressed: _showGsiHelp,
                    ),
                  ],
                ),
                subtitle: const Text(
                  'Flash a generic system image (system.img) instead of a '
                  'recovery-installable ROM zip. Suits most Treble devices, '
                  'including Samsung, Unisoc, and MediaTek phones and tablets. '
                  'The exact model is not needed; the steps are the same '
                  "across a brand's Treble devices.",
                ),
                value: _gsiMode,
                onChanged: (bool v) => setState(() => _gsiMode = v),
              ),
              const SizedBox(height: 12),
              if (!_gsiMode) ...<Widget>[
                _LabelledDropdown<String>(
                  label: 'ROM',
                  value: _romId,
                  items: roms.map((CatalogEntry e) => e.id).toList(),
                  itemLabel: (String id) =>
                      roms.firstWhere((CatalogEntry e) => e.id == id).name,
                  onChanged: (String? v) => setState(() => _romId = v),
                ),
                const SizedBox(height: 12),
              ],
              _LabelledDropdown<String>(
                label:
                    _gsiMode ? 'Recovery (optional, for vbmeta)' : 'Recovery',
                value: _recoveryId,
                items: recs.map((CatalogEntry e) => e.id).toList(),
                itemLabel: (String id) =>
                    recs.firstWhere((CatalogEntry e) => e.id == id).name,
                onChanged: (String? v) => setState(() => _recoveryId = v),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Include GApps'),
                subtitle: const Text('Adds a separate gapps.zip flash step.'),
                value: _wantsGapps,
                onChanged: (bool v) => setState(() => _wantsGapps = v),
              ),
              SwitchListTile(
                title: const Text('Include Magisk (root)'),
                subtitle:
                    const Text('Flash Magisk last so it patches the new boot.'),
                value: _wantsMagisk,
                onChanged: (bool v) => setState(() => _wantsMagisk = v),
              ),
              SwitchListTile(
                title: const Text('Wipe data (clean flash)'),
                subtitle: const Text(
                  'Strongly recommended when switching between different ROMs.',
                ),
                value: _wipeData,
                onChanged: (bool v) => setState(() => _wipeData = v),
              ),
              const SizedBox(height: 16),
              if (!ready)
                _NotReadyHint(gsiMode: _gsiMode)
              else ...<Widget>[
                _DownloadChips(
                  rom: _gsiMode ? null : selectedRom,
                  recovery: selectedRec,
                  wantsMagisk: _wantsMagisk,
                  gsiMode: _gsiMode,
                ),
                _ScriptOutput(text: _gsiMode ? _generateGsi() : _generate()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LabelledDropdown<T> extends StatelessWidget {
  const _LabelledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: items.contains(value) ? value : null,
          isExpanded: true,
          hint: Text(items.isEmpty ? '(none available)' : 'Select…'),
          onChanged: items.isEmpty ? null : onChanged,
          items: <DropdownMenuItem<T>>[
            for (final T item in items)
              DropdownMenuItem<T>(value: item, child: Text(itemLabel(item))),
          ],
        ),
      ),
    );
  }
}

class _ScriptOutput extends StatelessWidget {
  const _ScriptOutput({required this.text});
  final String text;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Script copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Saves or shares the script as a real `flash.sh` file. On phones it opens
  /// the system share sheet; on desktop it writes the file to the Downloads
  /// folder; on web (no filesystem) it falls back to sharing the text.
  Future<void> _saveOrShare(BuildContext context) async {
    if (kIsWeb) {
      await SharePlus.instance.share(
        ShareParams(text: text, subject: 'flash.sh'),
      );
      return;
    }
    final bool isMobile = Platform.isAndroid || Platform.isIOS;
    try {
      if (isMobile) {
        final Directory dir = await getTemporaryDirectory();
        final File file = File('${dir.path}/flash.sh');
        await file.writeAsString(text);
        await SharePlus.instance.share(
          ShareParams(
            files: <XFile>[
              XFile(file.path, mimeType: 'application/x-sh'),
            ],
            subject: 'flash.sh',
          ),
        );
      } else {
        Directory? dir = await getDownloadsDirectory();
        dir ??= await getApplicationDocumentsDirectory();
        final File file = File('${dir.path}/flash.sh');
        await file.writeAsString(text);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to ${file.path}'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Copy path',
              onPressed: () => Clipboard.setData(ClipboardData(text: file.path)),
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save the script: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: scheme.surfaceContainerHighest,
            child: Row(
              children: <Widget>[
                const Icon(Icons.terminal, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'flash.sh',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Copy',
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copy(context),
                ),
                IconButton(
                  tooltip: 'Save / share flash.sh',
                  icon: const Icon(Icons.ios_share),
                  onPressed: () => _saveOrShare(context),
                ),
              ],
            ),
          ),
          Container(
            color: scheme.surface,
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              text,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when the user has not picked enough to generate a script. Carries
/// quick links so an empty form still has a path forward.
class _NotReadyHint extends StatelessWidget {
  const _NotReadyHint({required this.gsiMode});

  final bool gsiMode;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              gsiMode
                  ? 'Pick a brand to generate the GSI script.'
                  : 'Pick a brand, codename, ROM, and recovery to generate '
                      'the script.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: gsiMode
                  ? <Widget>[
                      OutlinedButton.icon(
                        onPressed: () => context.push(AppRoutes.treble),
                        icon: const Icon(Icons.layers_outlined, size: 18),
                        label: const Text('Browse Treble & GSI'),
                      ),
                    ]
                  : <Widget>[
                      OutlinedButton.icon(
                        onPressed: () => context.push(AppRoutes.roms),
                        icon: const Icon(Icons.android_outlined, size: 18),
                        label: const Text('Browse ROMs'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.push(AppRoutes.recoveries),
                        icon: const Icon(Icons.restore, size: 18),
                        label: const Text('Browse recoveries'),
                      ),
                    ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tappable download links for the files the chosen script needs, so the user
/// does not have to copy URLs out of the script comments.
class _DownloadChips extends StatelessWidget {
  const _DownloadChips({
    required this.rom,
    required this.recovery,
    required this.wantsMagisk,
    required this.gsiMode,
  });

  final CatalogEntry? rom;
  final CatalogEntry? recovery;
  final bool wantsMagisk;
  final bool gsiMode;

  @override
  Widget build(BuildContext context) {
    final List<Widget> chips = <Widget>[];
    if (rom != null && rom!.downloadUrl.isNotEmpty) {
      chips.add(
        _chip(
          context,
          Icons.download_outlined,
          'ROM download',
          () => _open(context, rom!.downloadUrl),
        ),
      );
    }
    if (recovery != null && recovery!.downloadUrl.isNotEmpty) {
      chips.add(
        _chip(
          context,
          Icons.download_outlined,
          'Recovery download',
          () => _open(context, recovery!.downloadUrl),
        ),
      );
    }
    if (gsiMode) {
      chips.add(
        _chip(
          context,
          Icons.layers_outlined,
          'GSI builds',
          () => context.push(AppRoutes.treble),
        ),
      );
    }
    if (wantsMagisk) {
      chips.add(
        _chip(
          context,
          Icons.download_outlined,
          'Magisk',
          () => _open(context, kMagiskReleasesUrl),
        ),
      );
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Get the files', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
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

/// SharedPreferences key for suppressing the flash-generator guide warning.
const String _kSuppressFlashGuideWarningKey =
    'flashScript.suppressGuideWarning';

/// Buttons offered by the [_FlashGuideWarningDialog].
enum _FlashGuideAction { readGuide, reportIssue, dismiss }

/// Heads-up modal shown when the flash-script generator opens. Points users
/// at the more detailed Guide before they start flashing, and asks testers to
/// report problems on GitHub. Mirrors the one-time warning pattern used by the
/// XDA search dialog.
class _FlashGuideWarningDialog extends StatefulWidget {
  const _FlashGuideWarningDialog();

  @override
  State<_FlashGuideWarningDialog> createState() =>
      _FlashGuideWarningDialogState();
}

class _FlashGuideWarningDialogState extends State<_FlashGuideWarningDialog> {
  bool _dontShowAgain = false;

  Future<void> _pop(_FlashGuideAction action) async {
    if (_dontShowAgain) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kSuppressFlashGuideWarningKey, true);
    }
    if (!mounted) return;
    Navigator.of(context).pop(action);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: scheme.primary),
      title: const Text('Read the guide first'),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'This only generates a starting-point script, and flashing the '
            'wrong file can brick a device. The Guide covers the full process '
            'in more detail and is the safer place to start.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'This feature is new and needs testers. If a step is wrong for '
            'your device, please open a GitHub issue so it can be fixed.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 4),
          CheckboxListTile(
            value: _dontShowAgain,
            onChanged: (bool? v) =>
                setState(() => _dontShowAgain = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text("Don't show this again"),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton.icon(
          onPressed: () => _pop(_FlashGuideAction.reportIssue),
          icon: const Icon(Icons.bug_report_outlined, size: 18),
          label: const Text('Report issue'),
        ),
        TextButton(
          onPressed: () => _pop(_FlashGuideAction.dismiss),
          child: const Text('Continue anyway'),
        ),
        FilledButton.icon(
          onPressed: () => _pop(_FlashGuideAction.readGuide),
          icon: const Icon(Icons.menu_book_rounded, size: 18),
          label: const Text('Read the guide'),
        ),
      ],
    );
  }
}
