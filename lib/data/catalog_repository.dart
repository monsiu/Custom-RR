import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models.dart';

/// Loads the catalog JSON shipped under `assets/catalog.json` once and
/// caches the parsed entries. All UI reads through [instance] after
/// [load] has resolved.
///
/// Shipping the catalog as a JSON asset (rather than hard-coded Dart
/// constants) lets future versions swap in a remote fetch without
/// touching the UI layer.
class CatalogRepository {
  CatalogRepository._();
  static final CatalogRepository instance = CatalogRepository._();

  static const String _assetPath = 'assets/catalog.json';

  List<CatalogEntry> _roms = const <CatalogEntry>[];
  List<CatalogEntry> _recoveries = const <CatalogEntry>[];
  List<DeviceEntry> _devices = const <DeviceEntry>[];
  bool _loaded = false;

  bool get isLoaded => _loaded;
  List<CatalogEntry> get roms => _roms;
  List<CatalogEntry> get recoveries => _recoveries;
  List<DeviceEntry> get devices => _devices;

  Future<void> load({String? overrideJson}) async {
    if (_loaded && overrideJson == null) return;
    final String source =
        overrideJson ?? await rootBundle.loadString(_assetPath);
    final Map<String, dynamic> root =
        json.decode(source) as Map<String, dynamic>;
    _roms = _decodeList(root['roms'], CatalogEntry.fromJson);
    _recoveries = _decodeList(root['recoveries'], CatalogEntry.fromJson);
    _devices = _decodeList(root['devices'], DeviceEntry.fromJson);
    _loaded = true;
  }

  /// Force a re-read of the bundled catalog JSON. Useful for pull-to-refresh
  /// affordances; when the catalog becomes remotely fetched, this is the
  /// hook that will perform that fetch.
  Future<void> reload() async {
    _loaded = false;
    await load();
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
