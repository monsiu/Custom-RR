// Build-freshness snapshot generator.
//
//   dart run tool/sync_freshness.dart            # network + curated fallback
//   dart run tool/sync_freshness.dart --offline  # curated only, no HTTP
//
// Produces `assets/freshness.json` with one record per ROM/recovery id.
// Each record carries:
//   - status:     'active' | 'stale' | 'abandoned' | 'unknown'
//   - lastBuild:  ISO-8601 date of the most recent official build we know of
//   - daysAgo:    integer days between lastBuild and run time (UTC)
//   - version:    short human label ("Android 15 QPR2", "v14.2", ...)
//   - source:     URL the date was sourced from (so the UI can link to it)
//   - origin:     'network' | 'curated' — where the date actually came from
//
// Curated seeds are the source of truth when the network is unavailable
// (offline CI, GitHub outage, etc.). Each id can optionally register a
// `_NetFetcher` that tries to pull a fresher date from upstream; on any
// timeout / parse error / HTTP error we silently keep the curated value.
//
// Adding a network source for a new project: write a top-level async
// function that returns a `_NetResult?`, then put it in `_netFetchers`.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

const String _outPath = 'assets/freshness.json';
const Duration _httpTimeout = Duration(seconds: 6);

Future<void> main(List<String> args) async {
  final bool offline = args.contains('--offline');
  // Today's date used to compute days-since for the static seed values.
  final DateTime now = DateTime.now().toUtc();

  final Map<String, _Seed> seeds = <String, _Seed>{
    // ROMs
    'lineage': _Seed(
      lastBuild: DateTime.utc(2026, 5, 12),
      version: 'LineageOS 22.1 (Android 15)',
      source: 'https://download.lineageos.org/',
    ),
    'crdroid': _Seed(
      lastBuild: DateTime.utc(2026, 5, 7),
      version: 'crDroid 11.5 (Android 15)',
      source: 'https://crdroid.net/',
    ),
    'pixelexperience': _Seed(
      lastBuild: DateTime.utc(2025, 9, 1),
      version: 'PE 14 Plus',
      source: 'https://download.pixelexperience.org/',
    ),
    'evolutionx': _Seed(
      lastBuild: DateTime.utc(2026, 4, 28),
      version: 'Evolution X 10 (Android 15)',
      source: 'https://evolution-x.org/',
    ),
    'paranoidandroid': _Seed(
      lastBuild: DateTime.utc(2025, 1, 15),
      version: 'Topaz (Android 14 QPR2)',
      source: 'https://paranoidandroid.co/',
    ),
    'dotos': _Seed(
      lastBuild: DateTime.utc(2023, 8, 1),
      version: 'DotOS 6.1 (Android 13)',
      source: 'https://www.droidontime.com/',
    ),
    'bliss': _Seed(
      lastBuild: DateTime.utc(2026, 3, 18),
      version: 'Bliss 18 (Android 15)',
      source: 'https://blissroms.org/',
    ),
    'risingosrevived': _Seed(
      lastBuild: DateTime.utc(2026, 5, 16),
      version: 'RisingOS Revived (Android 15)',
      source: 'https://sourceforge.net/projects/risingos-revived/',
    ),
    'voltage': _Seed(
      lastBuild: DateTime.utc(2026, 4, 30),
      version: 'Voltage 4 (Android 15)',
      source: 'https://voltageos.com/',
    ),
    'projectelixir': _Seed(
      lastBuild: DateTime.utc(2026, 5, 10),
      version: 'Elixir 4 (Android 15)',
      source: 'https://projectelixiros.com/',
    ),
    'pixelos': _Seed(
      lastBuild: DateTime.utc(2026, 5, 12),
      version: 'PixelOS 15 (Android 15)',
      source: 'https://pixelos.net/',
    ),
    'grapheneos': _Seed(
      lastBuild: DateTime.utc(2026, 5, 20),
      version: '2026052000',
      source: 'https://grapheneos.org/releases',
    ),
    'calyxos': _Seed(
      lastBuild: DateTime.utc(2026, 5, 14),
      version: 'CalyxOS 6.x (Android 15)',
      source: 'https://calyxos.org/news/',
    ),
    'eos': _Seed(
      lastBuild: DateTime.utc(2026, 5, 6),
      version: '/e/OS 2.9 (R/S/T/U branches)',
      source: 'https://doc.e.foundation/devices',
    ),
    'divestos': _Seed(
      lastBuild: DateTime.utc(2026, 5, 11),
      version: 'DivestOS 22.1 (Android 15)',
      source: 'https://divestos.org/pages/devices',
    ),
    'derpfest': _Seed(
      lastBuild: DateTime.utc(2026, 5, 9),
      version: 'DerpFest 15 (Android 15)',
      source: 'https://projectderp.in/',
    ),
    'un1ca': _Seed(
      lastBuild: DateTime.utc(2026, 4, 1),
      version: 'UN1CA 3.0.7',
      source: 'https://github.com/salvogiangri/UN1CA/releases',
    ),
    'artisanrom': _Seed(
      lastBuild: DateTime.utc(2026, 5, 15),
      version: 'ArtisanROM Quant v3.1.1',
      source: 'https://github.com/ArtisanROM/ArtisanROM/releases',
    ),

    // Root solutions
    'magisk': _Seed(
      lastBuild: DateTime.utc(2026, 2, 23),
      version: 'Magisk v30.7',
      source: 'https://github.com/topjohnwu/Magisk/releases',
    ),
    'kernelsu': _Seed(
      lastBuild: DateTime.utc(2026, 4, 6),
      version: 'KernelSU v3.2.4',
      source: 'https://github.com/tiann/KernelSU/releases',
    ),
    'kernelsu_next': _Seed(
      lastBuild: DateTime.utc(2026, 4, 15),
      version: 'KernelSU Next v3.2.0',
      source: 'https://github.com/KernelSU-Next/KernelSU-Next/releases',
    ),
    'apatch': _Seed(
      lastBuild: DateTime.utc(2025, 11, 12),
      version: 'APatch 11142',
      source: 'https://github.com/bmax121/APatch/releases',
    ),
    'sukisu': _Seed(
      lastBuild: DateTime.utc(2026, 5, 28),
      version: 'SukiSU Ultra v4.1.3',
      source: 'https://github.com/SukiSU-Ultra/SukiSU-Ultra/releases',
    ),

    // Recoveries
    'twrp': _Seed(
      lastBuild: DateTime.utc(2024, 11, 2),
      version: 'TWRP 3.7.1',
      source: 'https://twrp.me/Devices/',
    ),
    'orangefox': _Seed(
      lastBuild: DateTime.utc(2026, 4, 25),
      version: 'OrangeFox R12.1',
      source: 'https://orangefox.download/',
    ),
    'redwolf': _Seed(
      lastBuild: DateTime.utc(2021, 7, 1),
      version: 'RedWolf 3.x',
      source: 'https://forum.xda-developers.com/c/redwolf-recovery.10018/',
    ),
    'pitchblack': _Seed(
      lastBuild: DateTime.utc(2024, 2, 14),
      version: 'PBRP 3.7.x',
      source: 'https://pitchblack.tech/',
    ),
    'shrp': _Seed(
      lastBuild: DateTime.utc(2023, 10, 1),
      version: 'SHRP 3.1',
      source: 'https://shrp.vercel.app/',
    ),
  };

  // Fire all network fetchers in parallel (if not --offline). Each entry
  // in `_netFetchers` returns a `_NetResult?`; null = bail, keep curated.
  final Map<String, _NetResult> netResults = <String, _NetResult>{};
  if (!offline) {
    final HttpClient client = HttpClient()
      ..userAgent = 'Custom-RR-FreshnessBot/1.0 (+https://github.com/monsiu/Custom-RR)'
      ..connectionTimeout = _httpTimeout;
    try {
      final List<MapEntry<String, Future<_NetResult?>>> jobs =
          <MapEntry<String, Future<_NetResult?>>>[
        for (final MapEntry<String, _NetFetcher> e in _netFetchers.entries)
          MapEntry<String, Future<_NetResult?>>(
            e.key,
            e.value(client).timeout(_httpTimeout, onTimeout: () => null),
          ),
      ];
      for (final MapEntry<String, Future<_NetResult?>> j in jobs) {
        try {
          final _NetResult? r = await j.value;
          if (r != null) {
            netResults[j.key] = r;
            stdout.writeln('[freshness] net OK    ${j.key}  '
                '${_isoDate(r.lastBuild)}  ${r.version}');
          } else {
            stdout.writeln('[freshness] net SKIP  ${j.key}  (no data)');
          }
        } on Object catch (err) {
          stdout.writeln('[freshness] net FAIL  ${j.key}  $err');
        }
      }
    } finally {
      client.close(force: true);
    }
  } else {
    stdout.writeln('[freshness] --offline: skipping network');
  }

  final Map<String, dynamic> entries = <String, dynamic>{};
  int netCount = 0;
  int curatedCount = 0;
  for (final MapEntry<String, _Seed> e in seeds.entries) {
    final _NetResult? net = netResults[e.key];
    final DateTime lastBuild = net?.lastBuild ?? e.value.lastBuild;
    final String version = net?.version ?? e.value.version;
    final String source = net?.source ?? e.value.source;
    final String origin = net != null ? 'network' : 'curated';
    if (net != null) {
      netCount++;
    } else {
      curatedCount++;
    }
    final int days = now.difference(lastBuild).inDays;
    entries[e.key] = <String, dynamic>{
      'status': _statusFor(days),
      'lastBuild': _isoDate(lastBuild),
      'daysAgo': days,
      'version': version,
      'source': source,
      'origin': origin,
    };
  }

  final Map<String, dynamic> root = <String, dynamic>{
    '_generated': 'tool/sync_freshness.dart',
    '_generatedAt': now.toIso8601String(),
    '_netCount': netCount,
    '_curatedCount': curatedCount,
    'entries': entries,
  };

  const JsonEncoder pretty = JsonEncoder.withIndent('  ');
  File(_outPath).writeAsStringSync('${pretty.convert(root)}\n');
  stdout.writeln('[freshness] wrote $_outPath  '
      '($netCount network / $curatedCount curated, ${entries.length} total)');
}

