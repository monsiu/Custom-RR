import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show ChangeNotifier, compute;
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';

/// Loads the catalog JSON shipped under `assets/catalog.json` once and
/// caches the parsed entries. All UI reads through [instance] after
/// [load] has resolved.
///
/// Resolution order on [load]:
///   1. Bundled `assets/catalog.json`, parsed on a background isolate so
///      the first frame always has data without spending UI time.
///   2. SharedPreferences cache, overlays #1 if a previous remote fetch
///      cached a newer payload locally.
///   3. Remote `assets/catalog.json` from the GitHub `main` branch,
///      fetched in the background. On success the payload is parsed,
///      applied, cached, and listeners notified so any subscribed pages
///      refresh; otherwise the locally-good data keeps showing.
///
/// The remote fetch never blocks startup: callers `await load()` and get
/// the best-available local data immediately; remote refresh happens
/// after the first frame. Mirrors [FreshnessRepository] so both data
/// sources stay current without app updates.
class CatalogRepository extends ChangeNotifier {
  CatalogRepository._();
  static final CatalogRepository instance = CatalogRepository._();

  static const String _assetPath = 'assets/catalog.json';
  static const String _cacheKey = 'catalog_json_v1';
  static const String _remoteUrl =
      'https://raw.githubusercontent.com/monsiu/Custom-RR/main/assets/catalog.json';
  static const Duration _remoteTimeout = Duration(seconds: 15);
  static const Duration _retryDelay = Duration(seconds: 2);

  List<CatalogEntry> _roms = const <CatalogEntry>[];
  List<CatalogEntry> _recoveries = const <CatalogEntry>[];
  List<DeviceEntry> _devices = const <DeviceEntry>[];
  bool _loaded = false;
  bool _remoteKicked = false;
  bool _hasCachedPayload = false;
  CatalogFetchStatus _fetchStatus = CatalogFetchStatus.idle;

  bool get isLoaded => _loaded;
  List<CatalogEntry> get roms => _roms;
  List<CatalogEntry> get recoveries => _recoveries;
  List<DeviceEntry> get devices => _devices;

  /// True when a previous successful remote catalog fetch is cached in
  /// SharedPreferences (or has succeeded this session). Mirrors the
  /// flag on [FreshnessRepository] so the offline notice can stay quiet
  /// when we still have a recent snapshot.
  bool get hasCachedPayload => _hasCachedPayload;

  /// State of the most recent remote-fetch attempt for the catalog.
  CatalogFetchStatus get fetchStatus => _fetchStatus;

  Future<void> load({String? overrideJson}) async {
    if (overrideJson != null) {
      final _ParsedCatalog parsed = await compute(_parseCatalog, overrideJson);
      _applyParsed(parsed);
      _loaded = true;
      return;
    }
    if (_loaded) {
      _maybeRefreshRemote();
      return;
    }

    // 1) Bundled asset baseline so the UI is never empty.
    // The shipped catalog is ~900 KB. Parsing + model decoding on the
    // UI isolate was burning ~1-2 s on cold start (Skipped 750 frames /
    // Davey! 2s in logcat). Move it to a background isolate; the result
    // objects are plain Dart classes, safe to transfer.
    final String bundled = await rootBundle.loadString(_assetPath);
    final _ParsedCatalog parsed = await compute(_parseCatalog, bundled);
    _applyParsed(parsed);

    // 2) Overlay last-known-good remote payload from SharedPreferences.
    try {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      final String? cached = sp.getString(_cacheKey);
      if (cached != null && cached.isNotEmpty) {
        final _ParsedCatalog cachedParsed =
            await compute(_parseCatalog, cached);
        _applyParsed(cachedParsed);
        _hasCachedPayload = true;
      }
    } on Object {
      // Cache unavailable or corrupt; ignore and stick with bundled.
    }

    _loaded = true;

    // 3) Kick off remote refresh in the background.
    _maybeRefreshRemote();
  }

  /// Force a re-read of the bundled catalog JSON plus a remote refresh.
  /// Useful for pull-to-refresh affordances and the "Check for updates"
  /// action.
  Future<void> reload() async {
    _loaded = false;
    _remoteKicked = false;
    await load();
  }

  /// Manually re-attempt the remote fetch (e.g. from a "Try again" button
  /// after the user reconnects).
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
    _fetchStatus = CatalogFetchStatus.loading;
    notifyListeners();
    // One retry after a short delay; covers transient DNS hiccups and
    // captive-portal warmup on freshly-joined Wi-Fi.
    for (int attempt = 0; attempt < 2; attempt++) {
      if (await _tryFetchOnce()) {
        _fetchStatus = CatalogFetchStatus.ok;
        _hasCachedPayload = true;
        notifyListeners();
        return;
      }
      if (attempt == 0) {
        await Future<void>.delayed(_retryDelay);
      }
    }
    _fetchStatus = CatalogFetchStatus.failed;
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
      // Parse + validate on a background isolate before caching so we
      // don't poison the cache with garbage and don't jank the UI.
      final _ParsedCatalog parsed = await compute(_parseCatalog, body);
      _applyParsed(parsed);
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

  void _applyParsed(_ParsedCatalog parsed) {
    _roms = parsed.roms;
    _recoveries = parsed.recoveries;
    _devices = parsed.devices;
  }

