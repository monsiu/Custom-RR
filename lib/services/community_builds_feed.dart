import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// How the community-builds list is ordered. Maps to the OpenDesktop / Pling
/// OCS API `sortmode` values.
enum CommunityBuildSort {
  downloads('down', 'Most downloaded'),
  latest('new', 'Latest'),
  rating('high', 'Top rated');

  const CommunityBuildSort(this.apiValue, this.label);

  /// The OCS API `sortmode` query value.
  final String apiValue;

  /// Human-readable label for the sort control.
  final String label;
}

/// A single community-uploaded ROM build listed on OpenDesktop's "Phone ROMS"
/// category (served by the Pling OCS API). These are unvetted, third-party
/// uploads, NOT part of the curated catalog.
@immutable
class CommunityBuild {
  const CommunityBuild({
    required this.id,
    required this.name,
    required this.maintainer,
    required this.summary,
    required this.downloads,
    required this.score,
    required this.updated,
    required this.detailPage,
    this.previewImage,
    this.deviceTags = const <String>[],
  });

  final int id;
  final String name;

  /// Uploader's username on OpenDesktop.
  final String maintainer;

  /// Short description provided by the uploader.
  final String summary;

  /// Total download count reported by the API.
  final int downloads;

  /// Quality score on a 0-100 scale. Divide by 10 for the 0-10 rating shown
  /// on the website.
  final int score;

  /// When the listing was last changed.
  final DateTime updated;

  /// Canonical OpenDesktop page for the listing (opened externally).
  final String detailPage;

  /// Optional preview thumbnail URL.
  final String? previewImage;

  /// Device codenames and vendor names parsed from the listing's tags
  /// (license, build-type and maintainer noise removed). May be empty when
  /// the uploader provided no useful tags.
  final List<String> deviceTags;

  /// Rating on a 0-10 scale, derived from [score].
  double get rating => score / 10.0;
}

/// One page of community-build results plus the paging metadata needed to
/// decide whether more pages exist.
@immutable
class CommunityBuildsResult {
  const CommunityBuildsResult({
    required this.builds,
    required this.totalItems,
    required this.page,
    required this.pageSize,
  });

  /// The visible builds for this page (already junk-filtered).
  final List<CommunityBuild> builds;

  /// Total items reported by the API BEFORE client-side filtering, used to
  /// compute [hasMore] reliably even when a page is filtered down.
  final int totalItems;

  final int page;
  final int pageSize;

  bool get hasMore => (page + 1) * pageSize < totalItems;
}

class CommunityBuildsException implements Exception {
  CommunityBuildsException(this.message);
  final String message;
  @override
  String toString() => 'CommunityBuildsException: $message';
}

class _CachedResult {
  _CachedResult(this.fetchedAt, this.result);
  final DateTime fetchedAt;
  final CommunityBuildsResult result;
}

/// Fetches the live "Phone ROMS" community uploads from the OpenDesktop /
/// Pling OCS API, with a short in-memory cache and graceful fallback.
///
/// This is intentionally separate from the curated [CatalogRepository]: the
/// entries here are unvetted community uploads and are surfaced on a dedicated
/// "Community builds" screen behind a disclaimer, never mixed into the catalog.
class CommunityBuildsFeed {
  CommunityBuildsFeed._();

  static final CommunityBuildsFeed instance = CommunityBuildsFeed._();

  /// Pluggable HTTP client so tests can inject a `MockClient`.
  http.Client httpClient = http.Client();

  /// OCS API base. category 495 = "Phone ROMS" on the Pling network.
  static const String _base = 'https://api.pling.com/ocs/v1/content/data';
  static const int _category = 495;

  static const Duration _ttl = Duration(minutes: 10);
  static const Duration _timeout = Duration(seconds: 10);

  final Map<String, _CachedResult> _cache = <String, _CachedResult>{};

  /// Fetches one page of community builds.
  ///
  /// Returns junk-filtered results (recoveries, kernels and other non-ROM
  /// uploads removed). Falls back to cached data on transient failures and
  /// throws [CommunityBuildsException] only when there is nothing to show.
  Future<CommunityBuildsResult> fetch({
    CommunityBuildSort sort = CommunityBuildSort.downloads,
    String search = '',
    int page = 0,
    int pageSize = 20,
    bool force = false,
  }) async {
    final String query = search.trim();
    final String key = '${sort.apiValue}|$query|$page|$pageSize';
    final _CachedResult? cached = _cache[key];
    if (!force &&
        cached != null &&
        DateTime.now().difference(cached.fetchedAt) < _ttl) {
      return cached.result;
    }

    final Uri uri = Uri.parse(_base).replace(
      queryParameters: <String, String>{
        'categories': '$_category',
        'format': 'json',
        'sortmode': sort.apiValue,
        'page': '$page',
        'pagesize': '$pageSize',
        if (query.isNotEmpty) 'search': query,
      },
    );

    try {
      final http.Response res = await httpClient.get(
        uri,
        headers: const <String, String>{
          'User-Agent': 'CustomRR/1.0 (+https://github.com/monsiu/Custom-RR)',
          'Accept': 'application/json',
        },
      ).timeout(_timeout);
      if (res.statusCode != 200) {
        throw CommunityBuildsException('Server responded ${res.statusCode}');
      }
      final CommunityBuildsResult result = parseResponse(
        res.body,
        page: page,
        pageSize: pageSize,
      );
      _cache[key] = _CachedResult(DateTime.now(), result);
      return result;
    } catch (err) {
      if (cached != null) return cached.result;
      if (err is CommunityBuildsException) rethrow;
      throw CommunityBuildsException('Could not load community builds');
    }
  }

