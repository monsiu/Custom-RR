import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';

/// Loads ROM/recovery freshness data and exposes per-entry [FreshnessInfo].
///
/// Resolution order on [load]:
///   1. Bundled `assets/freshness.json`, applied synchronously-fast so the
///      first frame always has *some* data.
///   2. SharedPreferences cache, overlays #1 if present (last good remote
///      payload from a previous run).
///   3. Remote `freshness.json`, fetched in the background; on success the
///      payload is parsed, applied, cached to SharedPreferences, and
///      listeners are notified so visible badges refresh.
///
/// The remote fetch never blocks startup: callers `await load()` and get
/// the best-available local data immediately; remote refresh happens after.
class FreshnessRepository extends ChangeNotifier {
  FreshnessRepository._();
  static final FreshnessRepository instance = FreshnessRepository._();

  static const String _assetPath = 'assets/freshness.json';
  static const String _cacheKey = 'freshness_json_v1';
  static const String _remoteUrl =
      'https://raw.githubusercontent.com/monsiu/Custom-RR/main/assets/freshness.json';
  // First-attempt timeout. On a cold start, DNS + TLS handshake to
  // raw.githubusercontent.com can easily take 4-6 s on mobile networks,
  // which was firing the bogus "you're offline" dialog. 12 s + one
  // retry handles slow networks without making users wait forever.
  static const Duration _remoteTimeout = Duration(seconds: 12);
  static const Duration _retryDelay = Duration(seconds: 2);

  Map<String, FreshnessInfo> _byId = const <String, FreshnessInfo>{};
  bool _loaded = false;
  bool _remoteKicked = false;
  bool _hasCachedPayload = false;
  FreshnessFetchStatus _fetchStatus = FreshnessFetchStatus.idle;

  bool get isLoaded => _loaded;
  Map<String, FreshnessInfo> get all => _byId;

  /// True when a previous successful remote fetch is cached in
  /// SharedPreferences (or has succeeded this session). Used by the
  /// offline notice to suppress its dialog: if we already have a recent
  /// snapshot, a transient fetch failure isn't worth a modal.
  bool get hasCachedPayload => _hasCachedPayload;

  /// State of the most recent attempt to fetch the remote snapshot.
  FreshnessFetchStatus get fetchStatus => _fetchStatus;

  Future<void> load({String? overrideJson}) async {
    if (overrideJson != null) {
      _applyJson(overrideJson);
      _loaded = true;
      return;
    }
    if (_loaded) {
      _maybeRefreshRemote();
      return;
    }

    // 1) Bundled asset baseline so the UI is never empty.
    try {
      _applyJson(await rootBundle.loadString(_assetPath));
    } on Object {
      _byId = const <String, FreshnessInfo>{};
    }

    // 2) Overlay last-known-good remote payload from SharedPreferences.
    try {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      final String? cached = sp.getString(_cacheKey);
      if (cached != null && cached.isNotEmpty) {
        _applyJson(cached);
        _hasCachedPayload = true;
      }
    } on Object {
      // Cache unavailable; ignore.
    }

    _loaded = true;

    // 3) Kick off remote refresh in the background.
    _maybeRefreshRemote();
  }

  /// Manually re-attempt the remote fetch (e.g. from an "Try again" button
  /// after the user reconnects to the network).
  Future<void> refresh() async {
    _remoteKicked = true;
    await _refreshRemote();
  }

  void _maybeRefreshRemote() {
    if (_remoteKicked) return;
    _remoteKicked = true;
    unawaited(_refreshRemote());
  }

  Future<void> _refreshRemote() async {
    _fetchStatus = FreshnessFetchStatus.loading;
    notifyListeners();
    // One retry after a short delay; covers transient DNS hiccups and
    // captive-portal warmup on freshly-joined Wi-Fi.
    for (int attempt = 0; attempt < 2; attempt++) {
      if (await _tryFetchOnce()) {
        _fetchStatus = FreshnessFetchStatus.ok;
        _hasCachedPayload = true;
        notifyListeners();
        return;
      }
      if (attempt == 0) {
        await Future<void>.delayed(_retryDelay);
      }
    }
    _fetchStatus = FreshnessFetchStatus.failed;
    notifyListeners();
  }

  /// Single fetch attempt. Returns true if it succeeded and the payload
  /// was applied + cached. Never throws.
  Future<bool> _tryFetchOnce() async {
    try {
      final http.Response resp =
          await http.get(Uri.parse(_remoteUrl)).timeout(_remoteTimeout);
      if (resp.statusCode < 200 || resp.statusCode >= 300) return false;
      final String body = resp.body;
      if (body.isEmpty) return false;
      // Validate before caching so we don't poison the cache with garbage.
      json.decode(body);
      _applyJson(body);
      try {
        final SharedPreferences sp = await SharedPreferences.getInstance();
        await sp.setString(_cacheKey, body);
      } on Object {
        // Best-effort cache; ignore.
      }
      return true;
    } on Object {
      // Offline, DNS, 5xx, parse error: keep whatever we already have.
      return false;
    }
  }

  void _applyJson(String source) {
    final Map<String, dynamic> root =
        json.decode(source) as Map<String, dynamic>;
    final Map<String, dynamic> entries =
        (root['entries'] as Map<String, dynamic>? ?? <String, dynamic>{});
    _byId = <String, FreshnessInfo>{
      for (final MapEntry<String, dynamic> e in entries.entries)
        e.key: FreshnessInfo.fromJson(e.value as Map<String, dynamic>),
    };
  }

  FreshnessInfo forId(String id) => _byId[id] ?? FreshnessInfo.unknown;
}

/// Lifecycle of the background remote fetch in [FreshnessRepository].
enum FreshnessFetchStatus {
  /// No fetch attempted yet this session.
  idle,

  /// HTTP request in flight.
  loading,

  /// Remote fetch completed; cache and in-memory map updated.
  ok,

  /// Last attempt failed (timeout, DNS, 4xx/5xx, parse error).
  /// Local bundled/cached data is still being shown.
  failed,
}