  /// Look up a ROM by id; returns `null` if not found.
  CatalogEntry? romById(String id) =>
      _firstWhereOrNull(_roms, (CatalogEntry e) => e.id == id);

  /// Look up a recovery by id; returns `null` if not found.
  CatalogEntry? recoveryById(String id) =>
      _firstWhereOrNull(_recoveries, (CatalogEntry e) => e.id == id);

  /// Look up a device by url-safe slug; returns `null` if not found.
  DeviceEntry? deviceBySlug(String slug) =>
      _firstWhereOrNull(_devices, (DeviceEntry d) => d.slug == slug);

  /// ROMs compatible with the given device (by manufacturer name).
  List<CatalogEntry> romsForDevice(String deviceName) => _roms
      .where(
        (CatalogEntry e) => e.supportedManufacturers.contains(deviceName),
      )
      .toList();

  /// Recoveries compatible with the given device (by manufacturer name).
  List<CatalogEntry> recoveriesForDevice(String deviceName) => _recoveries
      .where(
        (CatalogEntry e) => e.supportedManufacturers.contains(deviceName),
      )
      .toList();

  /// Distinct phone models supported by ANY ROM or recovery for the given
  /// manufacturer. Each [DeviceRef] is deduplicated on `(brand, model)`.
  /// Result is sorted alphabetically by model name.
  List<DeviceRef> modelsForDevice(String deviceName) {
    final Map<String, DeviceRef> seen = <String, DeviceRef>{};
    for (final CatalogEntry e in <CatalogEntry>[..._roms, ..._recoveries]) {
      for (final DeviceRef d in e.devices) {
        if (d.brand != deviceName) continue;
        seen.putIfAbsent('${d.brand}|${d.model}', () => d);
      }
    }
    final List<DeviceRef> out = seen.values.toList()
      ..sort(
        (DeviceRef a, DeviceRef b) =>
            a.model.toLowerCase().compareTo(b.model.toLowerCase()),
      );
    return out;
  }

  /// ROMs that explicitly list the given (brand, model) combination.
  List<CatalogEntry> romsForModel(String brand, String model) => _roms
      .where(
        (CatalogEntry e) => e.devices.any(
          (DeviceRef d) => d.brand == brand && d.model == model,
        ),
      )
      .toList();

  /// Recoveries that explicitly list the given (brand, model) combination.
  List<CatalogEntry> recoveriesForModel(String brand, String model) =>
      _recoveries
          .where(
            (CatalogEntry e) => e.devices.any(
              (DeviceRef d) => d.brand == brand && d.model == model,
            ),
          )
          .toList();

  /// ROMs that list the given (brand, codename) combination.
  List<CatalogEntry> romsForCodename(String brand, String codename) => _roms
      .where(
        (CatalogEntry e) => e.devices.any(
          (DeviceRef d) => d.brand == brand && d.codename == codename,
        ),
      )
      .toList();

  /// Recoveries that list the given (brand, codename) combination.
  List<CatalogEntry> recoveriesForCodename(String brand, String codename) =>
      _recoveries
          .where(
            (CatalogEntry e) => e.devices.any(
              (DeviceRef d) => d.brand == brand && d.codename == codename,
            ),
          )
          .toList();

  /// Lookup the first matching [DeviceRef] for the given (brand, codename).
  /// Used by the per-model detail page to resolve a URL into a real device.
  DeviceRef? deviceRefByCodename(String brand, String codename) {
    for (final CatalogEntry e in <CatalogEntry>[..._roms, ..._recoveries]) {
      for (final DeviceRef d in e.devices) {
        if (d.brand == brand && d.codename == codename) return d;
      }
    }
    return null;
  }
}

List<T> _decodeList<T>(
  Object? raw,
  T Function(Map<String, dynamic> json) decoder,
) {
  if (raw == null) return <T>[];
  return (raw as List<dynamic>)
      .map<T>((Object? e) => decoder(e! as Map<String, dynamic>))
      .toList();
}

T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T) test) {
  for (final T item in items) {
    if (test(item)) return item;
  }
  return null;
}

/// Result bundle for [_parseCatalog]. Held in a tiny class so it can be
/// shipped back across the isolate boundary in a single message.
class _ParsedCatalog {
  _ParsedCatalog(this.roms, this.recoveries, this.devices);
  final List<CatalogEntry> roms;
  final List<CatalogEntry> recoveries;
  final List<DeviceEntry> devices;
}

/// Top-level so [compute] can invoke it in a background isolate.
_ParsedCatalog _parseCatalog(String source) {
  final Map<String, dynamic> root =
      json.decode(source) as Map<String, dynamic>;
  return _ParsedCatalog(
    _decodeList(root['roms'], CatalogEntry.fromJson),
    _decodeList(root['recoveries'], CatalogEntry.fromJson),
    _decodeList(root['devices'], DeviceEntry.fromJson),
  );
}

/// Lifecycle of the background remote fetch in [CatalogRepository].
/// Mirrors `FreshnessFetchStatus` so UI affordances (offline notice,
/// "Try again" buttons) can treat both data sources uniformly.
enum CatalogFetchStatus {
  /// No fetch attempted yet this session.
  idle,

  /// HTTP request in flight.
  loading,

  /// Remote fetch completed; cache and in-memory catalog updated.
  ok,

  /// Last attempt failed (timeout, DNS, 4xx/5xx, parse error).
  /// Local bundled/cached catalog is still being shown.
  failed,
}