// ---------------------------------------------------------------------------
// Network fetchers
// ---------------------------------------------------------------------------

typedef _NetFetcher = Future<_NetResult?> Function(HttpClient client);

/// Register one fetcher per id you want to refresh from upstream. Anything
/// not in this map keeps the curated value (origin='curated'). Anything in
/// here that throws / times out / returns null also falls back cleanly.
final Map<String, _NetFetcher> _netFetchers = <String, _NetFetcher>{
  'grapheneos': _fetchGrapheneOs,
  'lineage': _fetchLineage,
  'risingosrevived': _fetchRisingOsRevived,
  'un1ca': (HttpClient c) => _fetchGitHubReleaseLatest(
        c,
        owner: 'salvogiangri',
        repo: 'UN1CA',
        displayName: 'UN1CA',
      ),
  'artisanrom': (HttpClient c) => _fetchGitHubReleaseLatest(
        c,
        owner: 'ArtisanROM',
        repo: 'ArtisanROM',
        displayName: 'ArtisanROM Quant',
      ),
  'magisk': (HttpClient c) => _fetchGitHubReleaseLatest(
        c,
        owner: 'topjohnwu',
        repo: 'Magisk',
        displayName: 'Magisk',
      ),
  'kernelsu': (HttpClient c) => _fetchGitHubReleaseLatest(
        c,
        owner: 'tiann',
        repo: 'KernelSU',
        displayName: 'KernelSU',
      ),
  'kernelsu_next': (HttpClient c) => _fetchGitHubReleaseLatest(
        c,
        owner: 'KernelSU-Next',
        repo: 'KernelSU-Next',
        displayName: 'KernelSU Next',
      ),
  'apatch': (HttpClient c) => _fetchGitHubReleaseLatest(
        c,
        owner: 'bmax121',
        repo: 'APatch',
        displayName: 'APatch',
      ),
  'sukisu': (HttpClient c) => _fetchGitHubReleaseLatest(
        c,
        owner: 'SukiSU-Ultra',
        repo: 'SukiSU-Ultra',
        displayName: 'SukiSU Ultra',
      ),
};

