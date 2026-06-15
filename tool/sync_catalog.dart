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

// PixelOS publishes its authoritative supported-devices list as a JSON
// blob on the `sixteen` branch of PixelOS-AOSP/official_devices.
const String _pixelosDevicesUrl =
    'https://raw.githubusercontent.com/PixelOS-AOSP/official_devices/sixteen/API/devices.json';
const String _pixelosCachePath = 'tool/.cache/pixelos/devices.json';

// Project Infinity X stores its authoritative device roster as one JSON
// file per codename under `devices/` on its official_devices repo. The site
// downloads page merges the `16` (current) and `master` branches, so a few
// devices that only live on `master` would be missed if we read `16` alone.
// We grab both branch tarballs once and union the device files by codename
// (16 wins on conflicts), mirroring the website's own list.
const Map<String, String> _infinityxBranchTarUrls = <String, String>{
  '16':
      'https://github.com/ProjectInfinity-X/official_devices/archive/refs/heads/16.tar.gz',
  'master':
      'https://github.com/ProjectInfinity-X/official_devices/archive/refs/heads/master.tar.gz',
};
const String _infinityxCacheDir = 'tool/.cache/infinityx';

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

  final List<_Device> pixelosDevices = await _loadPixelosDevices(refresh: refresh);
  stdout.writeln(
    '[sync] loaded ${pixelosDevices.length} PixelOS official devices',
  );

  final List<_Device> infinityxDevices =
      await _loadInfinityxDevices(refresh: refresh);
  stdout.writeln(
    '[sync] loaded ${infinityxDevices.length} Project Infinity X devices',
  );

  // Manufacturers shown in the Devices section must cover every vendor
  // referenced by any ROM, including PixelOS-only ones (e.g. 10or) that
  // never appear in the LineageOS wiki.
  final Set<String> allVendors = <String>{
    ...vendors,
    ...pixelosDevices.map((_Device d) => d.vendor),
    ...infinityxDevices.map((_Device d) => d.vendor),
  };
  final List<String> mergedVendors = allVendors.toList()..sort();

  // Build the JSON.
  final Map<String, dynamic> root = <String, dynamic>{
    '_generated': 'tool/sync_catalog.dart',
    '_generatedAt': DateTime.now().toUtc().toIso8601String(),
    'roms': _buildRoms(
      devices,
      pixelosDevices: pixelosDevices,
      infinityxDevices: infinityxDevices,
    ),
    'recoveries': _buildRecoveries(devices),
    'roots': _buildRoots(),
    'devices': _buildDevices(mergedVendors),
  };

  const JsonEncoder pretty = JsonEncoder.withIndent('  ');
  File(_catalogPath).writeAsStringSync('${pretty.convert(root)}\n');
  stdout.writeln('[sync] wrote $_catalogPath');
}