  /// Fetches community builds that target a specific device [codename]
  /// (e.g. `beryllium` for the Poco F1). Searches the API by codename, then
  /// keeps only builds that genuinely reference it (the API search is fuzzy
  /// and can return loosely-related uploads). Returns at most [limit] sorted
  /// by downloads. Throws [CommunityBuildsException] only on a hard failure
  /// with nothing cached.
  Future<List<CommunityBuild>> fetchForDevice(
    String codename, {
    int limit = 8,
    bool force = false,
  }) async {
    final String cn = codename.trim();
    if (cn.isEmpty) return const <CommunityBuild>[];
    final CommunityBuildsResult res = await fetch(
      search: cn,
      pageSize: 30,
      force: force,
    );
    final List<CommunityBuild> matched = res.builds
        .where((CommunityBuild b) => buildMatchesCodename(b, cn))
        .toList();
    return matched.length > limit ? matched.sublist(0, limit) : matched;
  }

  /// Whether [build] genuinely targets device [codename], used to tighten the
  /// API's fuzzy search. Matches when the codename appears as an exact device
  /// tag, or as a whole word in the name or summary.
  ///
  /// Visible for testing.
  @visibleForTesting
  static bool buildMatchesCodename(CommunityBuild build, String codename) {
    final String cn = codename.trim().toLowerCase();
    if (cn.isEmpty) return false;
    if (build.deviceTags.contains(cn)) return true;
    final RegExp word = RegExp(
      '(?<![a-z0-9])${RegExp.escape(cn)}(?![a-z0-9])',
      caseSensitive: false,
    );
    return word.hasMatch(build.name) || word.hasMatch(build.summary);
  }

