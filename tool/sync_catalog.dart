// Catalog sync script. Run with:
//
//   dart run tool/sync_catalog.dart
//
// What it does:
//   1. Downloads the LineageOS wiki repo tarball (cached at
//      `tool/.cache/lineage_wiki/`).
//   2. Parses every `_data/devices/*.yml` into a structured device record
//      (vendor, marketing name, codename, supported LineageOS versions,
//      release year, current branch).
//   3. Writes a fully populated `assets/catalog.json` with:
//        - every ROM/recovery listing real (brand, model, codename) tuples
//          in its `devices` array,
//        - top-level `devices` covering every manufacturer that appears.
//
// For ROMs other than LineageOS we use a known device-coverage policy
// (mostly Treble GSI sets + popular Snapdragon Xiaomi / OnePlus / Pixel /
// Samsung devices). The mapping is derived from each project's public
// device list and can be tuned in [_policyFor] below without re-scraping.
//
// This script is run on the developer's machine (or CI). The shipped app
// only reads the resulting JSON.

import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

const String _wikiTarUrl =
    'https://github.com/LineageOS/lineage_wiki/archive/refs/heads/main.tar.gz';
const String _cacheDir = 'tool/.cache/lineage_wiki';
const String _catalogPath = 'assets/catalog.json';

Future<void> main(List<String> args) async {
  final bool refresh = args.contains('--refresh');
  final Directory cache = Directory('$_cacheDir/devices');

  if (refresh || !cache.existsSync() || cache.listSync().isEmpty) {
    stdout.writeln('[sync] downloading LineageOS wiki tarball...');
    await _downloadWiki();
  } else {
    stdout.writeln('[sync] using cached wiki at ${cache.path}');
  }

  final List<_Device> devices = _parseAllDevices(cache);
  stdout.writeln('[sync] parsed ${devices.length} LineageOS devices');

  // Group by vendor to compute brand sets and most common phones.
  final Map<String, List<_Device>> byVendor = <String, List<_Device>>{};
  for (final _Device d in devices) {
    byVendor.putIfAbsent(d.vendor, () => <_Device>[]).add(d);
  }
  final List<String> vendors = byVendor.keys.toList()..sort();
  stdout.writeln('[sync] ${vendors.length} distinct manufacturers found');

  // Build the JSON.
  final Map<String, dynamic> root = <String, dynamic>{
    '_generated': 'tool/sync_catalog.dart',
    '_generatedAt': DateTime.now().toUtc().toIso8601String(),
    'roms': _buildRoms(devices),
    'recoveries': _buildRecoveries(devices),
    'devices': _buildDevices(vendors),
  };

  const JsonEncoder pretty = JsonEncoder.withIndent('  ');
  File(_catalogPath).writeAsStringSync('${pretty.convert(root)}\n');
  stdout.writeln('[sync] wrote $_catalogPath');
}

Future<void> _downloadWiki() async {
  Directory(_cacheDir).createSync(recursive: true);
  final String tarPath = '$_cacheDir/wiki.tar.gz';
  final ProcessResult curl = await Process.run('curl', <String>[
    '-sSL',
    '--max-time',
    '180',
    _wikiTarUrl,
    '-o',
    tarPath,
  ]);
  if (curl.exitCode != 0) {
    throw StateError('curl failed: ${curl.stderr}');
  }
  // Extract only _data/devices/*.yml using --strip-components.
  final ProcessResult tar = await Process.run('tar', <String>[
    '-xzf',
    tarPath,
    '-C',
    _cacheDir,
    '--strip-components=2',
    'lineage_wiki-main/_data/devices',
  ]);
  if (tar.exitCode != 0) {
    throw StateError('tar failed: ${tar.stderr}');
  }
}

List<_Device> _parseAllDevices(Directory devicesDir) {
  final List<_Device> out = <_Device>[];
  for (final FileSystemEntity e in devicesDir.listSync()) {
    if (e is! File || !e.path.endsWith('.yml')) continue;
    try {
      final YamlMap y = loadYaml(e.readAsStringSync()) as YamlMap;
      final String vendor = (y['vendor'] as String?)?.trim() ?? '';
      final String name = (y['name'] as String?)?.trim() ?? '';
      final String codename = (y['codename'] as String?)?.trim() ?? '';
      final String currentBranch =
          (y['current_branch']?.toString() ?? '').trim();
      final String release = (y['release']?.toString() ?? '').trim();
      final String type = (y['type'] as String?)?.trim() ?? 'phone';
      if (vendor.isEmpty || name.isEmpty || codename.isEmpty) continue;
      out.add(
        _Device(
          vendor: _normalizeVendor(vendor),
          model: name,
          codename: codename,
          type: type,
          currentBranch: currentBranch,
          releaseYear: _yearOf(release),
        ),
      );
    } on Object catch (err) {
      stderr.writeln('[sync] skip ${e.path}: $err');
    }
  }
  out.sort((_Device a, _Device b) {
    final int v = a.vendor.compareTo(b.vendor);
    if (v != 0) return v;
    return a.model.toLowerCase().compareTo(b.model.toLowerCase());
  });
  return out;
}