Future<void> _downloadWiki() async {
  Directory(_cacheDir).createSync(recursive: true);
  final String tarPath = '$_cacheDir/wiki.tar.gz';
  // Note: the wiki tarball is ~60 MB and GitHub does not always send a
  // Content-Length, so we cannot rely on a fixed --max-time. Instead, use
  // a short --connect-timeout, retry transient failures, and let the
  // transfer take as long as the connection needs.
  final ProcessResult curl = await Process.run('curl', <String>[
    '-sSL',
    '--connect-timeout',
    '30',
    '--retry',
    '5',
    '--retry-delay',
    '3',
    '--retry-all-errors',
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

/// Loads the authoritative PixelOS device list from
/// `PixelOS-AOSP/official_devices` (sixteen branch).
///
/// Fetches the JSON over the network and caches it at
/// [_pixelosCachePath]. If [refresh] is false and a cache file exists, we
/// use it. If the fetch fails and a cache exists, we fall back to the
/// cache; otherwise we rethrow.
Future<List<_Device>> _loadPixelosDevices({required bool refresh}) async {
  final File cache = File(_pixelosCachePath);
  String? raw;
  if (!refresh && cache.existsSync()) {
    raw = cache.readAsStringSync();
  } else {
    cache.parent.createSync(recursive: true);
    final ProcessResult curl = await Process.run('curl', <String>[
      '-sSL',
      '--connect-timeout',
      '15',
      '--retry',
      '3',
      '--retry-delay',
      '2',
      '--retry-all-errors',
      _pixelosDevicesUrl,
    ]);
    if (curl.exitCode == 0 && (curl.stdout as String).trim().isNotEmpty) {
      raw = curl.stdout as String;
      cache.writeAsStringSync(raw);
    } else if (cache.existsSync()) {
      stderr.writeln(
        '[sync] pixelos fetch failed, using cached ${cache.path}',
      );
      raw = cache.readAsStringSync();
    } else {
      throw StateError('pixelos fetch failed: ${curl.stderr}');
    }
  }

  final dynamic decoded = jsonDecode(raw);
  final List<dynamic> entries = (decoded as Map<String, dynamic>)['devices']
      as List<dynamic>;
  final List<_Device> out = <_Device>[];
  for (final dynamic e in entries) {
    final Map<String, dynamic> m = e as Map<String, dynamic>;
    final String codename = (m['codename'] as String?)?.trim() ?? '';
    final String vendor = (m['vendor'] as String?)?.trim() ?? '';
    final String model = (m['model'] as String?)?.trim() ?? '';
    if (codename.isEmpty || vendor.isEmpty || model.isEmpty) continue;
    out.add(
      _Device(
        vendor: _normalizeVendor(vendor),
        model: model,
        codename: codename,
        type: 'phone',
        currentBranch: '',
        releaseYear: null,
      ),
    );
  }
  out.sort((_Device a, _Device b) {
    final int v = a.vendor.compareTo(b.vendor);
    if (v != 0) return v;
    final int mm = a.model.toLowerCase().compareTo(b.model.toLowerCase());
    if (mm != 0) return mm;
    return a.codename.compareTo(b.codename);
  });
  return out;
}

/// Loads the authoritative Project Infinity X device list from
/// Loads the authoritative Project Infinity X device list from
/// `ProjectInfinity-X/official_devices`, where every supported device is a
/// `devices/<codename>.json` file carrying the model name and maintainer.
///
/// The site downloads page merges the `16` and `master` branches, so we do
/// the same: download both branch tarballs once into [_infinityxCacheDir]
/// (one subfolder per branch) and union the parsed devices by codename, with
/// the `16` branch winning on conflicts. If [refresh] is false and a branch
/// cache already holds device files, we reuse it without hitting the network.
Future<List<_Device>> _loadInfinityxDevices({required bool refresh}) async {
  // Union by codename; insert 16 first so it wins over master on conflicts.
  final Map<String, _Device> byCodename = <String, _Device>{};
  for (final MapEntry<String, String> branch
      in _infinityxBranchTarUrls.entries) {
    final Directory devicesDir = Directory(
      '$_infinityxCacheDir/${branch.key}/devices',
    );
    await _ensureInfinityxBranch(
      branch: branch.key,
      tarUrl: branch.value,
      devicesDir: devicesDir,
      refresh: refresh,
    );
    if (!devicesDir.existsSync()) continue;
    for (final FileSystemEntity e in devicesDir.listSync()) {
      if (e is! File || !e.path.endsWith('.json')) continue;
      try {
        final Map<String, dynamic> m =
            jsonDecode(e.readAsStringSync()) as Map<String, dynamic>;
        final String model = (m['devicemodel'] as String?)?.trim() ?? '';
        // The canonical, single codename is the file name; the JSON
        // `codename` field can list variants like "ginkgo/willow".
        final String codename =
            e.uri.pathSegments.last.replaceAll('.json', '').trim();
        if (model.isEmpty || codename.isEmpty) continue;
        byCodename.putIfAbsent(
          codename,
          () => _Device(
            vendor: _infinityxVendor(model),
            model: model,
            codename: codename,
            type: 'phone',
            currentBranch: '',
            releaseYear: null,
          ),
        );
      } on Object catch (err) {
        stderr.writeln('[sync] skip infinityx ${e.path}: $err');
      }
    }
  }

  final List<_Device> out = byCodename.values.toList();
  out.sort((_Device a, _Device b) {
    final int v = a.vendor.compareTo(b.vendor);
    if (v != 0) return v;
    final int mm = a.model.toLowerCase().compareTo(b.model.toLowerCase());
    if (mm != 0) return mm;
    return a.codename.compareTo(b.codename);
  });
  return out;
}

/// Ensures the Infinity X `devices/` files for a single [branch] are present
/// under [devicesDir], downloading and extracting the branch tarball when
/// needed. Falls back to any existing cache if the network fetch fails.
Future<void> _ensureInfinityxBranch({
  required String branch,
  required String tarUrl,
  required Directory devicesDir,
  required bool refresh,
}) async {
  final bool cached = devicesDir.existsSync() && devicesDir.listSync().isNotEmpty;
  if (!refresh && cached) return;

  final String branchDir = '$_infinityxCacheDir/$branch';
  Directory(branchDir).createSync(recursive: true);
  final String tarPath = '$branchDir/repo.tar.gz';
  final ProcessResult curl = await Process.run('curl', <String>[
    '-sSL',
    '--connect-timeout',
    '30',
    '--retry',
    '5',
    '--retry-delay',
    '3',
    '--retry-all-errors',
    tarUrl,
    '-o',
    tarPath,
  ]);
  if (curl.exitCode != 0) {
    if (cached) {
      stderr.writeln(
        '[sync] infinityx $branch fetch failed, using cached ${devicesDir.path}',
      );
      return;
    }
    throw StateError('infinityx $branch curl failed: ${curl.stderr}');
  }
  // Extract only official_devices-<branch>/devices/*.json, dropping the
  // top-level repo folder so files land directly in the branch cache dir.
  final ProcessResult tar = await Process.run('tar', <String>[
    '-xzf',
    tarPath,
    '-C',
    branchDir,
    '--strip-components=1',
    'official_devices-$branch/devices',
  ]);
  if (tar.exitCode != 0) {
    throw StateError('infinityx $branch tar failed: ${tar.stderr}');
  }
}


/// Derives the manufacturer for a Project Infinity X device from its model
/// string, since the upstream device files carry no explicit vendor field.
String _infinityxVendor(String model) {
  final String m = model.toLowerCase();
  if (m.contains('pixel')) return 'Google';
  if (m.contains('oneplus')) return 'OnePlus';
  if (m.contains('samsung') || m.contains('galaxy')) return 'Samsung';
  if (m.contains('nothing') || m.contains('cmf')) return 'Nothing';
  if (m.contains('infinix')) return 'Infinix';
  if (m.contains('itel')) return 'Itel';
  if (m.contains('realme') || m.contains('narzo')) return 'Realme';
  if (m.contains('motorola')) return 'Motorola';
  if (m.contains('poco') || m.contains('redmi') || m.contains('xiaomi')) {
    return 'Xiaomi';
  }
  // Fallback: normalise the leading brand token.
  return _normalizeVendor(model.split(RegExp(r'[\s/]')).first);
}

List<_Device> _parseAllDevices(Directory devicesDir) {
  // Vendors excluded from the catalog entirely. ARK's only claim to fame is
  // a single 2015 budget phone (Benefit A3, "peach") that falls inside
  // TWRP's broad date-based matcher; no ROM in the catalog targets it, so
  // it surfaced as a zero-ROM brand card on the Devices page.
  const Set<String> excludedVendors = <String>{'ARK'};
  final List<_Device> out = <_Device>[];
  for (final FileSystemEntity e in devicesDir.listSync()) {
    if (e is! File || !e.path.endsWith('.yml')) continue;    try {
      final YamlMap y = loadYaml(e.readAsStringSync()) as YamlMap;
      final String vendor = (y['vendor'] as String?)?.trim() ?? '';
      final String name = (y['name'] as String?)?.trim() ?? '';
      final String codename = (y['codename'] as String?)?.trim() ?? '';
      final String currentBranch =
          (y['current_branch']?.toString() ?? '').trim();
      final String release = (y['release']?.toString() ?? '').trim();
      final String type = (y['type'] as String?)?.trim() ?? 'phone';
      if (vendor.isEmpty || name.isEmpty || codename.isEmpty) continue;
      final String normalizedVendor = _normalizeVendor(vendor);
      if (excludedVendors.contains(normalizedVendor)) continue;
      out.add(
        _Device(
          vendor: normalizedVendor,
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
    final int m = a.model.toLowerCase().compareTo(b.model.toLowerCase());
    if (m != 0) return m;
    // Final tie-breaker so the output is fully deterministic across
    // filesystems (listSync() order is not stable between machines).
    return a.codename.compareTo(b.codename);
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
    // The LineageOS wiki spells the company "10.or"; the PixelOS device
    // repo spells it "10or". Same vendor, keep the wiki spelling so the
    // two sources do not produce duplicate brand cards.
    case '10or':
    case '10.or':
      return '10.or';
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
      // Officially everything in the wiki on a currently-maintained
      // branch (LineageOS 20 = Android 13 and newer). All form factors
      // included: phones, tablets, Android TV, set-top boxes.
      return (_Device d) => _branchAtLeast(d, 20);
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
    case 'arrowos':
      // Defunct; no devices listed. Kept so any stale catalog id passed
      // here resolves to a no-op filter instead of throwing.
      return (_Device _) => false;
    case 'risingos':
      // Original RisingOS is on hiatus; show no devices for the legacy
      // id. The active project lives under 'risingosrevived'.
      return (_Device _) => false;
    case 'risingosrevived':
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
    case 'pixelos':
      // PixelOS devices come from a live fetch of the official_devices
      // repo in [_loadPixelosDevices], so this policy is never consulted.
      // We still need a case so the switch is exhaustive, but it should
      // match nothing if it is ever called.
      return (_Device _) => false;
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
    case 'infinityx':
      // Project Infinity X devices come from a live fetch of its
      // official_devices repo in [_loadInfinityxDevices], so this policy is
      // never consulted. Match nothing if it is ever called.
      return (_Device _) => false;
    case 'un1ca':
      // UN1CA is a One UI based custom firmware with a small, maintainer
      // confirmed device list. Per-device support depends on hand-written
      // patches in the build system and the LineageOS wiki has no notion of
      // these One UI ports, so we pin the list to an explicit codename
      // allowlist (matching the project's official downloads page) instead of
      // a year-based heuristic that would sweep in unsupported Samsung phones.
      const Set<String> un1caCodenames = <String>{
        'a52sxq', // Galaxy A52s 5G
        'a73xq', // Galaxy A73 5G
        'm52xq', // Galaxy M52 5G
        'o1s', // Galaxy S21 5G (Exynos)
        't2s', // Galaxy S21+ 5G (Exynos)
        'p3s', // Galaxy S21 Ultra 5G (Exynos)
        'r9s', // Galaxy S21 FE 5G (Exynos)
      };
      return (_Device d) =>
          d.vendor == 'Samsung' && un1caCodenames.contains(d.codename);
    case 'artisanrom':
      // ArtisanROM Quant targets a specific, maintainer-confirmed set of
      // Exynos Samsung Galaxy devices: the Exynos 990 S20 / Note20 series
      // and the Exynos 9820 S10 series. The Note10 series and the various
      // A / M / F mid-rangers that a year-based heuristic would sweep in are
      // NOT supported, and neither is the Snapdragon S20 FE (r8q), so we pin
      // the device list to an explicit codename allowlist instead.
      const Set<String> artisanCodenames = <String>{
        // Exynos 9820 - Galaxy S10 series
        'beyond0lte', // S10e
        'beyond1lte', // S10
        'beyond2lte', // S10+
        'beyondx', // S10 5G
        // Exynos 990 - Galaxy S20 series
        'x1s', // S20 (4G/5G)
        'y2s', // S20+ (4G/5G)
        'z3s', // S20 Ultra (5G)
        'r8s', // S20 FE (Exynos)
        // Exynos 990 - Galaxy Note20 series
        'c1s', // Note20 (5G)
        'c2s', // Note20 Ultra (5G)
      };
      return (_Device d) =>
          d.vendor == 'Samsung' && artisanCodenames.contains(d.codename);
    case 'lineagee3q':
    case 'drketan':
      // Community builds for the Snapdragon Galaxy S24 Ultra. The device has
      // no LineageOS wiki entry, so it is injected explicitly in [_buildRoms]
      // and this policy matches nothing from the wiki pool.
      return (_Device _) => false;

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
  return devices.map((_Device d) {
    final String? forum = _xdaDeviceForums[d.codename];
    return <String, dynamic>{
      'brand': d.vendor,
      'model': d.model,
      'codename': d.codename,
      if (forum != null) 'forumUrl': forum,
    };
  }).toList();
}

/// Curated per-codename XDA Developers forum category URLs.
///
/// We only seed devices we know have an active xenForo category on
/// xdaforums.com (i.e. URLs in the canonical `/forums/<slug>.<id>/`
/// shape, which is what [XdaFeedService.feedUrlFor] knows how to
/// derive an RSS feed from). Devices without an entry simply do not
/// show the "Recent XDA discussions" section, which is the safe
/// default - the section is opt-in by codename.
///
/// To add a device, find its forum on https://xdaforums.com/forums/
/// and copy the URL ending in `<slug>.<id>/`. We append
/// `?prefix_id=33` so the section (and the "Open on XDA" button)
/// jumps straight to the Development sub-listing rather than the
/// noisier general forum.
const String _xdaDevFilter = '?prefix_id=33';
const Map<String, String> _xdaDeviceForums = <String, String>{
  // Asus
  'sake': 'https://xdaforums.com/f/asus-zenfone-8.12291/$_xdaDevFilter',

  // Fairphone
  'FP2': 'https://xdaforums.com/f/fairphone-2.4281/$_xdaDevFilter',
  'FP3': 'https://xdaforums.com/f/fairphone-3-3.12787/$_xdaDevFilter',
  'FP4': 'https://xdaforums.com/f/fairphone-4.12789/$_xdaDevFilter',
  'FP5': 'https://xdaforums.com/f/fairphone-5.12791/$_xdaDevFilter',

  // Google
  'akita': 'https://xdaforums.com/f/google-pixel-8a.12851/$_xdaDevFilter',
  'barbet': 'https://xdaforums.com/f/google-pixel-5a.12359/$_xdaDevFilter',
  'bluejay': 'https://xdaforums.com/f/google-pixel-6a.12605/$_xdaDevFilter',
  'caiman':
      'https://xdaforums.com/f/google-pixel-9-pro-9-pro-xl.12880/$_xdaDevFilter',
  'cheetah': 'https://xdaforums.com/f/google-pixel-7-pro.12609/$_xdaDevFilter',
  'husky': 'https://xdaforums.com/f/google-pixel-8-pro.12801/$_xdaDevFilter',
  'komodo':
      'https://xdaforums.com/f/google-pixel-9-pro-9-pro-xl.12880/$_xdaDevFilter',
  'lynx': 'https://xdaforums.com/f/google-pixel-7a.12743/$_xdaDevFilter',
  'oriole': 'https://xdaforums.com/f/google-pixel-6.12311/$_xdaDevFilter',
  'panther': 'https://xdaforums.com/f/google-pixel-7.12607/$_xdaDevFilter',
  'raven': 'https://xdaforums.com/f/google-pixel-6-pro.12313/$_xdaDevFilter',
  'shiba': 'https://xdaforums.com/f/google-pixel-8.12799/$_xdaDevFilter',
  'tegu': 'https://xdaforums.com/f/google-pixel-9a.12927/$_xdaDevFilter',
  'tokay': 'https://xdaforums.com/f/google-pixel-9.12879/$_xdaDevFilter',

  // LG
  'd800': 'https://xdaforums.com/f/at-t-lg-g2.3022/$_xdaDevFilter',
  'd801': 'https://xdaforums.com/f/t-mobile-lg-g2.3029/$_xdaDevFilter',
  'd850': 'https://xdaforums.com/f/at-t-lg-g3.3381/$_xdaDevFilter',
  'd851': 'https://xdaforums.com/f/t-mobile-lg-g3.3388/$_xdaDevFilter',
  'ls990': 'https://xdaforums.com/f/sprint-lg-g3.3374/$_xdaDevFilter',
  'vs985': 'https://xdaforums.com/f/verizon-lg-g3.3367/$_xdaDevFilter',

  // Motorola
  'bangkk': 'https://xdaforums.com/f/motorola-moto-g84-5g.12932/$_xdaDevFilter',
  'bathena': 'https://xdaforums.com/f/motorola-defy-2021.12369/$_xdaDevFilter',
  'berlin': 'https://xdaforums.com/f/motorola-edge-20.12419/$_xdaDevFilter',
  'berlna': 'https://xdaforums.com/f/motorola-edge-2021.12441/$_xdaDevFilter',
  'borneo': 'https://xdaforums.com/f/moto-g-power-2021.12069/$_xdaDevFilter',
  'denver': 'https://xdaforums.com/f/moto-g-stylus-5g.12373/$_xdaDevFilter',
  'devon': 'https://xdaforums.com/f/motorola-moto-g32.12803/$_xdaDevFilter',
  'dubai': 'https://xdaforums.com/f/motorola-edge-30.12697/$_xdaDevFilter',
  'eqs':
      'https://xdaforums.com/f/motorola-edge-30-ultra-motorola-moto-x30-pro.12663/$_xdaDevFilter',
  'hawao': 'https://xdaforums.com/f/moto-g42.12629/$_xdaDevFilter',
  'milanf': 'https://xdaforums.com/f/moto-g-stylus-5g.12373/$_xdaDevFilter',
  'nio':
      'https://xdaforums.com/f/motorola-moto-g100-edge-s.12173/$_xdaDevFilter',
  'pstar': 'https://xdaforums.com/f/motorola-edge-20-pro.12421/$_xdaDevFilter',
  'rhode': 'https://xdaforums.com/f/motorola-moto-g52.12797/$_xdaDevFilter',
  'rtwo':
      'https://xdaforums.com/f/motorola-edge-40-pro-moto-x40-china.12731/$_xdaDevFilter',

  // Nothing
  'Pong': 'https://xdaforums.com/f/nothing-phone-2.12739/$_xdaDevFilter',
  'Spacewar': 'https://xdaforums.com/f/nothing-phone-1.12585/$_xdaDevFilter',

  // OSOM
  'pyrite': 'https://xdaforums.com/f/osom-ov1.12561/$_xdaDevFilter',

  // OnePlus
  'aston':
      'https://xdaforums.com/f/oneplus-12r-oneplus-ace-3.12829/$_xdaDevFilter',
  'astonc':
      'https://xdaforums.com/f/oneplus-12r-oneplus-ace-3.12829/$_xdaDevFilter',
  'audi': 'https://xdaforums.com/f/oneplus-nord-4-ace-3v.12866/$_xdaDevFilter',
  'avalon':
      'https://xdaforums.com/f/oneplus-nord-4-ace-3v.12866/$_xdaDevFilter',
  'corvette': 'https://xdaforums.com/f/oneplus-ace-3-pro.12865/$_xdaDevFilter',
  'dodge': 'https://xdaforums.com/f/oneplus-13.12893/$_xdaDevFilter',
  'giulia': 'https://xdaforums.com/f/oneplus-13r-ace-5.12915/$_xdaDevFilter',
  'giuliac': 'https://xdaforums.com/f/oneplus-13r-ace-5.12915/$_xdaDevFilter',
  'lemonade': 'https://xdaforums.com/f/oneplus-11.12687/$_xdaDevFilter',
  'lemonadep': 'https://xdaforums.com/f/oneplus-9-pro.12153/$_xdaDevFilter',
  'lemonades': 'https://xdaforums.com/f/oneplus-9r.12183/$_xdaDevFilter',
  'lexus': 'https://xdaforums.com/f/oneplus-nord-5.12937/$_xdaDevFilter',
  'martini': 'https://xdaforums.com/f/oneplus-9rt.12505/$_xdaDevFilter',
  'salami': 'https://xdaforums.com/f/oneplus-11r-ace-2.12717/$_xdaDevFilter',
  'waffle': 'https://xdaforums.com/f/oneplus-12.12820/$_xdaDevFilter',

  // Samsung
  'a52q': 'https://xdaforums.com/f/samsung-galaxy-a52-4g.12131/$_xdaDevFilter',
  'a52sxq':
      'https://xdaforums.com/f/samsung-galaxy-a52s-5g.12587/$_xdaDevFilter',
  'a72q': 'https://xdaforums.com/f/samsung-galaxy-a72.12141/$_xdaDevFilter',
  'a73xq': 'https://xdaforums.com/f/samsung-galaxy-a73-5g.12667/$_xdaDevFilter',
  'dm1q': 'https://xdaforums.com/f/samsung-galaxy-s23.12707/$_xdaDevFilter',
  'e3q':
      'https://xdaforums.com/f/samsung-galaxy-s24-ultra.12819/$_xdaDevFilter',
  'f62': 'https://xdaforums.com/f/samsung-galaxy-f62-m62.12127/$_xdaDevFilter',
  'm52xq': 'https://xdaforums.com/f/samsung-galaxy-m52-5g.12703/$_xdaDevFilter',

  // Sony
  'pdx214': 'https://xdaforums.com/f/sony-xperia-5-iii.12229/$_xdaDevFilter',
  'pdx215': 'https://xdaforums.com/f/sony-xperia-1-iii.12227/$_xdaDevFilter',
  'pdx223': 'https://xdaforums.com/f/sony-xperia-1-iv.12633/$_xdaDevFilter',
  'pdx224': 'https://xdaforums.com/f/sony-xperia-5-iv.12677/$_xdaDevFilter',
  'pdx225': 'https://xdaforums.com/f/sony-xperia-10-iv.12727/$_xdaDevFilter',
  'pdx234': 'https://xdaforums.com/f/sony-xperia-1-v.12749/$_xdaDevFilter',
  'pdx235': 'https://xdaforums.com/f/sony-xperia-10-v.12751/$_xdaDevFilter',
  'pdx237': 'https://xdaforums.com/f/sony-xperia-5-v.12795/$_xdaDevFilter',
  'pdx245': 'https://xdaforums.com/f/sony-xperia-1-vi.12858/$_xdaDevFilter',
  'pdx257': 'https://xdaforums.com/f/sony-xperia-10-vii.12986/$_xdaDevFilter',

  // Wileyfox
  'crackling': 'https://xdaforums.com/f/wileyfox-swift.4960/$_xdaDevFilter',

  // Xiaomi / POCO
  'alioth':
      'https://xdaforums.com/f/xiaomi-poco-f3-xiaomi-mi-11x-redmi-k40.12161/$_xdaDevFilter',
  'diting':
      'https://xdaforums.com/f/xiaomi-12t-pro-redmi-k50-ultra.12673/$_xdaDevFilter',
  'fuxi': 'https://xdaforums.com/f/xiaomi-13.12681/$_xdaDevFilter',
  'garnet':
      'https://xdaforums.com/f/xiaomi-redmi-note-13-pro-5g-poco-x6-5g.12860/$_xdaDevFilter',
  'haydn':
      'https://xdaforums.com/f/xiaomi-mi-11i-11x-pro-redmi-k40-pro.12191/$_xdaDevFilter',
  'lisa': 'https://xdaforums.com/f/xiaomi-11-lite-5g-ne.12519/$_xdaDevFilter',
  'marble':
      'https://xdaforums.com/f/xiaomi-poco-f5-redmi-note-12-turbo-china.12733/$_xdaDevFilter',
  'mayfly': 'https://xdaforums.com/f/xiaomi-12s.12647/$_xdaDevFilter',
  'mondrian':
      'https://xdaforums.com/f/poco-f5-pro-redmi-k60-china.12741/$_xdaDevFilter',
  'munch':
      'https://xdaforums.com/f/xiaomi-poco-f4-munch-redmi-k40s.12661/$_xdaDevFilter',
  'nuwa': 'https://xdaforums.com/f/xiaomi-13-pro.12683/$_xdaDevFilter',
  'peridot':
      'https://xdaforums.com/f/xiaomi-poco-f6-redmi-turbo-3.12852/$_xdaDevFilter',
  'renoir': 'https://xdaforums.com/f/xiaomi-mi-11-lite-5g.12189/$_xdaDevFilter',
  'sweet': 'https://xdaforums.com/f/redmi-note-10-pro.12117/$_xdaDevFilter',
  'thor': 'https://xdaforums.com/f/xiaomi-12s-ultra.12643/$_xdaDevFilter',
  'unicorn': 'https://xdaforums.com/f/xiaomi-12s-pro.12645/$_xdaDevFilter',
  'vayu': 'https://xdaforums.com/f/xiaomi-poco-x3-pro.12163/$_xdaDevFilter',
  'venus': 'https://xdaforums.com/f/xiaomi-mi-11.12057/$_xdaDevFilter',
  'vermeer':
      'https://xdaforums.com/f/xiaomi-poco-f6-pro-redmi-k70.12853/$_xdaDevFilter',
  'zeus': 'https://xdaforums.com/f/xiaomi-12-pro.12493/$_xdaDevFilter',
};

/// Galaxy Note20 (Exynos 990) devices that ArtisanROM Quant supports but the
/// LineageOS wiki has no entry for, so they must be injected by hand. Keep the
/// codenames in sync with the `artisanrom` policy allowlist.
const List<_DeviceSeed> _artisanExtraSeeds = <_DeviceSeed>[
  _DeviceSeed('c1s', 'Galaxy Note20 (5G)'),
  _DeviceSeed('c2s', 'Galaxy Note20 Ultra (5G)'),
];

List<_Device> get _artisanExtraDevices => <_Device>[
  for (final _DeviceSeed s in _artisanExtraSeeds)
    _Device(
      vendor: 'Samsung',
      model: s.model,
      codename: s.codename,
      type: 'phone',
      currentBranch: '',
      releaseYear: 2020,
    ),
];

/// The full UN1CA device list from the project's official downloads page.
/// Most of these One UI ports have no LineageOS wiki entry, so the catalog
/// would otherwise show fewer devices than the project actually supports.
/// Keep the codenames in sync with the `un1ca` policy allowlist.
const List<_DeviceSeed> _un1caSeeds = <_DeviceSeed>[
  _DeviceSeed('a52sxq', 'Galaxy A52s 5G', 2021),
  _DeviceSeed('a73xq', 'Galaxy A73 5G', 2022),
  _DeviceSeed('m52xq', 'Galaxy M52 5G', 2021),
  _DeviceSeed('o1s', 'Galaxy S21 5G (Exynos)', 2021),
  _DeviceSeed('t2s', 'Galaxy S21+ 5G (Exynos)', 2021),
  _DeviceSeed('p3s', 'Galaxy S21 Ultra 5G (Exynos)', 2021),
  _DeviceSeed('r9s', 'Galaxy S21 FE 5G (Exynos)', 2022),
];

List<_Device> get _un1caExtraDevices => <_Device>[
  for (final _DeviceSeed s in _un1caSeeds)
    _Device(
      vendor: 'Samsung',
      model: s.model,
      codename: s.codename,
      type: 'phone',
      currentBranch: '',
      releaseYear: s.releaseYear ?? 2021,
    ),
];

/// The Snapdragon Galaxy S24 Ultra has no LineageOS wiki entry, so the
/// community builds that target it (unofficial LineageOS, Dr.Ketan ROM)
/// must inject the device by hand.
const List<_DeviceSeed> _e3qSeeds = <_DeviceSeed>[
  _DeviceSeed('e3q', 'Galaxy S24 Ultra', 2024),
];

List<_Device> get _e3qExtraDevices => <_Device>[
  for (final _DeviceSeed s in _e3qSeeds)
    _Device(
      vendor: 'Samsung',
      model: s.model,
      codename: s.codename,
      type: 'phone',
      currentBranch: '',
      releaseYear: s.releaseYear ?? 2024,
    ),
];

List<Map<String, dynamic>> _buildRoms(
  List<_Device> all, {
  required List<_Device> pixelosDevices,
  required List<_Device> infinityxDevices,
}) {
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
      // Official screenshots pulled from the LineageOS release-announcement
      // blog posts (Changelog 27 to 30). These are the real first-party app
      // shots (Aperture camera, Twelve clock, Glimpse gallery, Jelly browser,
      // Calculator, Dialer) plus the LineageOS 22.2 hero and catapult banner;
      // much higher quality than the older homepage marketing webps.
      screenshots: <String>[
        'https://lineageos.org/images/2025-10-11/hero.webp',
        'https://lineageos.org/images/2025-10-11/catapult.webp',
        'https://lineageos.org/images/2022-12-31/aperture.webp',
        'https://lineageos.org/images/2024-12-31/twelve.webp',
        'https://lineageos.org/images/2024-02-14/glimpse.webp',
        'https://lineageos.org/images/2024-02-14/jelly.webp',
        'https://lineageos.org/images/2024-02-14/dialer.webp',
        'https://lineageos.org/images/2024-02-14/calculator.webp',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://download.lineageos.org/',
      forumUrl: 'https://forum.xda-developers.com/f/lineageos-questions-answers.5614/',
      links: <_RomLink>[
        _RomLink(
          label: 'Website',
          url: 'https://lineageos.org/',
          iconName: 'web',
        ),
        _RomLink(
          label: 'GitHub',
          url: 'https://github.com/LineageOS',
          iconName: 'github',
        ),
        _RomLink(
          label: 'Wiki',
          url: 'https://wiki.lineageos.org/',
          iconName: 'web',
        ),
      ],
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
      // Curated gallery images from crdroid.net/#gallery, served as webp.
      screenshots: <String>[
        'https://crdroid.net/img/gallery/gallery-1.webp',
        'https://crdroid.net/img/gallery/gallery-2.webp',
        'https://crdroid.net/img/gallery/gallery-3.webp',
        'https://crdroid.net/img/gallery/gallery-4.webp',
        'https://crdroid.net/img/gallery/gallery-5.webp',
        'https://crdroid.net/img/gallery/gallery-6.webp',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://crdroid.net/downloads',
      links: <_RomLink>[
        _RomLink(
          label: 'Website',
          url: 'https://crdroid.net/',
          iconName: 'web',
        ),
        _RomLink(
          label: 'GitHub',
          url: 'https://github.com/crdroidandroid',
          iconName: 'github',
        ),
      ],
    ),
    _RomSpec(
      id: 'infinityx',
      name: 'Project Infinity X',
      headerAsset: 'images/infinityx.png',
      shortTagline:
          'AOSP custom ROM focused on refined performance and endless customisation.',
      description: <String>[
        'Project Infinity X is an Android 16 AOSP custom ROM that brings refined performance, stunning visuals, and deep customisation to a wide range of devices. Built for stability and designed for enthusiasts, it keeps the clean Pixel feel while adding a powerful theme engine and a large set of UI tweaks.',
        'It is free and open-source under Apache-2.0, maintained by tejas101k and a large community of device maintainers, with regular monthly OTA updates carrying the latest Android security patches.',
      ],
      features: <String>[
        'Optimised SystemUI tweaks aiming to beat stock OEM performance.',
        'Powerful theme engine with complete control over the UI.',
        'Designed to stay compatible with security-sensitive apps and device integrity checks.',
        'Adaptive battery and intelligent memory management for a smooth experience.',
        'Monthly OTA updates with new features and the latest security patches.',
        'Vanilla and GApps install paths, plus a GSI build for unlisted devices.',
      ],
      // Official screenshots served from the project homepage gallery
      // (projectinfinity-x.com/#screenshots), verified hot-linkable webp.
      screenshots: <String>[
        'https://projectinfinity-x.com/assets/images/ss-1.webp',
        'https://projectinfinity-x.com/assets/images/ss-2.webp',
        'https://projectinfinity-x.com/assets/images/ss-3.webp',
        'https://projectinfinity-x.com/assets/images/ss-4.webp',
        'https://projectinfinity-x.com/assets/images/ss-5.webp',
        'https://projectinfinity-x.com/assets/images/ss-6.webp',
        'https://projectinfinity-x.com/assets/images/ss-7.webp',
        'https://projectinfinity-x.com/assets/images/ss-8.webp',
        'https://projectinfinity-x.com/assets/images/ss-9.webp',
        'https://projectinfinity-x.com/assets/images/ss-10.webp',
        'https://projectinfinity-x.com/assets/images/ss-11.webp',
        'https://projectinfinity-x.com/assets/images/ss-12.webp',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://projectinfinity-x.com/downloads',
      forumUrl: 'https://xdaforums.com/tags/infinityx/',
      links: <_RomLink>[
        _RomLink(
          label: 'Website',
          url: 'https://projectinfinity-x.com/',
          iconName: 'web',
        ),
        _RomLink(
          label: 'GitHub',
          url: 'https://github.com/projectinfinity-x/',
          iconName: 'github',
        ),
        _RomLink(
          label: 'Telegram',
          url: 'https://t.me/projectinfinityx',
          iconName: 'forum',
        ),
        _RomLink(
          label: 'FAQ',
          url: 'https://projectinfinity-x.com/faq',
          iconName: 'web',
        ),
      ],
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
      // Pixel Experience shut down upstream development in 2024 and never
      // shipped a dedicated UI gallery; the official_devices repo only
      // holds device-frame marketing renders. Use real Pixel Launcher
      // screenshots from Wikimedia Commons instead: free-licensed, full
      // portrait-aspect UI shots that represent the experience the ROM
      // ships (Pixel home screen across multiple Android versions).
      screenshots: <String>[
        'https://upload.wikimedia.org/wikipedia/commons/2/2d/Android_16_home_screen_screenshot.png',
        'https://upload.wikimedia.org/wikipedia/commons/8/8e/Customized_Android_16_Home_Screen.jpg',
        'https://upload.wikimedia.org/wikipedia/commons/7/71/Pixel_4a_Android_11_Launcher.png',
        'https://upload.wikimedia.org/wikipedia/commons/0/0c/Android_10_screenshot.png',
        'https://upload.wikimedia.org/wikipedia/commons/7/75/Android_14_Go_Home_Screen.png',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://download.pixelexperience.org/',
      forumUrl: 'https://forum.xda-developers.com/c/pixel-experience.10089/',
      links: <_RomLink>[
        _RomLink(
          label: 'Website',
          url: 'https://pixelexperience.org/',
          iconName: 'web',
        ),
        _RomLink(
          label: 'GitHub',
          url: 'https://github.com/PixelExperience',
          iconName: 'github',
        ),
      ],
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
      // Hosted on the project's www_gitres GitHub repo (raw), referenced
      // directly by the live evolution-x.org marketing page.
      screenshots: <String>[
        'https://raw.githubusercontent.com/Evolution-X/www_gitres/refs/heads/main/screenshots/images/Home.webp',
        'https://raw.githubusercontent.com/Evolution-X/www_gitres/refs/heads/main/screenshots/images/Lockscreen.webp',
        'https://raw.githubusercontent.com/Evolution-X/www_gitres/refs/heads/main/screenshots/images/SystemUI.webp',
        'https://raw.githubusercontent.com/Evolution-X/www_gitres/refs/heads/main/screenshots/images/Settings.webp',
        'https://raw.githubusercontent.com/Evolution-X/www_gitres/refs/heads/main/screenshots/images/Evolver.webp',
        'https://raw.githubusercontent.com/Evolution-X/www_gitres/refs/heads/main/screenshots/images/Evolver_about.webp',
        'https://raw.githubusercontent.com/Evolution-X/www_gitres/refs/heads/main/screenshots/images/About.webp',
        'https://raw.githubusercontent.com/Evolution-X/www_gitres/refs/heads/main/screenshots/images/Updater.webp',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://evolution-x.org/devices',
      links: <_RomLink>[
        _RomLink(
          label: 'Website',
          url: 'https://evolution-x.org/',
          iconName: 'web',
        ),
        _RomLink(
          label: 'GitHub',
          url: 'https://github.com/Evolution-X',
          iconName: 'github',
        ),
      ],
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
      // The current paranoidandroid.co landing is a JS bundle with no
      // static screenshots. Use the cleaner official archived Quartz-era
      // device render from paranoidandroid.co; older AOSPA feature slides
      // exist, but visually read as dated.
      screenshots: <String>[
        'https://web.archive.org/web/20200714130039if_/https://paranoidandroid.co/assets/screens/devices.png',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://paranoidandroid.co/',
      forumUrl: 'https://forum.xda-developers.com/c/paranoid-android-aospa.10316/',
      links: <_RomLink>[
        _RomLink(
          label: 'Website',
          url: 'https://paranoidandroid.co/',
          iconName: 'web',
        ),
        _RomLink(
          label: 'GitHub',
          url: 'https://github.com/AOSPA',
          iconName: 'github',
        ),
      ],
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
      // Real device UI shots from the official DotOS v5.2 release blog
      // (showing MonetWannabe theming, redesigned Settings, Gaming Mode,
      // Battery Manager and the new clock widgets running on devices).
      screenshots: <String>[
        'https://blog.droidontime.com/static/images/MonetWannabeTwoPoint.png',
        'https://blog.droidontime.com/static/images/settings_dashboard_fivetwo.png',
        'https://blog.droidontime.com/static/images/gaming_fivetwo.png',
        'https://blog.droidontime.com/static/images/battery_manager-fiveTwo.png',
        'https://blog.droidontime.com/static/images/widgets_fivetwo.png',
        'https://blog.droidontime.com/static/images/banner_five_dotTwo.png',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://www.droidontime.com/devices',
      links: <_RomLink>[
        _RomLink(
          label: 'Website',
          url: 'https://www.droidontime.com/',
          iconName: 'web',
        ),
        _RomLink(
          label: 'GitHub',
          url: 'https://github.com/DotOS',
          iconName: 'github',
        ),
      ],
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
      // The current blissroms.org site no longer exposes the screenshot
      // assets at stable paths; serve the original gallery from the
      // Internet Archive (2021 snapshot).
      screenshots: <String>[
        'https://web.archive.org/web/20211228193409im_/https://blissroms.org/screenshots/1.jpg',
        'https://web.archive.org/web/20211228193409im_/https://blissroms.org/screenshots/2.jpg',
        'https://web.archive.org/web/20211228193409im_/https://blissroms.org/screenshots/3.jpg',
        'https://web.archive.org/web/20211228193409im_/https://blissroms.org/screenshots/4.jpg',
        'https://web.archive.org/web/20211228193409im_/https://blissroms.org/screenshots/6.jpg',
        'https://web.archive.org/web/20211228193409im_/https://blissroms.org/screenshots/7.jpg',
        'https://web.archive.org/web/20211228193409im_/https://blissroms.org/screenshots/8.jpg',
        'https://web.archive.org/web/20211228193409im_/https://blissroms.org/screenshots/9.jpg',
        'https://web.archive.org/web/20211228193409im_/https://blissroms.org/screenshots/10.jpg',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://blissroms.org/downloads',
      links: <_RomLink>[
        _RomLink(
          label: 'Website',
          url: 'https://blissroms.org/',
          iconName: 'web',
        ),
        _RomLink(
          label: 'GitHub',
          url: 'https://github.com/BlissRoms',
          iconName: 'github',
        ),
      ],
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
      // Official POSP screenshots from the PotatoProject/website repo on
      // GitHub (the same assets the live posp.co landing uses).
      screenshots: <String>[
        'https://raw.githubusercontent.com/PotatoProject/website/master/src/assets/screenshots/screenshot1.png',
        'https://raw.githubusercontent.com/PotatoProject/website/master/src/assets/screenshots/screenshot2.png',
        'https://raw.githubusercontent.com/PotatoProject/website/master/src/assets/screenshots/screenshot3.png',
        'https://raw.githubusercontent.com/PotatoProject/website/master/src/assets/screenshots/screenshot4.png',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://posp.co/',
      links: <_RomLink>[
        _RomLink(
          label: 'Website',
          url: 'https://posp.co/',
          iconName: 'web',
        ),
        _RomLink(
          label: 'GitHub',
          url: 'https://github.com/PotatoProject',
          iconName: 'github',
        ),
      ],
    ),
    _RomSpec(
      id: 'risingosrevived',
      name: 'RisingOS Revived',
      headerAsset: 'images/risingos.png',
      shortTagline:
          'Community continuation of RisingOS after its original team went on hiatus.',
      description: <String>[
        'RisingOS Revived is a community-led continuation of the original RisingOS, which has been on hiatus. A group of former contributors and device maintainers picked the codebase up to keep monthly builds, security patches, and customisation features flowing.',
        'The project is coordinated on Telegram and developed openly under the RisingOS-Revived GitHub organisation. Per-device builds are published to the Revived devices page.',
      ],
      features: <String>[
        'Continuation of the RisingOS feature set: deep customisation, Pixel-style UI, AI integrations.',
        'Community-maintained, fully open source.',
        'Active Telegram channel and GitHub org.',
      ],
      // Official Rising Revived device screenshots from their gh-pages
      // site repo (risingos-revived-devices.github.io).
      screenshots: <String>[
        'https://raw.githubusercontent.com/RisingOS-Revived-devices/risingos-revived-devices.github.io/refs/heads/main/assets/img/screenshots/ss-1-7-portrait.png',
        'https://raw.githubusercontent.com/RisingOS-Revived-devices/risingos-revived-devices.github.io/refs/heads/main/assets/img/screenshots/ss-2-7-portrait.png',
        'https://raw.githubusercontent.com/RisingOS-Revived-devices/risingos-revived-devices.github.io/refs/heads/main/assets/img/screenshots/ss-3-7-portrait.png',
        'https://raw.githubusercontent.com/RisingOS-Revived-devices/risingos-revived-devices.github.io/refs/heads/main/assets/img/screenshots/ss-4-7-portrait.png',
        'https://raw.githubusercontent.com/RisingOS-Revived-devices/risingos-revived-devices.github.io/refs/heads/main/assets/img/screenshots/ss-5-7-portrait.png',
        'https://raw.githubusercontent.com/RisingOS-Revived-devices/risingos-revived-devices.github.io/refs/heads/main/assets/img/screenshots/ss-6-7-portrait.png',
        'https://raw.githubusercontent.com/RisingOS-Revived-devices/risingos-revived-devices.github.io/refs/heads/main/assets/img/screenshots/ss-7-7-portrait.png',
      ],
      downloadLabel: 'Devices and builds',
      downloadUrl: 'https://sourceforge.net/projects/risingos-revived/files/',
      forumUrl: 'https://t.me/s/RisingRevived/30',
      links: <_RomLink>[
        _RomLink(
          label: 'Telegram channel',
          url: 'https://t.me/s/RisingRevived/30',
          iconName: 'telegram',
        ),
        _RomLink(
          label: 'GitHub organisation',
          url: 'https://github.com/RisingOS-Revived',
          iconName: 'github',
        ),
        _RomLink(
          label: 'SourceForge downloads',
          url: 'https://sourceforge.net/projects/risingos-revived/files/',
          iconName: 'web',
        ),
        _RomLink(
          label: 'Devices page',
          url: 'https://risingos-revived-devices.github.io/',
          iconName: 'web',
        ),
      ],
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
      // Official voltageos.com marketing device frames (hashed filenames
      // are stable as long as the site is live).
      screenshots: <String>[
        'https://www.voltageos.com/assets/Frame%20342-CpdyX8g5.png',
        'https://www.voltageos.com/assets/Frame%20341-NKAEc1aS.png',
        'https://www.voltageos.com/assets/Frame%20338-7WWYWnVV.png',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://www.voltageos.com/devices',
      links: <_RomLink>[
        _RomLink(
          label: 'Website',
          url: 'https://www.voltageos.com/',
          iconName: 'web',
        ),
        _RomLink(
          label: 'GitHub',
          url: 'https://github.com/VoltageOS',
          iconName: 'github',
        ),
      ],
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
      // Official projectelixiros.com gallery images.
      screenshots: <String>[
        'https://projectelixiros.com/assets/images/elixir16-home.png',
        'https://projectelixiros.com/assets/images/s1.png',
        'https://projectelixiros.com/assets/images/s2.png',
        'https://projectelixiros.com/assets/images/s3.png',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://projectelixiros.com/download',
      warning:
          'In mid-2024, users discovered a hidden "kill switch" in Project '
          'Elixir\'s source code. The developers had locked certain '
          'customisation features behind a paywall, and if the ROM detected '
          'that a user was trying to bypass that paywall (via ADB commands '
          'or other methods), the embedded code would automatically wipe '
          'the device\'s internal storage, external SD card, and eSIMs '
          'without consent or warning. The Android community condemned '
          'this as an extreme, unethical, and potentially illegal '
          'anti-piracy measure, especially given the risk of a bug '
          'triggering a false positive and destroying innocent users\' '
          'data.\n\n'
          'Other documented issues around the same period included: '
          'shipping closed-source, obfuscated payload code inside what is '
          'meant to be an AOSP / GPL project (violating upstream licences '
          'and Android\'s open-source spirit); gating features behind paid '
          '"supporter" tiers on Telegram and Patreon, including basic '
          'customisation toggles that other ROMs provide for free; '
          'silencing critics by banning them from the official Telegram '
          'group, Discord, and XDA threads instead of addressing the '
          'concerns; initially denying that the kill switch existed and '
          'attacking the researchers who decompiled the code; threatening '
          'legal action against community members who shared findings; '
          'and reportedly pushing retaliatory OTAs that broke installs on '
          'devices belonging to vocal critics.\n\n'
          'Following the backlash, the developers announced they were '
          'shutting the project down, though independent device '
          'maintainers have occasionally kept builds alive. We strongly '
          'advise against installing Project Elixir; use crDroid, '
          'Evolution X, or DerpFest instead.',
      links: <_RomLink>[
        _RomLink(
          label: 'Website',
          url: 'https://projectelixiros.com/',
          iconName: 'web',
        ),
      ],
    ),
    _RomSpec(
      id: 'pixelos',
      name: 'PixelOS',
      headerAsset: 'images/pixelos.png',
      shortTagline:
          'Clean AOSP ROM that mirrors the Pixel software experience.',
      description: <String>[
        'PixelOS is an after-market distribution of Android based on AOSP that aims to reproduce the Pixel software experience on a wider range of devices, while staying close to stock.',
        'Builds ship with Pixel launcher, Pixel-style system UI, and Google apps preinstalled. Customisation is intentionally minimal in favour of polish and stability.',
      ],
      features: <String>[
        'Pixel launcher, wallpapers, and boot animation out of the box.',
        'GApps and Pixel feature drops bundled.',
        'Monthly security patches, fast adoption of new Android versions.',
      ],
      // Official PixelOS docs screenshots, pinned to the blog_assets commit
      // used by the current resources page. The old
      // /assets/img/screenshots/*.png gallery URLs now return 404.
      screenshots: <String>[
        'https://raw.githubusercontent.com/PixelOS-CI/blog_assets/aac63355b18c0e46dfd60bd1b45964c1bfc477b3/assets/screenshots/latest/1.webp',
        'https://raw.githubusercontent.com/PixelOS-CI/blog_assets/aac63355b18c0e46dfd60bd1b45964c1bfc477b3/assets/screenshots/latest/2.webp',
        'https://raw.githubusercontent.com/PixelOS-CI/blog_assets/aac63355b18c0e46dfd60bd1b45964c1bfc477b3/assets/screenshots/latest/3.webp',
        'https://raw.githubusercontent.com/PixelOS-CI/blog_assets/aac63355b18c0e46dfd60bd1b45964c1bfc477b3/assets/screenshots/latest/4.webp',
        'https://raw.githubusercontent.com/PixelOS-CI/blog_assets/aac63355b18c0e46dfd60bd1b45964c1bfc477b3/assets/screenshots/latest/5.webp',
        'https://raw.githubusercontent.com/PixelOS-CI/blog_assets/aac63355b18c0e46dfd60bd1b45964c1bfc477b3/assets/screenshots/latest/6.webp',
        'https://raw.githubusercontent.com/PixelOS-CI/blog_assets/aac63355b18c0e46dfd60bd1b45964c1bfc477b3/assets/screenshots/latest/7.webp',
        'https://raw.githubusercontent.com/PixelOS-CI/blog_assets/aac63355b18c0e46dfd60bd1b45964c1bfc477b3/assets/screenshots/latest/8.webp',
        'https://raw.githubusercontent.com/PixelOS-CI/blog_assets/aac63355b18c0e46dfd60bd1b45964c1bfc477b3/assets/screenshots/latest/9.webp',
        'https://raw.githubusercontent.com/PixelOS-CI/blog_assets/aac63355b18c0e46dfd60bd1b45964c1bfc477b3/assets/screenshots/latest/10.webp',
        'https://raw.githubusercontent.com/PixelOS-CI/blog_assets/aac63355b18c0e46dfd60bd1b45964c1bfc477b3/assets/screenshots/latest/11.webp',
        'https://raw.githubusercontent.com/PixelOS-CI/blog_assets/aac63355b18c0e46dfd60bd1b45964c1bfc477b3/assets/screenshots/latest/12.webp',
        'https://raw.githubusercontent.com/PixelOS-CI/blog_assets/aac63355b18c0e46dfd60bd1b45964c1bfc477b3/assets/screenshots/latest/13.webp',
        'https://raw.githubusercontent.com/PixelOS-CI/blog_assets/aac63355b18c0e46dfd60bd1b45964c1bfc477b3/assets/screenshots/latest/14.webp',
        'https://raw.githubusercontent.com/PixelOS-CI/blog_assets/aac63355b18c0e46dfd60bd1b45964c1bfc477b3/assets/screenshots/latest/15.webp',
        'https://raw.githubusercontent.com/PixelOS-CI/blog_assets/aac63355b18c0e46dfd60bd1b45964c1bfc477b3/assets/screenshots/latest/16.webp',
        'https://raw.githubusercontent.com/PixelOS-CI/blog_assets/aac63355b18c0e46dfd60bd1b45964c1bfc477b3/assets/screenshots/latest/17.webp',
        'https://raw.githubusercontent.com/PixelOS-CI/blog_assets/aac63355b18c0e46dfd60bd1b45964c1bfc477b3/assets/screenshots/latest/18.webp',
        'https://raw.githubusercontent.com/PixelOS-CI/blog_assets/aac63355b18c0e46dfd60bd1b45964c1bfc477b3/assets/screenshots/latest/19.webp',
        'https://raw.githubusercontent.com/PixelOS-CI/blog_assets/aac63355b18c0e46dfd60bd1b45964c1bfc477b3/assets/screenshots/latest/20.webp',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://pixelos.net/download',
      links: <_RomLink>[
        _RomLink(
          label: 'Website',
          url: 'https://pixelos.net/',
          iconName: 'web',
        ),
        _RomLink(
          label: 'GitHub',
          url: 'https://github.com/PixelOS-AOSP',
          iconName: 'github',
        ),
      ],
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
      // GrapheneOS doesn't publish screenshots on its own site, but real
      // device OS captures (home screen, Apps store, default-apps screen)
      // are hosted on Wikimedia Commons under CC licenses and used in
      // the Wikipedia GrapheneOS article. Pull them straight from the
      // upload.wikimedia.org CDN.
      screenshots: <String>[
        'https://upload.wikimedia.org/wikipedia/commons/e/ed/GrapheneOS_home_screen_Android_16_QPR2.png',
        'https://upload.wikimedia.org/wikipedia/commons/b/b9/GrapheneOS_Home_Screen.png',
        'https://upload.wikimedia.org/wikipedia/commons/5/5e/GrapheneOS_Screenshot.png',
        'https://upload.wikimedia.org/wikipedia/commons/a/ad/GrapheneOS-Apps.png',
        'https://upload.wikimedia.org/wikipedia/commons/1/13/GrapheneOS_Default_Apps_Screen_as_of_May_2023.png',
      ],
      downloadLabel: 'Install / web installer',
      downloadUrl: 'https://grapheneos.org/install/',
      forumUrl: 'https://discuss.grapheneos.org/',
      links: <_RomLink>[
        _RomLink(
          label: 'Website',
          url: 'https://grapheneos.org/',
          iconName: 'web',
        ),
        _RomLink(
          label: 'GitHub',
          url: 'https://github.com/GrapheneOS',
          iconName: 'github',
        ),
        _RomLink(
          label: 'Forum',
          url: 'https://discuss.grapheneos.org/',
          iconName: 'forum',
        ),
      ],
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
      // Official calyxos.org device feature illustrations.
      screenshots: <String>[
        'https://calyxos.org/assets/images/device/feature/communication.png',
        'https://calyxos.org/assets/images/device/feature/internet.png',
        'https://calyxos.org/assets/images/device/feature/app-store.png',
      ],
      downloadLabel: 'Install instructions',
      downloadUrl: 'https://calyxos.org/install/',
      forumUrl: 'https://discuss.calyxinstitute.org/',
      links: <_RomLink>[
        _RomLink(
          label: 'Website',
          url: 'https://calyxos.org/',
          iconName: 'web',
        ),
        _RomLink(
          label: 'Source',
          url: 'https://gitlab.com/CalyxOS',
          iconName: 'web',
        ),
        _RomLink(
          label: 'Forum',
          url: 'https://discuss.calyxinstitute.org/',
          iconName: 'forum',
        ),
      ],
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
      // Murena / e.foundation marketing illustrations from the
      // 2025 e-os homepage redesign.
      screenshots: <String>[
        'https://e.foundation/wp-content/uploads/2025/07/Group-1000000838-6.png',
        'https://e.foundation/wp-content/uploads/2025/07/Group-1000000838-1.png',
        'https://e.foundation/wp-content/uploads/2025/07/FP5-DuckDuckGo.png',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://doc.e.foundation/devices',
      forumUrl: 'https://community.e.foundation/',
      links: <_RomLink>[
        _RomLink(
          label: 'Website',
          url: 'https://e.foundation/',
          iconName: 'web',
        ),
        _RomLink(
          label: 'Murena',
          url: 'https://murena.com/',
          iconName: 'web',
        ),
        _RomLink(
          label: 'Forum',
          url: 'https://community.e.foundation/',
          iconName: 'forum',
        ),
      ],
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
      // The DivestOS project shut down in Dec 2024 and divestos.org no
      // longer resolves. Pull the official Android 12 gallery from the
      // Internet Archive snapshots (the `if_` suffix returns the raw
      // image bytes, redirecting to the closest 2024/2025 capture).
      screenshots: <String>[
        'https://web.archive.org/web/2024if_/https://divestos.org/images/screenshots/12/Home_Screen.png',
        'https://web.archive.org/web/2024if_/https://divestos.org/images/screenshots/12/Lock_Screen.png',
        'https://web.archive.org/web/2024if_/https://divestos.org/images/screenshots/12/Settings.png',
        'https://web.archive.org/web/2024if_/https://divestos.org/images/screenshots/12/Permissions.png',
        'https://web.archive.org/web/2024if_/https://divestos.org/images/screenshots/12/Mull.png',
        'https://web.archive.org/web/2024if_/https://divestos.org/images/screenshots/12/Camera.png',
        'https://web.archive.org/web/2024if_/https://divestos.org/images/screenshots/12/About.png',
      ],
      downloadLabel: 'Official downloads (Wayback)',
      downloadUrl: 'https://web.archive.org/web/2024/https://divestos.org/pages/devices',
      links: <_RomLink>[
        _RomLink(
          label: 'GitHub',
          url: 'https://github.com/Divested-Mobile',
          iconName: 'github',
        ),
        _RomLink(
          label: 'Website (Wayback)',
          url: 'https://web.archive.org/web/2024/https://divestos.org/',
          iconName: 'web',
        ),
      ],
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
      // Official DerpFest landing-page feature shots.
      screenshots: <String>[
        'https://derpfest.org/img/5226475742240116555.jpg',
        'https://derpfest.org/img/5226475742240116575.jpg',
        'https://derpfest.org/img/5226475742240116573.jpg',
        'https://derpfest.org/img/5226475742240116596.jpg',
        'https://derpfest.org/img/5226475742240116599.jpg',
        'https://derpfest.org/img/5190896052771427113.jpg',
        'https://derpfest.org/img/5467634951864913145.jpg',
        'https://derpfest.org/img/5233574769129625083.jpg',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://derpfest.org/devices',
      links: <_RomLink>[
        _RomLink(
          label: 'Website',
          url: 'https://derpfest.org/',
          iconName: 'web',
        ),
        _RomLink(
          label: 'GitHub',
          url: 'https://github.com/DerpFest-AOSP',
          iconName: 'github',
        ),
      ],
    ),
    _RomSpec(
      id: 'un1ca',
      name: 'UN1CA',
      headerAsset: 'images/un1ca.png',
      shortTagline:
          'Debloated, customisable One UI custom firmware for Samsung Galaxy devices.',
      description: <String>[
        "UN1CA is a custom firmware project by salvogiangri that takes Samsung's One UI and refines it for power users: stripping bloat, restoring choice, and layering in extra features while keeping the core Samsung experience intact.",
        'It ships an EROFS-based build, full Galaxy AI support (call assist, browsing assist, note/photo/writing assist, Now Brief and friends), an integrated OTA updater, and a long list of system-level toggles that One UI normally hides. The project is GPL-3.0 and developed in the open on GitHub with an active Telegram community.',
      ],
      features: <String>[
        'Galaxy AI features fully unlocked (audio eraser, call/browsing/writing assist, Now Brief, transcript assist, and more).',
        'Heavily debloated and DeKnoxed One UI with stock look and feel preserved.',
        'EROFS partitions for smaller, faster system images.',
        'Integrated OTA updater for in-place upgrades.',
        'Per-app blur toggle, OneUI Home animations, Vulkan toggle, and other quality-of-life switches.',
        'Ships TrickyStore, Play Integrity Fix, and Hide My Applist hooks out of the box.',
        'Open source under GPL-3.0 with builds published on GitHub Releases.',
      ],
      // Official UN1CA screenshots from the XDA release thread. They are
      // bundled locally (asset paths, not URLs) because the source host
      // blocks hot-linking, so remote loading is not possible.
      screenshots: <String>[
        'images/screenshots/un1ca/1_home.jpg',
        'images/screenshots/un1ca/2_lockscreen.jpg',
        'images/screenshots/un1ca/3_app_drawer.jpg',
        'images/screenshots/un1ca/4_quick_settings.jpg',
        'images/screenshots/un1ca/5_unica_settings.jpg',
        'images/screenshots/un1ca/6_unica_updates.jpg',
        'images/screenshots/un1ca/7_software_info.jpg',
      ],
      downloadLabel: 'GitHub releases',
      downloadUrl: 'https://github.com/salvogiangri/UN1CA/releases',
      forumUrl: 'https://github.com/salvogiangri/UN1CA/discussions',
      links: <_RomLink>[
        _RomLink(
          label: 'Telegram channel',
          url: 'https://t.me/unicarom',
          iconName: 'telegram',
        ),
        _RomLink(
          label: 'GitHub repository',
          url: 'https://github.com/salvogiangri/UN1CA',
          iconName: 'github',
        ),
        _RomLink(
          label: 'Discussions',
          url: 'https://github.com/salvogiangri/UN1CA/discussions',
          iconName: 'forum',
        ),
      ],
    ),
    _RomSpec(
      id: 'artisanrom',
      name: 'ArtisanROM Quant',
      headerAsset: 'images/artisanrom.png',
      shortTagline:
          'OneUI 8 custom firmware for Exynos Galaxy S10, S20 and Note20 devices.',
      description: <String>[
        'ArtisanROM Quant is a work-in-progress custom firmware for Samsung Galaxy devices, built on the latest stable One UI 8 Galaxy S25 FE firmware. It targets older Exynos hardware: the Exynos 990 (S20 / Note20 series) and Exynos 9820 (S10 series), bringing modern Samsung software to phones that Samsung itself has stopped updating.',
        'It is built on top of the ExtremeROM and UN1CA build system, automating firmware download, extraction, patching, and flashable zip generation. The project is GPL-3.0, maintained by Android-Artisan with a long list of contributors, and ships fully upstreamed kernels for every officially supported device.',
      ],
      features: <String>[
        'Based on the latest stable One UI 8 Galaxy S25 FE firmware.',
        'S25 Ultra CSC, ringtones, and most S25 FE software features ported over.',
        'Full Galaxy AI support including Now Brief, Super HDR, and adaptive color tone.',
        'Fully upstreamed kernels for every officially supported device.',
        'Moderately debloated and heavily DeKnoxed while keeping full SELinux enforcing.',
        'EROFS partitions, BluetoothLibraryPatcher, and KnoxPatch integrated.',
        'Extra mods (Disable Secure Flag, OutDoor mode) and CSC tweaks (call recording, network speed indicator, 5GHz hotspot).',
        'Multi-user, AppLock, adaptive brightness and refresh rate support.',
      ],
      // Official ArtisanROM screenshots provided by the maintainer.
      // Bundled locally because the upstream host blocks hot-linking.
      screenshots: <String>[
        'images/screenshots/artisanrom/01_settings.jpg',
        'images/screenshots/artisanrom/02_settings.jpg',
        'images/screenshots/artisanrom/03_settings.jpg',
        'images/screenshots/artisanrom/04_settings.jpg',
        'images/screenshots/artisanrom/05_updater.jpg',
        'images/screenshots/artisanrom/06_updater.jpg',
        'images/screenshots/artisanrom/07_updater.jpg',
        'images/screenshots/artisanrom/08_updater.jpg',
        'images/screenshots/artisanrom/09_updater.jpg',
        'images/screenshots/artisanrom/10_updater.jpg',
        'images/screenshots/artisanrom/11_package_installer.jpg',
      ],
      downloadLabel: 'GitHub releases',
      downloadUrl: 'https://github.com/ArtisanROM/ArtisanROM/releases',
      forumUrl: 'https://github.com/ArtisanROM/ArtisanROM/wiki',
      links: <_RomLink>[
        _RomLink(
          label: 'GitHub repository',
          url: 'https://github.com/ArtisanROM/ArtisanROM',
          iconName: 'github',
        ),
        _RomLink(
          label: 'Wiki',
          url: 'https://github.com/ArtisanROM/ArtisanROM/wiki',
          iconName: 'forum',
        ),
        _RomLink(
          label: 'Changelog',
          url:
              'https://github.com/ArtisanROM/ArtisanROM/blob/sixteen/CHANGELOG.md',
          iconName: 'web',
        ),
        _RomLink(
          label: 'Exynos 990 kernel sources',
          url:
              'https://github.com/Android-Artisan/android_kernel_samsung_exynos990',
          iconName: 'github',
        ),
      ],
    ),
    _RomSpec(
      id: 'lineagee3q',
      name: 'LineageOS for S24 Ultra (Unofficial)',
      headerAsset: 'images/lineageos.png',
      unofficial: true,
      shortTagline:
          'Community-built unofficial LineageOS for the Snapdragon Galaxy S24 Ultra.',
      description: <String>[
        'Unofficial LineageOS builds for the Galaxy S24 Ultra (e3q), maintained by XDA developer josip-k under the Exynoobs project. The S24 Ultra has no official LineageOS support, so this community port is the way to run AOSP-style Android on the device.',
        'Builds are published on the Exynoobs OTA page together with step-by-step install instructions, and the device tree, common tree, and kernel sources are developed in the open on GitHub. Current builds track LineageOS 23.2 and require the stock S928BXXS4BYH2 firmware as a base.',
      ],
      features: <String>[
        'LineageOS 23.2 for a device with no official LineageOS support.',
        'Dedicated OTA page with builds, changelogs, and install instructions.',
        'Device, common, and kernel sources published on GitHub.',
        'MindTheGapps support for Google apps.',
        'Active XDA thread with changelogs and developer support.',
      ],
      // Reuses the official lineageos.org press shots (the build ships the
      // same stock LineageOS UI), shuffled so the gallery does not mirror
      // the official LineageOS entry one-for-one.
      screenshots: <String>[
        'https://lineageos.org/images/2024-02-14/jelly.webp',
        'https://lineageos.org/images/2024-12-31/twelve.webp',
        'https://lineageos.org/images/2025-10-11/hero.webp',
        'https://lineageos.org/images/2024-02-14/calculator.webp',
        'https://lineageos.org/images/2022-12-31/aperture.webp',
        'https://lineageos.org/images/2024-02-14/dialer.webp',
        'https://lineageos.org/images/2025-10-11/catapult.webp',
        'https://lineageos.org/images/2024-02-14/glimpse.webp',
      ],
      downloadLabel: 'Builds & install guide',
      downloadUrl: 'https://exynoobs.github.io/OTA/devices/e3q.html',
      forumUrl:
          'https://xdaforums.com/t/rom-unofficial-lineageos-23-2-for-galaxy-s24-ultra.4779036/',
      warning:
          'Unofficial community build by a single maintainer; not endorsed by the LineageOS project. VoLTE is currently not working, and flashing requires the stock S928BXXS4BYH2 firmware base. Read the install instructions carefully.',
      links: <_RomLink>[
        _RomLink(
          label: 'Install instructions',
          url: 'https://exynoobs.github.io/OTA/devices/e3q-install.html',
          iconName: 'web',
        ),
        _RomLink(
          label: 'Device sources',
          url: 'https://github.com/Exynoobs/android_device_samsung_e3q',
          iconName: 'github',
        ),
        _RomLink(
          label: 'Kernel sources',
          url: 'https://github.com/Exynoobs/android_kernel_samsung_sm8650',
          iconName: 'github',
        ),
      ],
    ),
    _RomSpec(
      id: 'drketan',
      name: 'Dr.Ketan ROM',
      headerAsset: 'images/samsung.png',
      shortTagline:
          'Stock-based One UI custom ROM with root-friendly extras for the Galaxy S24 Ultra (S928B).',
      description: <String>[
        'Dr.Ketan ROM is a long-running stock-based custom ROM line by XDA Recognized Developer dr.ketan, here built for the Snapdragon Galaxy S24 Ultra (SM-S928B/DS). It keeps the full One UI experience while adding root-friendly conveniences on top of Samsung firmware.',
        'The ROM ships as an Odin-flashable full package with One UI 7.0 and One UI 8.5 bases, a system-RW F2FS layout, and the bundled ROM Tool app for applying tweaks like the S Health root patch, font installation, and navigation bar gesture-hint toggles.',
      ],
      features: <String>[
        'Full stock One UI experience with One UI 7.0 and One UI 8.5 bases.',
        'Odin-flashable full ROM packages.',
        'System-RW with F2FS for a writable system partition.',
        'ROM Tool app: S Health patch for rooted devices, font install, NavBar gesture hint toggle, and more.',
        'Maintained by a veteran XDA Recognized Developer with a long history of Samsung flagship ROMs.',
      ],
      screenshots: <String>[],
      downloadLabel: 'XDA thread (downloads)',
      downloadUrl:
          'https://xdaforums.com/t/12-02-26-dr-ketan-rom-i-oneui-7-0-i-oneui-8-5-i-full-rom-system-rw-f2fs-for-s928b.4652891/',
      forumUrl:
          'https://xdaforums.com/t/12-02-26-dr-ketan-rom-i-oneui-7-0-i-oneui-8-5-i-full-rom-system-rw-f2fs-for-s928b.4652891/',
      warning:
          'Distributed and supported through its XDA thread. Built strictly for the Snapdragon Galaxy S24 Ultra (SM-S928B/DS); do not flash it on any other model.',
    ),
  ];

  return specs.map((_RomSpec s) {
    final _Policy policy = _policyFor(s.id);
    final List<_Device> matched;
    if (s.id == 'pixelos') {
      matched = pixelosDevices;
    } else if (s.id == 'infinityx') {
      matched = infinityxDevices;
    } else if (s.id == 'artisanrom') {
      // The maintainer supports the Exynos 990 Galaxy Note20 series, but the
      // LineageOS wiki (our device pool) carries no Note20 entry, so the
      // allowlist policy alone cannot surface them. Inject them explicitly
      // and union with whatever the policy matches from the wiki pool.
      final List<_Device> policyMatched = all.where(policy).toList();
      final Set<String> seen =
          policyMatched.map((_Device d) => d.codename).toSet();
      matched = <_Device>[
        ...policyMatched,
        for (final _Device d in _artisanExtraDevices)
          if (!seen.contains(d.codename)) d,
      ];
    } else if (s.id == 'un1ca') {
      // UN1CA's One UI ports are mostly absent from the LineageOS wiki, so
      // inject the full official device list and union with anything the
      // allowlist policy happens to match from the wiki pool.
      final List<_Device> policyMatched = all.where(policy).toList();
      final Set<String> seen =
          policyMatched.map((_Device d) => d.codename).toSet();
      matched = <_Device>[
        ...policyMatched,
        for (final _Device d in _un1caExtraDevices)
          if (!seen.contains(d.codename)) d,
      ];
    } else if (s.id == 'lineagee3q' || s.id == 'drketan') {
      // Community builds for the Galaxy S24 Ultra, which has no LineageOS
      // wiki entry; the device is injected by hand.
      matched = _e3qExtraDevices;
    } else {
      matched = all.where(policy).toList();
    }
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
      if (s.warning != null) 'warning': s.warning,
      if (s.unofficial) 'unofficial': true,
      if (s.links.isNotEmpty)
        'links': s.links.map((_RomLink l) => l.toJson()).toList(),
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
      links: <_RomLink>[
        _RomLink(
          label: 'Website',
          url: 'https://twrp.me/',
          iconName: 'web',
        ),
        _RomLink(
          label: 'GitHub',
          url: 'https://github.com/TeamWin',
          iconName: 'github',
        ),
      ],
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
      // Sourced from the official OrangeFox wiki (the "recovery without touch"
      // guide), which is currently the only place that publishes hot-linkable
      // screenshots of the recovery UI.
      screenshots: <String>[
        'https://wiki.orangefox.tech/hw_nav.png',
        'https://wiki.orangefox.tech/hwgui/screenshot_2025-04-04-22-49-37.png',
        'https://wiki.orangefox.tech/hwgui/screenshot_2025-04-04-23-07-19.png',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://orangefox.download/',
      links: <_RomLink>[
        _RomLink(
          label: 'Website',
          url: 'https://orangefox.download/',
          iconName: 'web',
        ),
        _RomLink(
          label: 'Wiki',
          url: 'https://wiki.orangefox.tech/',
          iconName: 'web',
        ),
      ],
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
      // Hero and feature artwork from the official RedWolf site
      // (redwolfrecovery.github.io). The project does not publish a separate
      // screenshot gallery, so these are the official marketing visuals.
      screenshots: <String>[
        'https://redwolfrecovery.github.io/assets/images/home-image-620x365.png',
        'https://redwolfrecovery.github.io/assets/images/slider-img-4-620x365.png',
        'https://redwolfrecovery.github.io/assets/images/feature-banners-1-300x300.png',
        'https://redwolfrecovery.github.io/assets/images/feature-banners-4-300x300.png',
        'https://redwolfrecovery.github.io/assets/images/feature-banners-7-300x300.png',
        'https://redwolfrecovery.github.io/assets/images/feature-banners-8-300x300.png',
        'https://redwolfrecovery.github.io/assets/images/feature-banners-9-300x300.png',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://forum.xda-developers.com/c/redwolf-recovery.10018/',
      links: <_RomLink>[
        _RomLink(
          label: 'Website',
          url: 'https://redwolfrecovery.github.io/',
          iconName: 'web',
        ),
      ],
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
      // Original PBRP carousel + recovery shots, served from the
      // Internet Archive (2023 snapshot of pitchblackrecovery.com).
      screenshots: <String>[
        'https://web.archive.org/web/20231226225027im_/https://pitchblackrecovery.com/wp-content/uploads/elementor/thumbs/Final_Home-1-phsp7ogz6aai0fx2y7iqx6qevr5qvewi1ejcxmwb2a.png',
        'https://web.archive.org/web/20231226225027im_/https://pitchblackrecovery.com/wp-content/uploads/2020/07/Screenshot_PBRP_2020-07-26-01-31-02-1-576x1024.png',
        'https://web.archive.org/web/20231226225027im_/https://pitchblackrecovery.com/wp-content/uploads/2020/07/Screenshot_PBRP_2020-07-26-01-31-05-1-576x1024.png',
        'https://web.archive.org/web/20231226225027im_/https://pitchblackrecovery.com/wp-content/uploads/2020/07/Screenshot_PBRP_2020-07-26-01-31-07-576x1024.png',
        'https://web.archive.org/web/20231226225027im_/https://pitchblackrecovery.com/wp-content/uploads/2020/07/Screenshot_PBRP_2020-07-26-01-31-15-576x1024.png',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://pitchblack.tech/',
      links: <_RomLink>[
        _RomLink(
          label: 'Website',
          url: 'https://pitchblack.tech/',
          iconName: 'web',
        ),
        _RomLink(
          label: 'GitHub',
          url: 'https://github.com/PitchBlackRecoveryProject',
          iconName: 'github',
        ),
      ],
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
      // The official SHRP recovery UI screenshots, served straight from the
      // SourceForge project page (sourceforge.net/projects/shrp). The earlier
      // shrp.dev URL was an unrelated personal site.
      screenshots: <String>[
        'https://a.fsdn.com/con/app/proj/shrp/screenshots/1.jpg/max/max/1',
        'https://a.fsdn.com/con/app/proj/shrp/screenshots/2.jpg/max/max/1',
        'https://a.fsdn.com/con/app/proj/shrp/screenshots/3.jpg/max/max/1',
        'https://a.fsdn.com/con/app/proj/shrp/screenshots/4.jpg/max/max/1',
      ],
      downloadLabel: 'Official downloads',
      downloadUrl: 'https://shrp.github.io/',
      links: <_RomLink>[
        _RomLink(
          label: 'Website',
          url: 'https://shrp.github.io/',
          iconName: 'web',
        ),
        _RomLink(
          label: 'GitHub',
          url: 'https://github.com/SHRP',
          iconName: 'github',
        ),
      ],
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
      if (s.links.isNotEmpty)
        'links': s.links.map((_RomLink l) => l.toJson()).toList(),
    };
  }).toList();
}

/// Root solutions are device-agnostic (they target kernels / boot images,
/// not specific phones), so they don't run through `_policyFor` and ship
/// with an empty `devices` list. The `links` field surfaces the upstream
/// Telegram/Discord/docs channels that root projects rely on.
List<Map<String, dynamic>> _buildRoots() {
  final List<_RomSpec> specs = <_RomSpec>[
    _RomSpec(
      id: 'magisk',
      name: 'Magisk',
      headerAsset: 'images/magisk.png',
      shortTagline:
          'The original systemless root: boot-image patching, modules, and Zygisk.',
      description: <String>[
        'Magisk is the most widely adopted root solution for Android. It patches the boot image to inject a small init shim that mounts a writable overlay over /system, giving root and module support without modifying real partitions.',
        'The module system lets the community ship systemless tweaks (audio mods, hosts blockers, font packs) that can be enabled/disabled at runtime. Zygisk runs code inside every app process, which third-party modules like LSPosed use to hook frameworks.',
      ],
      features: <String>[
        'Systemless root via boot-image patching.',
        'Module ecosystem with hundreds of community modules.',
        'Per-app root permission management with logging.',
        'Zygisk runtime code injection into the Zygote.',
        'MagiskBoot tool for unpacking/repacking boot.img.',
        'DenyList to hide modifications from selected apps.',
        'Supports Android 6.0 through current releases.',
      ],
      screenshots: <String>[
        // From the official Magisk repo's docs/images. The project does not
        // publish a dedicated screenshot gallery; these are the in-app shots
        // embedded in the installation / OTA guides and are the most
        // UI-representative hot-linkable assets the upstream provides.
        'https://raw.githubusercontent.com/topjohnwu/Magisk/master/docs/images/device_info.png',
        'https://raw.githubusercontent.com/topjohnwu/Magisk/master/docs/images/manager_reboot.png',
        'https://raw.githubusercontent.com/topjohnwu/Magisk/master/docs/images/install_inactive_slot.png',
        'https://raw.githubusercontent.com/topjohnwu/Magisk/master/docs/images/restore_img.png',
      ],
      downloadLabel: 'GitHub Releases',
      downloadUrl: 'https://github.com/topjohnwu/Magisk/releases',
      forumUrl: 'https://forum.xda-developers.com/t/3473445/',
      links: <_RomLink>[
        _RomLink(
          label: 'Documentation',
          url: 'https://topjohnwu.github.io/Magisk/',
          iconName: 'web',
        ),
        _RomLink(
          label: 'GitHub',
          url: 'https://github.com/topjohnwu/Magisk',
          iconName: 'github',
        ),
      ],
    ),
    _RomSpec(
      id: 'kernelsu',
      name: 'KernelSU',
      headerAsset: 'images/kernelsu.png',
      shortTagline:
          'Kernel-space root for GKI 2.0 devices, with per-app profiles and modules.',
      description: <String>[
        'KernelSU moves the root provider into the Linux kernel itself, which makes it harder to detect and removes the need to patch boot images on most modern devices.',
        'Officially targets GKI 2.0 (kernel 5.10+); older non-GKI kernels (4.14+) can be supported by rebuilding the kernel with the KernelSU patches.',
      ],
      features: <String>[
        'Kernel-based `su` implementation.',
        'App Profile: per-app root, UID, group, capability and SELinux rules.',
        'Module system inspired by Magisk (OverlayFS-based).',
        'Works on WSA, ChromeOS Android subsystem and containers.',
        'Open source, GPL-2 kernel parts + GPL-3 userspace.',
      ],
      screenshots: <String>[],
      downloadLabel: 'GitHub Releases',
      downloadUrl: 'https://github.com/tiann/KernelSU/releases',
      forumUrl: 'https://github.com/tiann/KernelSU/discussions',
      warning:
          'Requires a kernel built with KernelSU patches. For most devices that means flashing a compatible custom kernel (or using GKI on supported Pixel/Samsung models). Recent kernel changes have broken x86_64 builds in some configurations.',
      links: <_RomLink>[
        _RomLink(
          label: 'Documentation',
          url: 'https://kernelsu.org/',
          iconName: 'web',
        ),
        _RomLink(
          label: 'GitHub',
          url: 'https://github.com/tiann/KernelSU',
          iconName: 'github',
        ),
      ],
    ),
    _RomSpec(
      id: 'kernelsu_next',
      name: 'KernelSU Next',
      headerAsset: 'images/kernelsu_next.png',
      shortTagline:
          'Actively maintained KernelSU fork with broader non-GKI support and Magic Mount.',
      description: <String>[
        'KernelSU Next is a community fork of KernelSU that adds Magic Mount (from MKSU) alongside the original OverlayFS mounter, with a toggle to switch between them. It targets devices the upstream project does not officially support, especially older non-GKI kernels.',
        'Stays close to upstream while adding QoL features: module backup and restore, an auto-updating manager app, and tighter SuSFS integration.',
      ],
      features: <String>[
        'Magic Mount or OverlayFS, switchable at runtime.',
        'Supports non-GKI kernels from 4.4 up to 6.6.',
        'Module backup / restore from the manager app.',
        'SuSFS integration for hiding modifications.',
        'Bulk module install and auto-update manager.',
      ],
      screenshots: <String>[],
      downloadLabel: 'GitHub Releases',
      downloadUrl: 'https://github.com/KernelSU-Next/KernelSU-Next/releases',
      forumUrl:
          'https://github.com/KernelSU-Next/KernelSU-Next/discussions',
      warning:
          'Community fork: synced with upstream but maintains its own patches. Still requires a custom kernel built with the KernelSU Next sources.',
      links: <_RomLink>[
        _RomLink(
          label: 'Documentation',
          url: 'https://kernelsu-next.github.io/webpage/',
          iconName: 'web',
        ),
        _RomLink(
          label: 'GitHub',
          url: 'https://github.com/KernelSU-Next/KernelSU-Next',
          iconName: 'github',
        ),
      ],
    ),
    _RomSpec(
      id: 'apatch',
      name: 'APatch',
      headerAsset: 'images/apatch.png',
      shortTagline:
          'KernelPatch-based root that hooks the running kernel without recompiling it.',
      description: <String>[
        'APatch builds on KernelPatch, a runtime kernel-patching framework. Instead of requiring a custom kernel like KernelSU, it injects inline hooks into the live kernel image, so it can run on devices whose vendor kernel is otherwise locked.',
        'Supports both APModule (Magisk-style systemless modules) and KPModule (in-kernel patch modules) for low-level extensions.',
      ],
      features: <String>[
        'Runtime kernel patching via KernelPatch.',
        'APModule (userspace) + KPModule (kernel) support.',
        'Inline-hook and syscall-table-hook backends.',
        'Module system derived from KernelSU.',
        'SELinux policy management via magiskpolicy.',
        'Targets kernels 3.18 through 6.12 on ARM64.',
      ],
      screenshots: <String>[],
      downloadLabel: 'GitHub Releases',
      downloadUrl: 'https://github.com/bmax121/APatch/releases',
      forumUrl: 'https://github.com/bmax121/APatch/discussions',
      warning:
          'ARM64 only. APatch uses a SuperKey that has higher privileges than root: a weak or leaked SuperKey can take full control of the device, so treat it like a master password. Requires CONFIG_KALLSYMS in the kernel.',
      links: <_RomLink>[
        _RomLink(
          label: 'Documentation',
          url: 'https://apatch.dev/',
          iconName: 'web',
        ),
        _RomLink(
          label: 'GitHub',
          url: 'https://github.com/bmax121/APatch',
          iconName: 'github',
        ),
        _RomLink(
          label: 'Telegram',
          url: 'https://t.me/APatchChannel',
          iconName: 'telegram',
        ),
      ],
    ),
    _RomSpec(
      id: 'sukisu',
      name: 'SukiSU Ultra',
      headerAsset: 'images/sukisu.png',
      shortTagline:
          'KernelSU fork that bundles KernelPatch Module (KPM) support and Magic Mount.',
      description: <String>[
        'SukiSU Ultra is an actively developed fork of KernelSU that integrates KernelPatch Module (KPM) support so users get both KernelSU-style modules and APatch-style in-kernel patches from a single project.',
        'Ships with WebUI X for module management, Magic Mount for system overlays, and broader non-GKI coverage than upstream KernelSU.',
      ],
      features: <String>[
        'Kernel-based `su` with per-app profiles.',
        'KPM (KernelPatch Module) support.',
        'Magic Mount for system-level overlays.',
        'WebUI X management interface.',
        'SuSFS integration and theming controls.',
        'Non-GKI 4.x-5.4 LTS + GKI 5.10+ support.',
      ],
      screenshots: <String>[],
      downloadLabel: 'GitHub Releases',
      downloadUrl: 'https://github.com/SukiSU-Ultra/SukiSU-Ultra/releases',
      forumUrl:
          'https://github.com/SukiSU-Ultra/SukiSU-Ultra/discussions',
      warning:
          'Community fork of KernelSU. KPM support needs CONFIG_KPM=y in the kernel and may require backports on older kernels. Inherits KernelSU compatibility caveats on x86_64.',
      links: <_RomLink>[
        _RomLink(
          label: 'Documentation',
          url: 'https://sukisu.org/',
          iconName: 'web',
        ),
        _RomLink(
          label: 'GitHub',
          url: 'https://github.com/SukiSU-Ultra/SukiSU-Ultra',
          iconName: 'github',
        ),
        _RomLink(
          label: 'Telegram',
          url: 'https://t.me/Sukiksu',
          iconName: 'telegram',
        ),
      ],
    ),
  ];

  return specs.map((_RomSpec s) {
    return <String, dynamic>{
      'id': s.id,
      'name': s.name,
      'headerAsset': s.headerAsset,
      'shortTagline': s.shortTagline,
      'description': s.description,
      'features': s.features,
      'screenshots': s.screenshots,
      'devices': const <Map<String, dynamic>>[],
      'downloadLabel': s.downloadLabel,
      'downloadUrl': s.downloadUrl,
      'forumUrl': s.forumUrl ?? _xdaSearchUrl(s.name),
      if (s.warning != null) 'warning': s.warning,
      if (s.links.isNotEmpty)
        'links': s.links.map((_RomLink l) => l.toJson()).toList(),
    };
  }).toList();
}

List<Map<String, dynamic>> _buildDevices(List<String> vendors) {
  // Per-vendor hero photo. For vendors without a tailored asset we fall back
  // to the generic branding placeholder, but the runtime catalog should
  // ensure every shipped vendor has an entry here.
  const Map<String, String> assetMap = <String, String>{
    '10.or': 'images/device_10or.png',
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

/// Minimal codename/model pair used to inject ROM-specific devices that the
/// upstream device pools do not carry (e.g. ArtisanROM's Galaxy Note20).
class _DeviceSeed {
  const _DeviceSeed(this.codename, this.model, [this.releaseYear]);

  final String codename;
  final String model;
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
    this.warning,
    this.links = const <_RomLink>[],
    this.unofficial = false,
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

  /// Optional prominent warning rendered above the description on the ROM
  /// detail page. Use for credibility concerns, community controversies,
  /// or projects on hiatus that still ship downloadable builds.
  final String? warning;

  /// Optional curated external links shown as clickable chips between the
  /// description and Key Features. Use for project Telegram channels,
  /// GitHub orgs, per-device builds pages, etc.
  final List<_RomLink> links;

  /// True for community-maintained builds published by independent
  /// developers (usually via XDA) rather than an official project. The
  /// client groups these under a separate "Unofficial builds" section.
  final bool unofficial;
}

class _RomLink {
  const _RomLink({required this.label, required this.url, this.iconName = ''});
  final String label;
  final String url;

  /// One of: 'telegram', 'github', 'discord', 'matrix', 'forum', 'web'.
  /// Empty falls back to a generic link icon on the client.
  final String iconName;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'label': label,
        'url': url,
        if (iconName.isNotEmpty) 'iconName': iconName,
      };
}

/// Deterministic XDA search URL for [name]. Used as a fallback whenever a
/// project does not have a curated forum link, so the in-app Discussion
/// button is never broken.
String _xdaSearchUrl(String name) {
  final String q = Uri.encodeQueryComponent(name);
  return 'https://forum.xda-developers.com/search/?q=$q'
      '&o=date&c[content]=thread';
}