/// GrapheneOS publishes a one-line stable-channel manifest per device at
/// `https://releases.grapheneos.org/{device}-stable`. The first whitespace
/// token is the build id (YYYYMMDDHH), the second is a unix timestamp.
Future<_NetResult?> _fetchGrapheneOs(HttpClient client) async {
  const String device = 'oriole'; // Pixel 6 — reliably maintained reference.
  final Uri url = Uri.parse('https://releases.grapheneos.org/$device-stable');
  final String body = await _httpGetText(client, url);
  final List<String> tokens = body.trim().split(RegExp(r'\s+'));
  if (tokens.length < 2) return null;
  final int? unix = int.tryParse(tokens[1]);
  if (unix == null) return null;
  final DateTime built =
      DateTime.fromMillisecondsSinceEpoch(unix * 1000, isUtc: true);
  return _NetResult(
    lastBuild: built,
    version: tokens[0],
    source: 'https://grapheneos.org/releases',
  );
}

/// LineageOS exposes a per-device JSON API. We sample a long-lived reference
/// device to gauge "latest official build shipped" for the project overall.
Future<_NetResult?> _fetchLineage(HttpClient client) async {
  const String device = 'oriole'; // Pixel 6 — official Lineage device.
  final Uri url = Uri.parse(
    'https://download.lineageos.org/api/v2/devices/$device/builds',
  );
  final String body = await _httpGetText(client, url);
  final dynamic decoded = json.decode(body);
  if (decoded is! List || decoded.isEmpty) return null;
  DateTime? newest;
  String? newestVersion;
  for (final dynamic item in decoded) {
    if (item is! Map) continue;
    final dynamic dt = item['datetime'];
    if (dt is! num) continue;
    final DateTime when =
        DateTime.fromMillisecondsSinceEpoch(dt.toInt() * 1000, isUtc: true);
    if (newest == null || when.isAfter(newest)) {
      newest = when;
      final dynamic v = item['version'];
      newestVersion = v is String ? v : null;
    }
  }
  if (newest == null) return null;
  return _NetResult(
    lastBuild: newest,
    version: newestVersion != null
        ? 'LineageOS $newestVersion'
        : 'LineageOS (latest)',
    source: 'https://download.lineageos.org/',
  );
}

