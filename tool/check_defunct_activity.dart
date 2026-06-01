// Pings each ROM/recovery we have marked as defunct and looks for signs
// of life: a release or commit on a watched GitHub org newer than the
// known-last-build threshold.
//
//   dart run tool/check_defunct_activity.dart
//
// Designed to be run by CI on a schedule. Prints a human report and, when
// GITHUB_STEP_SUMMARY is set, also writes a Markdown summary there. The
// process exits 0 either way, but emits ::warning:: lines for each hit so
// they show up in the Actions UI; CI can grep the output and open an
// issue if it wants to.
//
// Notes:
//   - GitHub anonymous API is 60 req/h. Pass GITHUB_TOKEN via env to get
//     5000 req/h (the workflow already sets this).
//   - Only fork/template repos and obvious mirrors are ignored.
//   - Adding a new defunct project: append to `_watchlist`.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

const Duration _httpTimeout = Duration(seconds: 10);

class _Watch {
  _Watch({
    required this.id,
    required this.displayName,
    required this.thresholdUtc,
    this.githubOrgs = const <String>[],
    this.officialUrl = '',
  });

  /// Stable id (matches catalog/freshness keys when applicable).
  final String id;
  final String displayName;

  /// Treat any release/commit strictly newer than this date as activity.
  final DateTime thresholdUtc;

  /// GitHub orgs / users whose public repos we should sample.
  final List<String> githubOrgs;

  /// Project homepage, included in the report for convenience.
  final String officialUrl;
}

final List<_Watch> _watchlist = <_Watch>[
  _Watch(
    id: 'havoc',
    displayName: 'Havoc-OS',
    thresholdUtc: _utc(2023, 11, 3),
    githubOrgs: <String>['Havoc-OS'],
    officialUrl: 'https://havoc-os.com/',
  ),
  _Watch(
    id: 'aospextended',
    displayName: 'AOSP Extended',
    thresholdUtc: _utc(2022, 6, 26),
    githubOrgs: <String>['AOSPExtended'],
    officialUrl: 'https://www.aospextended.com/',
  ),
  _Watch(
    id: 'mokee',
    displayName: 'MoKee',
    thresholdUtc: _utc(2023, 9, 1),
    githubOrgs: <String>['MoKee'],
    officialUrl: 'https://www.mokeedev.com/',
  ),
  _Watch(
    id: 'resurrectionremix',
    displayName: 'Resurrection Remix',
    thresholdUtc: _utc(2021, 12, 31),
    githubOrgs: <String>['ResurrectionRemix-Ten'],
    officialUrl: 'https://resurrectionremix.com/',
  ),
  _Watch(
    id: 'dirtyunicorns',
    displayName: 'Dirty Unicorns',
    thresholdUtc: _utc(2021, 8, 5),
    githubOrgs: <String>['DirtyUnicorns'],
    officialUrl: 'https://www.dirtyunicorns.com/',
  ),
  _Watch(
    id: 'octavi',
    displayName: 'Octavi OS',
    thresholdUtc: _utc(2023, 12, 31),
    githubOrgs: <String>['Octavi-OS'],
    officialUrl: 'https://octavi-os.com/',
  ),
  _Watch(
    id: 'arrowos',
    displayName: 'ArrowOS',
    thresholdUtc: _utc(2024, 7, 22),
    githubOrgs: <String>['ArrowOS', 'ArrowOS-Devices'],
    officialUrl: 'https://arrowos.net/',
  ),
  _Watch(
    id: 'potatoaosp',
    displayName: 'POSP (Potato Open Sauce Project)',
    thresholdUtc: _utc(2025, 5, 8),
    githubOrgs: <String>['PotatoProject', 'PotatoProject-Devices'],
    officialUrl: 'https://posp.co/',
  ),
  _Watch(
    id: 'risingos',
    displayName: 'RisingOS (original)',
    thresholdUtc: _utc(2025, 2, 9),
    githubOrgs: <String>['RisingOSS'],
    officialUrl: 'https://risingos.org/',
  ),
];

class _Hit {
  _Hit(this.kind, this.repo, this.when, this.label, this.url);
  final String kind; // 'release' | 'commit'
  final String repo;
  final DateTime when;
  final String label;
  final String url;
}