int? _yearOf(String release) {
  if (release.length < 4) return null;
  return int.tryParse(release.substring(0, 4));
}

String _normalizeVendor(String v) {
  switch (v.toLowerCase()) {
    case 'google':
      return 'Google';
    case 'xiaomi':
      return 'Xiaomi';
    case 'redmi':
      return 'Xiaomi';
    case 'poco':
      return 'Xiaomi';
    case 'oneplus':
      return 'OnePlus';
    case 'samsung':
      return 'Samsung';
    case 'sony':
      return 'Sony';
    case 'motorola':
      return 'Motorola';
    case 'nokia':
      return 'Nokia';
    case 'lenovo':
      return 'Lenovo';
    case 'huawei':
      return 'Huawei';
    case 'honor':
      return 'Huawei';
    case 'lg':
      return 'LG';
    case 'asus':
      return 'Asus';
    case 'fairphone':
      return 'Fairphone';
    case 'nothing':
      return 'Nothing';
    case 'realme':
      return 'Realme';
    case 'oppo':
      return 'Oppo';
    case 'vivo':
      return 'Vivo';
    case 'zte':
      return 'ZTE';
    case 'razer':
      return 'Razer';
    case 'essential':
      return 'Essential';
    case 'oukitel':
      return 'Oukitel';
    case 'shift':
      return 'SHIFT';
    case 'bq':
      return 'BQ';
    case 'wileyfox':
      return 'Wileyfox';
    case 'yandex':
      return 'Yandex';
    case 'yu':
      return 'YU';
    case 'leeco':
      return 'LeEco';
    case 'le':
      return 'LeEco';
    case 'wingtech':
      return 'Wingtech';
    case 'f(x)tec':
    case 'fxtec':
      return 'F(x)tec';
    default:
      return v;
  }
}

/// Per-ROM device-coverage policy. Returns true if [d] should be listed
/// as supported by the ROM identified by [romId].
typedef _Policy = bool Function(_Device d);