/// GitHub Releases API: `repos/{owner}/{repo}/releases/latest` returns the
/// most recent non-draft, non-prerelease release as JSON. We use the
/// `published_at` timestamp as the build date and the `tag_name` (stripped
/// of a leading `v`) as the version suffix. Drafts and prereleases are
/// invisible to this endpoint, which is the same behaviour the in-app
/// UpdateChecker relies on.
Future<_NetResult?> _fetchGitHubReleaseLatest(
  HttpClient client, {
  required String owner,
  required String repo,
  required String displayName,
}) async {
  final Uri url =
      Uri.parse('https://api.github.com/repos/$owner/$repo/releases/latest');
  final String body = await _httpGetText(client, url);
  final dynamic decoded = json.decode(body);
  if (decoded is! Map) return null;
  final dynamic published = decoded['published_at'];
  final dynamic tag = decoded['tag_name'];
  if (published is! String || tag is! String) return null;
  final DateTime? when = DateTime.tryParse(published);
  if (when == null) return null;
  final String cleanTag =
      tag.startsWith('v') || tag.startsWith('V') ? tag.substring(1) : tag;
  return _NetResult(
    lastBuild: when.toUtc(),
    version: '$displayName $cleanTag',
    source: 'https://github.com/$owner/$repo/releases',
  );
}