Future<void> main() async {
  final String? token = Platform.environment['GITHUB_TOKEN'];
  final HttpClient client = HttpClient()
    ..userAgent =
        'Custom-RR-DefunctWatcher/1.0 (+https://github.com/monsiu/Custom-RR)'
    ..connectionTimeout = _httpTimeout;

  final Map<String, List<_Hit>> findings = <String, List<_Hit>>{};
  try {
    for (final _Watch w in _watchlist) {
      final List<_Hit> hits = <_Hit>[];
      for (final String org in w.githubOrgs) {
        try {
          hits.addAll(await _scanOrg(client, org, w.thresholdUtc, token));
        } on Object catch (err) {
          stderr.writeln('[defunct-watch] ${w.id} org=$org FAILED: $err');
        }
      }
      hits.sort((_Hit a, _Hit b) => b.when.compareTo(a.when));
      findings[w.id] = hits;
      if (hits.isEmpty) {
        stdout.writeln('[defunct-watch] ${w.displayName.padRight(22)} quiet');
      } else {
        stdout.writeln(
          '[defunct-watch] ${w.displayName.padRight(22)} '
          '${hits.length} fresh signal(s) since ${_isoDate(w.thresholdUtc)}',
        );
        for (final _Hit h in hits.take(5)) {
          stdout.writeln('    ${h.kind.padRight(7)} ${_isoDate(h.when)}  '
              '${h.repo}  ${h.label}');
        }
      }
    }
  } finally {
    client.close(force: true);
  }

  // GitHub Actions: surface each project with signals as a warning and
  // append a Markdown table to the run summary if available.
  final String? summaryPath = Platform.environment['GITHUB_STEP_SUMMARY'];
  final StringBuffer md = StringBuffer()
    ..writeln('# Defunct ROM activity check')
    ..writeln()
    ..writeln('Run UTC: ${DateTime.now().toUtc().toIso8601String()}')
    ..writeln();

  int totalHits = 0;
  for (final _Watch w in _watchlist) {
    final List<_Hit> hits = findings[w.id] ?? <_Hit>[];
    md.writeln('## ${w.displayName}');
    md.writeln();
    md.writeln('- Threshold: ${_isoDate(w.thresholdUtc)}');
    if (w.officialUrl.isNotEmpty) {
      md.writeln('- Site: ${w.officialUrl}');
    }
    if (hits.isEmpty) {
      md.writeln('- Status: **no new activity**');
      md.writeln();
      continue;
    }
    totalHits += hits.length;
    stdout.writeln(
      '::warning::Possible activity for defunct project ${w.displayName} '
      '(${hits.length} signals)',
    );
    md
      ..writeln('- Status: **${hits.length} fresh signal(s)**')
      ..writeln()
      ..writeln('| Kind | When | Repo | What |')
      ..writeln('| ---- | ---- | ---- | ---- |');
    for (final _Hit h in hits.take(10)) {
      md.writeln(
        '| ${h.kind} | ${_isoDate(h.when)} | '
        '[${h.repo}](https://github.com/${h.repo}) | '
        '[${_escapeMd(h.label)}](${h.url}) |',
      );
    }
    md.writeln();
  }

  if (summaryPath != null && summaryPath.isNotEmpty) {
    try {
      File(summaryPath).writeAsStringSync(md.toString(), mode: FileMode.append);
    } on Object catch (err) {
      stderr.writeln('[defunct-watch] could not write step summary: $err');
    }
  }

  stdout.writeln(
    '[defunct-watch] done. ${_watchlist.length} project(s) scanned, '
    '$totalHits total signals.',
  );
}