  /// Parses an OCS JSON body into a filtered [CommunityBuildsResult].
  ///
  /// Visible for testing so the parsing and junk-filtering logic can be
  /// exercised without hitting the network.
  @visibleForTesting
  static CommunityBuildsResult parseResponse(
    String body, {
    required int page,
    required int pageSize,
  }) {
    final dynamic decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw CommunityBuildsException('Unexpected response shape');
    }
    final int total =
        int.tryParse('${decoded['totalitems'] ?? ''}') ?? 0;
    final dynamic data = decoded['data'];
    final List<CommunityBuild> builds = <CommunityBuild>[];
    if (data is List) {
      for (final dynamic raw in data) {
        if (raw is! Map) continue;
        final CommunityBuild? b = _parseItem(raw.cast<String, dynamic>());
        if (b == null) continue;
        if (isLikelyNonRom(b.name, b.summary)) continue;
        builds.add(b);
      }
    }
    return CommunityBuildsResult(
      builds: builds,
      totalItems: total,
      page: page,
      pageSize: pageSize,
    );
  }

  static CommunityBuild? _parseItem(Map<String, dynamic> m) {
    final int? id = int.tryParse('${m['id'] ?? ''}');
    final String name = ('${m['name'] ?? ''}').trim();
    if (id == null || name.isEmpty) return null;
    final String detail = ('${m['detailpage'] ?? ''}').trim().isNotEmpty
        ? '${m['detailpage']}'.trim()
        : 'https://www.pling.com/p/$id';
    final String? preview = _firstNonEmpty(<String?>[
      m['smallpreviewpic1'] as String?,
      m['previewpic1'] as String?,
    ]);
    // Prefer the structured tags; when they carry no device hints, fall back
    // to codenames parsed from the freeform description.
    List<String> devices = extractDeviceTags(
      '${m['tags'] ?? ''}',
      maintainer: '${m['personid'] ?? ''}',
    );
    if (devices.isEmpty) {
      devices = extractDeviceTagsFromDescription('${m['description'] ?? ''}');
    }
    return CommunityBuild(
      id: id,
      name: name,
      maintainer: ('${m['personid'] ?? ''}').trim(),
      summary: _collapse(('${m['summary'] ?? ''}').trim()),
      downloads: int.tryParse('${m['downloads'] ?? ''}') ?? 0,
      score: int.tryParse('${m['score'] ?? ''}') ?? 0,
      updated: DateTime.tryParse('${m['changed'] ?? ''}')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      detailPage: detail,
      previewImage: (preview != null && preview.isNotEmpty) ? preview : null,
      deviceTags: devices,
    );
  }

  /// True when a listing in the "Phone ROMS" category is actually a recovery,
  /// kernel, or other non-ROM upload that should not appear in a ROM list.
  /// Visible for testing.
  @visibleForTesting
  static bool isLikelyNonRom(String name, String summary) {
    final String t = '$name $summary'.toLowerCase();
    const List<String> needles = <String>[
      'recovery',
      'orangefox',
      'twrp',
      'pitchblack',
      ' shrp',
      'kernel',
      'magisk',
      'gapps',
      'firmware only',
      'wallpaper',
    ];
    for (final String n in needles) {
      if (t.contains(n)) return true;
    }
    return false;
  }

  /// Tags that are licenses, build types, or generic status words rather than
  /// devices. Removed when deriving the device-tag chips.
  static const Set<String> _noiseTags = <String>{
    // Licenses
    'apache-license', 'apache', 'apache2', 'gpl', 'gplv2', 'gplv2-later',
    'gplv3', 'gplv3-later', 'lgpl', 'agpl', 'agplv3', 'mit', 'bsd', 'isc',
    'zlib', 'mpl', 'mpl-2.0', 'cc-by', 'cc-by-sa', 'cc-by-nc', 'cc0',
    'public-domain', 'unlicense', 'proprietary', 'custom-license', 'wtfpl',
    'boost', 'original-product',
    // Build type / status / generic
    'app', 'application', 'rom', 'roms', 'custom-rom', 'customrom', 'android',
    'aosp', 'los', 'lineage', 'lineageos', 'root', 'rooted', 'magisk',
    'kernel', 'kernels', 'recovery', 'twrp', 'orangefox', 'ofox',
    'pitchblack', 'pbrp', 'shrp', 'theme', 'themes', 'mod', 'mods', 'module',
    'firmware', 'gapps', 'microg', 'vanilla', 'gms', 'official', 'unofficial',
    'stable', 'beta', 'alpha', 'testing', 'nightly', 'weekly', 'port',
    'ported', 'oss', 'source', 'opensource', 'open-source', 'custom', 'build',
    'builds', 'os', 'launcher', 'gsi', 'generic', 'system', 'image', 'efi',
    'treble', 'arm64', 'arm', 'a-only', 'ab', 'vndklite', 'rooting', 'noobrom',
  };

  /// Extracts device codenames and vendor names from a listing's raw
  /// comma-separated [rawTags], dropping license, build-type, and maintainer
  /// noise. Returns at most six, de-duplicated, in their original order.
  ///
  /// Visible for testing.
  @visibleForTesting
  static List<String> extractDeviceTags(
    String rawTags, {
    String maintainer = '',
  }) {
    if (rawTags.trim().isEmpty) return const <String>[];
    final String maint = maintainer.trim().toLowerCase();
    final List<String> out = <String>[];
    final Set<String> seen = <String>{};
    for (final String part in rawTags.split(',')) {
      final String tag = part.trim().toLowerCase();
      if (tag.isEmpty || tag == maint) continue;
      if (_noiseTags.contains(tag)) continue;
      if (!seen.add(tag)) continue;
      out.add(tag);
      if (out.length >= 6) break;
    }
    return out;
  }

  /// A plausible device codename: starts with a letter, then 2-19 more
  /// alphanumeric/underscore characters, no spaces (e.g. `beryllium`, `x00t`).
  static final RegExp _codenameLike = RegExp(r'^[A-Za-z][A-Za-z0-9_]{2,19}$');

  /// Generic words that can appear parenthetically in a description but are
  /// not device codenames. Checked alongside [_noiseTags].
  static const Set<String> _descStopwords = <String>{
    'treble', 'gsi', 'arm64', 'arm', 'a-only', 'ab', 'vndklite', 'lite',
    'recommended', 'experimental', 'note', 'pro', 'plus', 'max', 'mini',
    'global', 'eea', 'china', 'indian', 'india', 'global-version', 'tap',
    'quick', 'support', 'group', 'unified', 'version', 'edition', 'series',
  };

  /// Fallback device extraction from a listing's freeform [descriptionHtml],
  /// used when its tags carry no device hints. Pulls codenames out of
  /// parenthetical groups (e.g. "Corvus OS for Poco F1 (beryllium)" or
  /// "... ( ginkgo / willow )"), the most reliable device signal in the
  /// description text. Returns at most six, de-duplicated and lowercased.
  ///
  /// Visible for testing.
  @visibleForTesting
  static List<String> extractDeviceTagsFromDescription(String descriptionHtml) {
    if (descriptionHtml.trim().isEmpty) return const <String>[];
    final String text = descriptionHtml
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    final List<String> out = <String>[];
    final Set<String> seen = <String>{};
    for (final Match m in RegExp(r'\(([^)]{1,60})\)').allMatches(text)) {
      final String group = m.group(1) ?? '';
      for (final String piece in group.split(RegExp(r'[/,]'))) {
        final String token = piece.trim();
        if (!_codenameLike.hasMatch(token)) continue;
        final String lower = token.toLowerCase();
        if (_noiseTags.contains(lower) || _descStopwords.contains(lower)) {
          continue;
        }
        if (!seen.add(lower)) continue;
        out.add(lower);
        if (out.length >= 6) return out;
      }
    }
    return out;
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final String? v in values) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  /// Collapses runs of whitespace/newlines in API summaries to single spaces.
  static String _collapse(String s) =>
      s.replaceAll(RegExp(r'\s+'), ' ').trim();
}