_Policy _policyFor(String romId) {
  switch (romId) {
    case 'lineage':
      // Officially everything in the wiki, modern branches only.
      return (_Device d) => d.type == 'phone' && _branchAtLeast(d, 20);
    case 'crdroid':
      // crDroid's official list, ~150 devices, mostly Xiaomi/OnePlus/Pixel.
      return (_Device d) =>
          d.type == 'phone' &&
          _branchAtLeast(d, 21) &&
          const <String>{
            'Xiaomi',
            'OnePlus',
            'Google',
            'Asus',
            'Realme',
            'Nothing',
            'Motorola',
            'Samsung',
          }.contains(d.vendor);
    case 'pixelexperience':
      // Mostly Pixels + Snapdragon Xiaomi/POCO + Treble GSIs.
      return (_Device d) =>
          d.type == 'phone' &&
          _branchAtLeast(d, 21) &&
          const <String>{'Google', 'Xiaomi', 'OnePlus', 'Asus'}
              .contains(d.vendor);
    case 'arrowos':
      return (_Device d) =>
          d.type == 'phone' &&
          _branchAtLeast(d, 20) &&
          const <String>{
            'Google',
            'Xiaomi',
            'OnePlus',
            'Asus',
            'Realme',
            'Motorola',
          }.contains(d.vendor);
    case 'evolutionx':
      return (_Device d) =>
          d.type == 'phone' &&
          _branchAtLeast(d, 21) &&
          const <String>{
            'Google',
            'Xiaomi',
            'OnePlus',
            'Asus',
            'Motorola',
            'Samsung',
          }.contains(d.vendor);
    case 'paranoidandroid':
      return (_Device d) =>
          d.type == 'phone' &&
          _branchAtLeast(d, 21) &&
          const <String>{
            'Google',
            'Xiaomi',
            'OnePlus',
            'Nothing',
          }.contains(d.vendor);
    case 'havoc':
      return (_Device d) =>
          d.type == 'phone' &&
          _yearAtLeast(d, 2016) &&
          const <String>{
            'Google',
            'Xiaomi',
            'OnePlus',
            'Asus',
            'Motorola',
            'Samsung',
            'Sony',
          }.contains(d.vendor);
    case 'dotos':
      return (_Device d) =>
          d.type == 'phone' &&
          _yearAtLeast(d, 2017) &&
          const <String>{'Google', 'Xiaomi', 'OnePlus', 'Motorola'}
              .contains(d.vendor);
    case 'bliss':
      return (_Device d) =>
          d.type == 'phone' &&
          _branchAtLeast(d, 20) &&
          const <String>{
            'Google',
            'Xiaomi',
            'OnePlus',
            'Asus',
            'Motorola',
            'Nothing',
          }.contains(d.vendor);
    case 'potatoaosp':
      return (_Device d) =>
          d.type == 'phone' &&
          _yearAtLeast(d, 2018) &&
          const <String>{'Google', 'Xiaomi', 'OnePlus', 'Asus'}
              .contains(d.vendor);
    case 'risingos':
      return (_Device d) =>
          d.type == 'phone' &&
          _branchAtLeast(d, 21) &&
          const <String>{
            'Google',
            'Xiaomi',
            'OnePlus',
            'Asus',
            'Nothing',
            'Realme',
            'Motorola',
          }.contains(d.vendor);
    case 'voltage':
      return (_Device d) =>
          d.type == 'phone' &&
          _branchAtLeast(d, 21) &&
          const <String>{'Google', 'Xiaomi', 'OnePlus', 'Realme', 'Nothing'}
              .contains(d.vendor);
    case 'projectelixir':
      return (_Device d) =>
          d.type == 'phone' &&
          _branchAtLeast(d, 21) &&
          const <String>{
            'Google',
            'Xiaomi',
            'OnePlus',
            'Asus',
            'Realme',
            'Nothing',
          }.contains(d.vendor);
    case 'grapheneos':
      // Pixel-only by policy.
      return (_Device d) =>
          d.type == 'phone' && d.vendor == 'Google' && _yearAtLeast(d, 2020);
    case 'calyxos':
      // Pixel-only with a handful of supported Fairphone / Xiaomi targets.
      return (_Device d) =>
          d.type == 'phone' &&
          _yearAtLeast(d, 2019) &&
          const <String>{'Google', 'Fairphone'}.contains(d.vendor);
    case 'eos':
      // /e/OS, wide LineageOS-derived device coverage.
      return (_Device d) => d.type == 'phone' && _branchAtLeast(d, 18);
    case 'divestos':
      // Security-hardened LineageOS fork; ships builds for older devices too.
      return (_Device d) => d.type == 'phone' && _branchAtLeast(d, 17);
    case 'derpfest':
      return (_Device d) =>
          d.type == 'phone' &&
          _branchAtLeast(d, 21) &&
          const <String>{
            'Google',
            'Xiaomi',
            'OnePlus',
            'Asus',
            'Realme',
            'Nothing',
            'Motorola',
          }.contains(d.vendor);

    // Recoveries follow approximate official device lists.
    case 'twrp':
      return (_Device d) => d.type == 'phone' && _yearAtLeast(d, 2014);
    case 'orangefox':
      return (_Device d) =>
          d.type == 'phone' &&
          _yearAtLeast(d, 2017) &&
          const <String>{
            'Xiaomi',
            'OnePlus',
            'Realme',
            'Motorola',
            'Asus',
            'Nothing',
          }.contains(d.vendor);
    case 'redwolf':
      return (_Device d) =>
          d.type == 'phone' &&
          _yearAtLeast(d, 2016) &&
          const <String>{'Xiaomi', 'OnePlus'}.contains(d.vendor);
    case 'pitchblack':
      return (_Device d) =>
          d.type == 'phone' &&
          _yearAtLeast(d, 2016) &&
          const <String>{
            'Xiaomi',
            'OnePlus',
            'Samsung',
            'Motorola',
            'Asus',
          }.contains(d.vendor);
    case 'shrp':
      return (_Device d) =>
          d.type == 'phone' &&
          _yearAtLeast(d, 2017) &&
          const <String>{'Xiaomi', 'OnePlus', 'Realme'}.contains(d.vendor);
    default:
      return (_Device _) => false;
  }
}

bool _branchAtLeast(_Device d, int major) {
  final List<String> parts = d.currentBranch.split('.');
  if (parts.isEmpty) return false;
  final int? n = int.tryParse(parts.first);
  return n != null && n >= major;
}

bool _yearAtLeast(_Device d, int year) =>
    d.releaseYear != null && d.releaseYear! >= year;

List<Map<String, dynamic>> _toDeviceList(Iterable<_Device> devices) {
  return devices
      .map(
        (_Device d) => <String, dynamic>{
          'brand': d.vendor,
          'model': d.model,
          'codename': d.codename,
        },
      )
      .toList();
}