Future<List<_Hit>> _scanOrg(
  HttpClient client,
  String org,
  DateTime threshold,
  String? token,
) async {
  final List<_Hit> hits = <_Hit>[];
  // List the org's public repos (top 30 by recent push). Org and user
  // endpoints differ; we try /orgs first and fall back to /users.
  final List<Map<String, dynamic>> repos = await _listRepos(client, org, token);
  for (final Map<String, dynamic> repo in repos) {
    final String fullName = (repo['full_name'] as String?) ?? '';
    if (fullName.isEmpty) continue;
    if ((repo['fork'] as bool?) == true) continue;
    if ((repo['archived'] as bool?) == true) continue;

    // pushed_at is the cheap pre-filter: if the repo has not been pushed
    // since the threshold, skip the per-repo release/commit lookups.
    final DateTime? pushed = _parseGhDate(repo['pushed_at']);
    if (pushed == null || !pushed.isAfter(threshold)) continue;

    // Latest release (if any).
    try {
      final Map<String, dynamic>? rel = await _latestRelease(
        client, fullName, token,
      );
      if (rel != null) {
        final DateTime? when =
            _parseGhDate(rel['published_at'] ?? rel['created_at']);
        if (when != null && when.isAfter(threshold)) {
          hits.add(_Hit(
            'release',
            fullName,
            when,
            (rel['name'] as String?)?.trim().isNotEmpty == true
                ? rel['name'] as String
                : (rel['tag_name'] as String? ?? 'release'),
            (rel['html_url'] as String?) ??
                'https://github.com/$fullName/releases',
          ),);
        }
      }
    } on Object catch (err) {
      stderr.writeln('[defunct-watch] $fullName releases failed: $err');
    }

    // Latest commit on default branch.
    try {
      final Map<String, dynamic>? commit = await _latestCommit(
        client, fullName, token,
      );
      if (commit != null) {
        final Map<String, dynamic>? c =
            (commit['commit'] as Map<String, dynamic>?);
        final Map<String, dynamic>? author =
            c == null ? null : c['author'] as Map<String, dynamic>?;
        final DateTime? when = _parseGhDate(author?['date']);
        if (when != null && when.isAfter(threshold)) {
          final String msg = ((c?['message'] as String?) ?? '').split('\n').first;
          hits.add(_Hit(
            'commit',
            fullName,
            when,
            msg.length > 80 ? '${msg.substring(0, 77)}...' : msg,
            (commit['html_url'] as String?) ??
                'https://github.com/$fullName/commits',
          ),);
        }
      }
    } on Object catch (err) {
      stderr.writeln('[defunct-watch] $fullName commits failed: $err');
    }
  }
  return hits;
}

Future<List<Map<String, dynamic>>> _listRepos(
  HttpClient client,
  String owner,
  String? token,
) async {
  for (final String kind in <String>['orgs', 'users']) {
    final Uri url = Uri.parse(
      'https://api.github.com/$kind/$owner/repos'
      '?per_page=30&sort=pushed&direction=desc',
    );
    try {
      final dynamic body = await _ghGetJson(client, url, token);
      if (body is List) {
        return body.whereType<Map<String, dynamic>>().toList(growable: false);
      }
    } on _NotFound {
      continue;
    }
  }
  return const <Map<String, dynamic>>[];
}

Future<Map<String, dynamic>?> _latestRelease(
  HttpClient client,
  String fullName,
  String? token,
) async {
  final Uri url =
      Uri.parse('https://api.github.com/repos/$fullName/releases/latest');
  try {
    final dynamic body = await _ghGetJson(client, url, token);
    if (body is Map<String, dynamic>) return body;
  } on _NotFound {
    // Repo has no releases. Not an error.
  }
  return null;
}

Future<Map<String, dynamic>?> _latestCommit(
  HttpClient client,
  String fullName,
  String? token,
) async {
  final Uri url = Uri.parse(
    'https://api.github.com/repos/$fullName/commits?per_page=1',
  );
  try {
    final dynamic body = await _ghGetJson(client, url, token);
    if (body is List && body.isNotEmpty) {
      final dynamic first = body.first;
      if (first is Map<String, dynamic>) return first;
    }
  } on _NotFound {
    // Empty repo.
  }
  return null;
}

class _NotFound implements Exception {}

Future<dynamic> _ghGetJson(
  HttpClient client,
  Uri url,
  String? token,
) async {
  final HttpClientRequest req = await client.getUrl(url);
  req.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
  req.headers.set('X-GitHub-Api-Version', '2022-11-28');
  if (token != null && token.isNotEmpty) {
    req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
  }
  final HttpClientResponse resp =
      await req.close().timeout(_httpTimeout);
  if (resp.statusCode == 404) {
    await resp.drain<void>();
    throw _NotFound();
  }
  if (resp.statusCode == 403) {
    final String body = await utf8.decodeStream(resp);
    throw HttpException('HTTP 403 (rate-limited?) for $url - $body');
  }
  if (resp.statusCode < 200 || resp.statusCode >= 300) {
    await resp.drain<void>();
    throw HttpException('HTTP ${resp.statusCode} for $url');
  }
  return json.decode(await utf8.decodeStream(resp));
}

DateTime? _parseGhDate(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toUtc();
}

String _isoDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

String _escapeMd(String s) => s
    .replaceAll('|', '\\|')
    .replaceAll('\r', ' ')
    .replaceAll('\n', ' ');

DateTime _utc(int y, int m, int d) => DateTime.utc(y, m, d);