Future<String> _httpGetText(HttpClient client, Uri url) async {
  final HttpClientRequest req = await client.getUrl(url);
  req.headers.set(HttpHeaders.acceptHeader, 'application/json, text/plain, */*');
  final HttpClientResponse resp = await req.close();
  if (resp.statusCode < 200 || resp.statusCode >= 300) {
    throw HttpException('HTTP ${resp.statusCode} for $url');
  }
  return utf8.decodeStream(resp);
}

/// SourceForge exposes a per-project RSS feed at
/// `https://sourceforge.net/projects/{slug}/rss?path=/` listing the most
/// recent files first. We take the newest `<pubDate>` as the project's
/// last build timestamp, and pull a version hint from the file path when
/// one is present (e.g. `.../v6.0/.../RisingOS-...-6.0-...zip`).
Future<_NetResult?> _fetchRisingOsRevived(HttpClient client) async {
  final Uri url = Uri.parse(
    'https://sourceforge.net/projects/risingos-revived/rss?path=/',
  );
  final String body = await _httpGetText(client, url);

  final RegExp itemRe =
      RegExp(r'<item>([\s\S]*?)</item>', caseSensitive: false);
  final RegExp pubDateRe =
      RegExp(r'<pubDate>([^<]+)</pubDate>', caseSensitive: false);
  // SourceForge wraps <title> in CDATA; capture either CDATA or plain text.
  final RegExp titleRe = RegExp(
    r'<title>\s*(?:<!\[CDATA\[([\s\S]*?)\]\]>|([^<]+))\s*</title>',
    caseSensitive: false,
  );

  DateTime? newest;
  String? newestTitle;
  for (final Match m in itemRe.allMatches(body)) {
    final String chunk = m.group(1) ?? '';
    final Match? dm = pubDateRe.firstMatch(chunk);
    if (dm == null) continue;
    // SourceForge emits e.g. "Wed, 31 Dec 2025 06:21:57 UT", which
    // HttpDate.parse rejects because the timezone token is "UT" rather
    // than "GMT" / "UTC" / a numeric offset. Normalise before parsing.
    final String raw = dm.group(1)!.trim().replaceFirst(
          RegExp(r'\s+UT$', caseSensitive: false),
          ' GMT',
        );
    DateTime? when;
    try {
      when = HttpDate.parse(raw);
    } on Object {
      continue;
    }
    if (newest == null || when.isAfter(newest)) {
      newest = when;
      final Match? tm = titleRe.firstMatch(chunk);
      newestTitle = (tm?.group(1) ?? tm?.group(2))?.trim();
    }
  }
  if (newest == null) return null;

  String version = 'RisingOS Revived (latest)';
  if (newestTitle != null) {
    final Match? vm = RegExp(r'(\d+\.\d+(?:\.\d+)?)').firstMatch(newestTitle);
    if (vm != null) version = 'RisingOS Revived ${vm.group(1)}';
  }
  return _NetResult(
    lastBuild: newest,
    version: version,
    source: 'https://sourceforge.net/projects/risingos-revived/',
  );
}

class _NetResult {
  const _NetResult({
    required this.lastBuild,
    required this.version,
    required this.source,
  });
  final DateTime lastBuild;
  final String version;
  final String source;
}

String _statusFor(int days) {
  if (days <= 60) return 'active';
  if (days <= 180) return 'stale';
  return 'abandoned';
}

String _isoDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

class _Seed {
  const _Seed({
    required this.lastBuild,
    required this.version,
    required this.source,
  });
  final DateTime lastBuild;
  final String version;
  final String source;
}
