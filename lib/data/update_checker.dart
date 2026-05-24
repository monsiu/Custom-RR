import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Outcome of an update check against the GitHub Releases API.
class UpdateCheckResult {
  const UpdateCheckResult({
    required this.currentVersion,
    required this.latestVersion,
    required this.isUpdateAvailable,
    required this.releaseUrl,
    required this.releaseName,
    required this.releaseNotes,
    required this.publishedAt,
  });

  /// Local app version (without leading 'v').
  final String currentVersion;

  /// Latest published release version (without leading 'v'), or empty if
  /// the lookup failed.
  final String latestVersion;

  final bool isUpdateAvailable;

  /// HTML URL of the release page on GitHub, or empty on failure.
  final String releaseUrl;

  /// Display name of the release (falls back to the tag if unset).
  final String releaseName;

  /// Markdown release notes from GitHub (may be empty).
  final String releaseNotes;

  /// When the release was published, or `null` if unknown.
  final DateTime? publishedAt;
}

/// Thin client around the GitHub Releases API used to power the in-app
/// "Check for updates" action. Only reads the public `releases/latest`
/// endpoint so no authentication is required.
class UpdateChecker {
  UpdateChecker._();
  static final UpdateChecker instance = UpdateChecker._();

  static const String _repoOwner = 'monsiu';
  static const String _repoName = 'Custom-RR';

  Uri get _latestReleaseUri => Uri.https(
        'api.github.com',
        '/repos/$_repoOwner/$_repoName/releases/latest',
      );

  /// Fetches the latest GitHub release and compares it to the running
  /// app version. Throws on network or parse failures so the UI can
  /// distinguish "no update" from "could not check".
  Future<UpdateCheckResult> check({Duration timeout = const Duration(seconds: 10)}) async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    final String current = info.version;

    final http.Response response = await http
        .get(
          _latestReleaseUri,
          headers: <String, String>{
            'Accept': 'application/vnd.github+json',
            'X-GitHub-Api-Version': '2022-11-28',
          },
        )
        .timeout(timeout);

    if (response.statusCode == 404) {
      // Repo has no published releases yet.
      return UpdateCheckResult(
        currentVersion: current,
        latestVersion: '',
        isUpdateAvailable: false,
        releaseUrl: 'https://github.com/$_repoOwner/$_repoName/releases',
        releaseName: '',
        releaseNotes: '',
        publishedAt: null,
      );
    }
    if (response.statusCode != 200) {
      throw HttpException(
        'GitHub responded with ${response.statusCode}',
      );
    }

    final Map<String, dynamic> body =
        json.decode(response.body) as Map<String, dynamic>;
    final String tag = (body['tag_name'] as String? ?? '').trim();
    final String latest = _stripLeadingV(tag);
    final String url = (body['html_url'] as String? ?? '').trim();
    final String name = ((body['name'] as String?)?.trim().isNotEmpty ?? false)
        ? (body['name'] as String).trim()
        : tag;
    final String notes = (body['body'] as String? ?? '').trim();
    final String publishedRaw = (body['published_at'] as String? ?? '').trim();
    final DateTime? published =
        publishedRaw.isEmpty ? null : DateTime.tryParse(publishedRaw);

    return UpdateCheckResult(
      currentVersion: current,
      latestVersion: latest,
      isUpdateAvailable: _isNewer(latest, current),
      releaseUrl: url,
      releaseName: name,
      releaseNotes: notes,
      publishedAt: published,
    );
  }

  static String _stripLeadingV(String tag) {
    if (tag.isEmpty) return tag;
    if (tag.startsWith('v') || tag.startsWith('V')) {
      return tag.substring(1);
    }
    return tag;
  }

  /// Returns true when [latest] is strictly newer than [current] using a
  /// loose semantic-version comparison. Non-numeric or missing components
  /// are treated as 0.
  static bool _isNewer(String latest, String current) {
    if (latest.isEmpty) return false;
    final List<int> a = _versionParts(latest);
    final List<int> b = _versionParts(current);
    final int len = a.length > b.length ? a.length : b.length;
    for (int i = 0; i < len; i++) {
      final int ai = i < a.length ? a[i] : 0;
      final int bi = i < b.length ? b[i] : 0;
      if (ai > bi) return true;
      if (ai < bi) return false;
    }
    return false;
  }

  static List<int> _versionParts(String v) {
    // Strip any build/pre-release suffix (e.g. "1.2.3+4", "1.2.3-rc1").
    final String core = v.split(RegExp(r'[+\-]')).first;
    return core
        .split('.')
        .map((String s) => int.tryParse(s.trim()) ?? 0)
        .toList(growable: false);
  }
}

/// Lightweight exception type so the UI can show a friendly error
/// without depending on dart:io.
class HttpException implements Exception {
  HttpException(this.message);
  final String message;
  @override
  String toString() => message;
}