List<Map<String, dynamic>> _buildRoms(List<_Device> all) {
  final List<_RomSpec> specs = <_RomSpec>[
    _RomSpec(
      id: 'lineage',
      name: 'LineageOS',
      headerAsset: 'images/lineageos.png',
      shortTagline:
          'The largest community-built Android distribution, descended from CyanogenMod.',
      description: <String>[
        'LineageOS is a free and open-source operating system based on Android, with official builds for over 200 devices and a strong focus on customization and longevity.',
        'It is maintained by hundreds of volunteer developers and is widely considered the reference custom ROM for any modern Android device.',
      ],
      features: <String>[
        'Officially supports a huge range of devices, including extended security updates.',
        'Built-in PrivacyGuard for per-app permission controls.',
        'Updater app delivers signed OTA updates straight from the official servers.',
        'Optional MicroG, F-Droid, or Google Apps via separate installers.',
      ],
      screenshots: <String>[
        'https://lineageos.org/images/2024-09-01/featured.jpg',
        'https://i.imgur.com/8tXFw5w.png',
        'https://i.imgur.com/3GxF3jK.png',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://download.lineageos.org/',
      forumUrl: 'https://forum.xda-developers.com/f/lineageos-questions-answers.5614/',
    ),
    _RomSpec(
      id: 'crdroid',
      name: 'crDroid',
      headerAsset: 'images/crdroid_hori.png',
      shortTagline:
          'LineageOS-based ROM packed with extra customisation knobs.',
      description: <String>[
        'crDroid extends LineageOS with a deep customisation layer covering the lockscreen, status bar, navigation gestures, and theming engine.',
        'Builds track upstream Android security patches monthly and ship for ~150 devices.',
      ],
      features: <String>[
        'Status-bar, lockscreen, gesture and theming customisation.',
        'Built-in OTA updater.',
        'Monthly security patches.',
        'GApps and vanilla variants for most devices.',
      ],
      screenshots: <String>[
        'https://crdroid.net/img/cards/customization.png',
        'https://crdroid.net/img/cards/themes.png',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://crdroid.net/',
    ),
    _RomSpec(
      id: 'pixelexperience',
      name: 'Pixel Experience',
      headerAsset: 'images/pixelexperience.png',
      shortTagline:
          'AOSP-based ROM that mirrors the Google Pixel software experience.',
      description: <String>[
        'Pixel Experience ships the Pixel launcher, wallpapers, icons, fonts, boot animation, and Google apps so your device behaves like a Pixel.',
        'Built straight from AOSP and updated alongside Google security patches.',
      ],
      features: <String>[
        'Pixel-style UI, animations, and wallpapers out of the box.',
        'Google apps and Pixel exclusive features pre-installed.',
        'Monthly security patches in sync with Google Pixel.',
        'Plus variant adds extra customisation if you want it.',
      ],
      screenshots: <String>[
        'https://download.pixelexperience.org/img/screenshots/13.png',
        'https://download.pixelexperience.org/img/screenshots/14.png',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://download.pixelexperience.org/',
      forumUrl: 'https://forum.xda-developers.com/c/pixel-experience.10089/',
    ),
    _RomSpec(
      id: 'arrowos',
      name: 'ArrowOS',
      headerAsset: 'images/arrowos.png',
      shortTagline:
          'Minimal AOSP-based ROM focused on smoothness and zero bloat.',
      description: <String>[
        'ArrowOS sticks close to stock Android, dropping in only the most-requested customisations to keep things fast and battery friendly.',
        'Ideal if you want something stable, near-vanilla, and easy to live with.',
      ],
      features: <String>[
        'Near-stock AOSP with curated quality-of-life additions.',
        'Focus on stability and battery life over feature creep.',
        'Monthly security patches.',
      ],
      screenshots: <String>[
        'https://arrowos.net/assets/img/screenshots/home.jpg',
        'https://arrowos.net/assets/img/screenshots/settings.jpg',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://arrowos.net/',
    ),
    _RomSpec(
      id: 'evolutionx',
      name: 'Evolution X',
      headerAsset: 'images/evolutionx.png',
      shortTagline:
          'Pixel-style ROM that adds extra customisation on top of AOSP.',
      description: <String>[
        'Evolution X combines a Pixel-like baseline (launcher, wallpapers, boot animation) with a wide customisation menu and Google apps.',
      ],
      features: <String>[
        'Pixel UI baseline with optional GApps included.',
        'Status-bar, lockscreen, and navigation customisation.',
        'Monthly security patches.',
      ],
      screenshots: <String>[
        'https://evolution-x.org/assets/img/screenshots/lockscreen.jpg',
        'https://evolution-x.org/assets/img/screenshots/settings.jpg',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://evolution-x.org/',
    ),
    _RomSpec(
      id: 'paranoidandroid',
      name: 'Paranoid Android',
      headerAsset: 'images/paranoidandroid.png',
      shortTagline:
          'Refined AOSP ROM known for tasteful UI changes and Pixel polish.',
      description: <String>[
        'Paranoid Android is one of the oldest custom ROM projects. It focuses on small, considered UX touches like pop-up notifications and an enhanced ambient display.',
      ],
      features: <String>[
        'Pop-up notifications and refined ambient display.',
        'Pixel-like baseline with subtle customisation.',
        'Active community, slow but careful release cadence.',
      ],
      screenshots: <String>[
        'https://paranoidandroid.co/images/topaz/topaz_home.png',
        'https://paranoidandroid.co/images/topaz/topaz_settings.png',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://paranoidandroid.co/',
      forumUrl: 'https://forum.xda-developers.com/c/paranoid-android-aospa.10316/',
    ),
    _RomSpec(
      id: 'havoc',
      name: 'Havoc-OS',
      headerAsset: 'images/havoc.png',
      shortTagline:
          'LineageOS-derived ROM with a rich feature set and Substratum theming.',
      description: <String>[
        'Havoc-OS is built on top of LineageOS device trees and AOSP, bundling a large set of customisation toggles and built-in Substratum theming.',
        'Active development has slowed in recent years; check the official site for current device coverage.',
      ],
      features: <String>[
        'Substratum theming engine built in.',
        'Status-bar, lockscreen, and navigation customisation.',
        'Optional GApps build per device.',
      ],
      screenshots: <String>[
        'https://havoc-os.com/assets/img/screenshots/home.png',
        'https://havoc-os.com/assets/img/screenshots/settings.png',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://havoc-os.com/',
    ),
    _RomSpec(
      id: 'dotos',
      name: 'DotOS',
      headerAsset: 'images/dotos.png',
      shortTagline:
          'Stock-like AOSP ROM with a tasteful design language of its own.',
      description: <String>[
        'DotOS focuses on visual polish and small daily-driver improvements rather than maximum customisation.',
      ],
      features: <String>[
        'Curated design language across the system UI.',
        'Optional GApps variants.',
        'Smooth animations and lean install.',
      ],
      screenshots: <String>[
        'https://droidontime.com/wp-content/uploads/2021/01/dotOS.png',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://www.droidontime.com/',
    ),
    _RomSpec(
      id: 'bliss',
      name: 'Bliss ROMs',
      headerAsset: 'images/blissrom.png',
      shortTagline:
          'LineageOS-based ROM with builds for phones, tablets, and PCs.',
      description: <String>[
        'Bliss ROMs ships LineageOS-based builds for Android handsets and a separate Bliss OS x86 build for PCs and tablets, reusing much of the same UX code.',
      ],
      features: <String>[
        'Extensive customisation menu.',
        'Tablet and large-screen tweaks.',
        'Sister Bliss OS x86 builds for PCs.',
      ],
      screenshots: <String>[
        'https://blissroms.org/images/bliss-home.jpg',
        'https://blissroms.org/images/bliss-settings.jpg',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://blissroms.org/',
    ),
    _RomSpec(
      id: 'potatoaosp',
      name: 'POSP',
      headerAsset: 'images/potatoaosp.png',
      shortTagline:
          'AOSP-based "Potato Open Sauce Project" with a light customisation set.',
      description: <String>[
        'POSP ships a clean AOSP base with a curated set of features and a focus on snappy, low-overhead daily use.',
      ],
      features: <String>[
        'Lean AOSP base.',
        'Pixel launcher and tasteful UI tweaks.',
        'Active maintainer community.',
      ],
      screenshots: <String>[
        'https://posp.co/images/screenshots/home.png',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://posp.co/',
    ),
    _RomSpec(
      id: 'risingos',
      name: 'RisingOS',
      headerAsset: 'images/risingos.png',
      shortTagline:
          'Feature-rich Android 14/15 ROM with a strong customisation suite.',
      description: <String>[
        'RisingOS is a newer-generation custom ROM that ships a deep customisation menu, AI integrations, and polished animations on top of AOSP 14 and 15.',
      ],
      features: <String>[
        'Rich customisation: lockscreen, status-bar, gestures, themes.',
        'Pixel-style UI baseline.',
        'Frequent monthly releases.',
      ],
      screenshots: <String>[
        'https://risingos.org/img/screens/home.png',
        'https://risingos.org/img/screens/customization.png',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://risingos.org/',
    ),
    _RomSpec(
      id: 'voltage',
      name: 'Voltage OS',
      headerAsset: 'images/voltage.png',
      shortTagline:
          'Vanilla-leaning AOSP ROM aimed at battery life and snappiness.',
      description: <String>[
        'Voltage OS keeps very close to AOSP and adds only the minimum set of features to give a clean, fast daily driver.',
      ],
      features: <String>[
        'Lean AOSP base.',
        'Battery-life-first tuning.',
        'Optional GApps.',
      ],
      screenshots: <String>[
        'https://voltageos.com/images/home.png',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://voltageos.com/',
    ),
    _RomSpec(
      id: 'projectelixir',
      name: 'Project Elixir',
      headerAsset: 'images/projectelixir.png',
      shortTagline:
          'Modern AOSP ROM with a polished Pixel-inspired UI and rich customisation.',
      description: <String>[
        'Project Elixir is a fast-moving AOSP-based ROM that ships Pixel launcher and animations with an extensive customisation suite.',
      ],
      features: <String>[
        'Pixel UI baseline and GApps included.',
        'Deep customisation menu.',
        'Active monthly releases.',
      ],
      screenshots: <String>[
        'https://projectelixiros.com/images/lockscreen.png',
        'https://projectelixiros.com/images/customization.png',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://projectelixiros.com/',
    ),
    _RomSpec(
      id: 'grapheneos',
      name: 'GrapheneOS',
      headerAsset: 'images/grapheneos.png',
      shortTagline:
          'Privacy- and security-hardened AOSP ROM for Google Pixel devices.',
      description: <String>[
        'GrapheneOS is a non-profit, open-source mobile OS focused on privacy and security improvements over stock Android.',
        'Builds are AOSP-based and target Google Pixel phones (3a and newer) where the hardware can be re-locked after install.',
      ],
      features: <String>[
        'Hardened malloc, MTE, fortified kernel, exec-only memory.',
        'Per-app Network, Sensors, Storage and Contacts permissions.',
        'Sandboxed Google Play layer for app compatibility.',
        'Verified boot with user-installable keys.',
      ],
      screenshots: <String>[
        'https://grapheneos.org/screenshots/setup-wizard.png',
        'https://grapheneos.org/screenshots/sandboxed-google-play.png',
      ],
      downloadLabel: 'Install / web installer',
      downloadUrl: 'https://grapheneos.org/install/',
      forumUrl: 'https://discuss.grapheneos.org/',
    ),
    _RomSpec(
      id: 'calyxos',
      name: 'CalyxOS',
      headerAsset: 'images/calyxos.png',
      shortTagline:
          'Privacy-focused AOSP ROM with microG and verified boot, by The Calyx Institute.',
      description: <String>[
        'CalyxOS is built by The Calyx Institute as a privacy and security focused Android distribution targeting Google Pixel devices and a small set of Fairphone hardware.',
        'It ships with microG pre-configured for de-Googled push, and includes Datura firewall, Signal, and the Aurora Store out of the box.',
      ],
      features: <String>[
        'microG bundled and ready, no Google services required.',
        'Verified boot supported on official Pixel targets.',
        'Datura firewall and per-app network controls.',
        'F-Droid, Aurora Store and Signal pre-installed.',
      ],
      screenshots: <String>[
        'https://calyxos.org/img/screenshots/home.png',
        'https://calyxos.org/img/screenshots/datura.png',
      ],
      downloadLabel: 'Install instructions',
      downloadUrl: 'https://calyxos.org/install/',
      forumUrl: 'https://discuss.calyxinstitute.org/',
    ),
    _RomSpec(
      id: 'eos',
      name: '/e/OS',
      headerAsset: 'images/eos.png',
      shortTagline:
          'LineageOS-based, de-Googled OS by the e Foundation (Murena).',
      description: <String>[
        '/e/OS is a privacy-respecting fork of LineageOS that ships microG instead of Google services, a custom launcher, and the e Foundation cloud ecosystem.',
        'Builds are available for a wide range of devices, and Murena also sells pre-installed phones (Fairphone, Pixel, Murena ONE).',
      ],
      features: <String>[
        'microG-based, fully de-Googled experience.',
        'Bundled App Lounge with anonymous logins and privacy scores.',
        'Optional Murena cloud (Mail, Drive, Calendar).',
        'Official builds for 200+ devices via the e installer.',
      ],
      screenshots: <String>[
        'https://murena.com/wp-content/uploads/2023/01/e-launcher.png',
        'https://murena.com/wp-content/uploads/2023/01/applounge.png',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://doc.e.foundation/devices',
      forumUrl: 'https://community.e.foundation/',
    ),
    _RomSpec(
      id: 'divestos',
      name: 'DivestOS',
      headerAsset: 'images/divestos.png',
      shortTagline:
          'Security-hardened LineageOS soft-fork with extended device support.',
      description: <String>[
        'DivestOS is a soft-fork of LineageOS focused on increased privacy and security, including monthly maintenance for many older devices that upstream has dropped.',
        'Builds ship with F-Droid, Mulch (a hardened Chromium), and additional hardening backported from GrapheneOS.',
      ],
      features: <String>[
        'Security patches and hardening backports.',
        'Extended life for legacy devices Lineage no longer ships.',
        'F-Droid and Mulch browser pre-installed.',
        'Per-network MAC randomisation and other privacy tweaks.',
      ],
      screenshots: <String>[
        'https://divestos.org/images/screenshot-home.png',
        'https://divestos.org/images/screenshot-settings.png',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://divestos.org/pages/devices',
    ),
    _RomSpec(
      id: 'derpfest',
      name: 'DerpFest',
      headerAsset: 'images/derpfest.png',
      shortTagline:
          'Feature-rich LineageOS-based ROM built by a community of maintainers.',
      description: <String>[
        'DerpFest is a community-driven ROM that layers a deep customisation suite on top of LineageOS, with active maintainers across a broad device list.',
        'Builds are produced for current Android branches and emphasise daily-driver stability.',
      ],
      features: <String>[
        'LineageOS base with an extensive customisation menu.',
        'Pixel-style UI accents.',
        'Per-device maintainer model, frequent updates.',
        'GApps and vanilla variants.',
      ],
      screenshots: <String>[
        'https://projectderp.in/images/screen1.png',
        'https://projectderp.in/images/screen2.png',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://projectderp.in/',
    ),
  ];

  return specs.map((_RomSpec s) {
    final _Policy policy = _policyFor(s.id);
    final List<_Device> matched = all.where(policy).toList();
    return <String, dynamic>{
      'id': s.id,
      'name': s.name,
      'headerAsset': s.headerAsset,
      'shortTagline': s.shortTagline,
      'description': s.description,
      'features': s.features,
      'screenshots': s.screenshots,
      'devices': _toDeviceList(matched),
      'downloadLabel': s.downloadLabel,
      'downloadUrl': s.downloadUrl,
      'forumUrl': s.forumUrl ?? _xdaSearchUrl(s.name),
    };
  }).toList();
}

List<Map<String, dynamic>> _buildRecoveries(List<_Device> all) {
  final List<_RomSpec> specs = <_RomSpec>[
    _RomSpec(
      id: 'twrp',
      name: 'TWRP',
      headerAsset: 'images/recovery_twrp.png',
      shortTagline:
          'The classic Team Win Recovery Project. Touch-based and supported on hundreds of devices.',
      description: <String>[
        'TWRP is the most widely used custom recovery for Android. It exposes a touch-based interface for flashing ZIPs, taking nandroid backups, mounting partitions, and using ADB sideload.',
      ],
      features: <String>[
        'Touch-based UI, themable.',
        'Full nandroid backups and restore.',
        'ADB sideload, terminal, and file manager.',
        'Officially supported on hundreds of devices.',
      ],
      screenshots: <String>[
        // Wikimedia Commons hosts the only stable, hot-linkable TWRP screenshot;
        // twrp.me/assets/img/twrp_3_4_main.png used to work but now 404s.
        'https://upload.wikimedia.org/wikipedia/commons/a/a3/TWRP_3.7.0_menu_screenshot.png',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://twrp.me/Devices/',
      forumUrl: 'https://forum.xda-developers.com/f/orig-development.5410/',
    ),
    _RomSpec(
      id: 'orangefox',
      name: 'OrangeFox Recovery',
      headerAsset: 'images/recovery_orangefox.png',
      shortTagline:
          'TWRP fork focused on MIUI/Treble decryption and a modern UI.',
      description: <String>[
        'OrangeFox is a fork of TWRP that ships first-class support for MIUI and Treble devices, a refreshed UI, and built-in tools like a Magisk installer.',
      ],
      features: <String>[
        'Improved decryption support on Xiaomi/MIUI devices.',
        'Modern themable UI.',
        'Built-in Magisk installer, file manager, terminal.',
      ],
      // No reliably hot-linkable screenshot; the old URL 404s. Leave empty so
      // the detail page omits the carousel instead of showing a broken image.
      screenshots: <String>[],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://orangefox.download/',
    ),
    _RomSpec(
      id: 'redwolf',
      name: 'RedWolf Recovery',
      headerAsset: 'images/recovery_redwolf.png',
      shortTagline: 'TWRP-based recovery with extra MIUI-friendly features.',
      description: <String>[
        'RedWolf Recovery focuses on Xiaomi and OnePlus devices, adding MIUI-style features on top of a TWRP base.',
      ],
      features: <String>[
        'TWRP-derived feature set.',
        'MIUI-friendly partition handling.',
        'Built-in repair tools.',
      ],
      // Old imgur upload was removed; no stable replacement found.
      screenshots: <String>[],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://forum.xda-developers.com/c/redwolf-recovery.10018/',
    ),
    _RomSpec(
      id: 'pitchblack',
      name: 'PitchBlack Recovery',
      headerAsset: 'images/recovery_pitchblack.png',
      shortTagline:
          'TWRP-based recovery built around a dark theme and quality-of-life extras.',
      description: <String>[
        'PitchBlack Recovery Project is a TWRP fork that ships a dark theme out of the box plus quick boot options, MIUI-friendly partition handling, and other QoL features.',
      ],
      features: <String>[
        'TWRP base with a curated dark theme.',
        'Quick boot menu (recovery / fastboot / system).',
        'MIUI-friendly partition handling.',
      ],
      // Old imgur upload was removed; no stable replacement found.
      screenshots: <String>[],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://pitchblack.tech/',
    ),
    _RomSpec(
      id: 'shrp',
      name: 'SHRP',
      headerAsset: 'images/recovery_shrp.png',
      shortTagline:
          'SkyHawk Recovery Project: a TWRP fork with a polished UI and stock-ROM backup helpers.',
      description: <String>[
        'SHRP (formerly SkyHawk Recovery) is a TWRP fork that targets MIUI and OxygenOS devices with a polished UI and built-in stock-rom backup helpers.',
      ],
      features: <String>[
        'Stock ROM backup helpers.',
        'Polished TWRP-derived UI.',
        'Builds for popular Xiaomi/OnePlus/Realme models.',
      ],
      screenshots: <String>[
        // Project banner from the current SHRP site.
        'https://shrp.dev/images/shrp.png',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://shrp.vercel.app/',
    ),
  ];

  return specs.map((_RomSpec s) {
    final _Policy policy = _policyFor(s.id);
    final List<_Device> matched = all.where(policy).toList();
    return <String, dynamic>{
      'id': s.id,
      'name': s.name,
      'headerAsset': s.headerAsset,
      'shortTagline': s.shortTagline,
      'description': s.description,
      'features': s.features,
      'screenshots': s.screenshots,
      'devices': _toDeviceList(matched),
      'downloadLabel': s.downloadLabel,
      'downloadUrl': s.downloadUrl,
      'forumUrl': s.forumUrl ?? _xdaSearchUrl(s.name),
    };
  }).toList();
}

List<Map<String, dynamic>> _buildDevices(List<String> vendors) {
  // Per-vendor hero photo. For vendors without a tailored asset we fall back
  // to the generic branding placeholder, but the runtime catalog should
  // ensure every shipped vendor has an entry here.
  const Map<String, String> assetMap = <String, String>{
    '10.or': 'images/device_10or.png',
    'ARK': 'images/device_ark.png',
    'Asus': 'images/device_asus.png',
    'BQ': 'images/device_bq.png',
    'Banana Pi': 'images/device_banana_pi.png',
    'Dynalink': 'images/device_dynalink.png',
    'Essential': 'images/device_essential.png',
    'F(x)tec': 'images/device_fxtec.png',
    'Fairphone': 'images/device_fairphone.png',
    'Google': 'images/google.png',
    'HTC': 'images/device_htc.png',
    'HardKernel': 'images/device_hardkernel.png',
    'Huawei': 'images/huawei.png',
    'LG': 'images/lg.png',
    'LeEco': 'images/device_leeco.png',
    'Lenovo': 'images/lenovo.png',
    'Motorola': 'images/motorola.png',
    'NVIDIA': 'images/device_nvidia.png',
    'Nextbit': 'images/device_nextbit.png',
    'Nintendo': 'images/device_nintendo.png',
    'Nokia': 'images/nokia.png',
    'Nothing': 'images/device_nothing.png',
    'Nubia': 'images/device_nubia.png',
    'OSOM': 'images/device_osom.png',
    'OnePlus': 'images/oneplus.png',
    'Oppo': 'images/device_oppo.png',
    'Radxa': 'images/device_radxa.png',
    'Razer': 'images/device_razer.png',
    'Realme': 'images/device_realme.png',
    'SHIFT': 'images/device_shift.png',
    'Samsung': 'images/samsung.png',
    'Smartisan': 'images/device_smartisan.png',
    'Solana': 'images/device_solana.png',
    'Sony': 'images/sony.png',
    'Vsmart': 'images/device_vsmart.png',
    'Walmart': 'images/device_walmart.png',
    'Wileyfox': 'images/device_wileyfox.png',
    'Wingtech': 'images/device_wingtech.png',
    'Xiaomi': 'images/xiaomi.png',
    'YU': 'images/device_yu.png',
    'Yandex': 'images/device_yandex.png',
    'ZTE': 'images/device_zte.png',
    'ZUK': 'images/device_zuk.png',
  };
  const String fallback = 'images/branding.png';
  return vendors
      .map(
        (String v) => <String, dynamic>{
          'name': v,
          'imageAsset': assetMap[v] ?? fallback,
        },
      )
      .toList();
}

class _Device {
  _Device({
    required this.vendor,
    required this.model,
    required this.codename,
    required this.type,
    required this.currentBranch,
    required this.releaseYear,
  });

  final String vendor;
  final String model;
  final String codename;
  final String type;
  final String currentBranch;
  final int? releaseYear;
}

class _RomSpec {
  _RomSpec({
    required this.id,
    required this.name,
    required this.headerAsset,
    required this.shortTagline,
    required this.description,
    required this.features,
    required this.screenshots,
    required this.downloadLabel,
    required this.downloadUrl,
    this.forumUrl,
  });

  final String id;
  final String name;
  final String headerAsset;
  final String shortTagline;
  final List<String> description;
  final List<String> features;
  final List<String> screenshots;
  final String downloadLabel;
  final String downloadUrl;

  /// Optional curated XDA Developers thread / category URL. When null, the
  /// build falls back to [_xdaSearchUrl] so every entry still surfaces a
  /// working "Discuss on XDA" button.
  final String? forumUrl;
}

/// Deterministic XDA search URL for [name]. Used as a fallback whenever a
/// project does not have a curated forum link, so the in-app Discussion
/// button is never broken.
String _xdaSearchUrl(String name) {
  final String q = Uri.encodeQueryComponent(name);
  return 'https://forum.xda-developers.com/search/?q=$q'
      '&o=date&c[content]=thread';
}
