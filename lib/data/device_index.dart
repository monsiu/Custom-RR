import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../util/codename_aliases.dart';

/// A device recognised from Google's Play device catalog, whether or not any
/// project builds for it.
@immutable
class KnownDevice {
  const KnownDevice({
    required this.codename,
    required this.brand,
    required this.name,
    required this.models,
  });

  final String codename;
  final String brand;
  final String name;

  /// Retail model numbers (e.g. `SM-X205`, `SM-X207`).
  final List<String> models;

  /// "Samsung Galaxy Tab A8", falling back to whichever half we have.
  String get label => <String>[
        brand,
        name,
      ].where((String s) => s.isNotEmpty).join(' ').trim();
}

/// Dictionary of ~36k Android codenames and retail model numbers, bundled from
/// Google's public Play device catalog.
///
/// The catalog only lists devices some project actually builds for. This index
/// covers everything else, so a search for `gta8` or `SM-X205` can answer
/// "that is a Samsung Galaxy Tab A8, and nobody maintains a build for it yet"
/// instead of showing nothing.
class DeviceIndex {
  DeviceIndex._();

  static final DeviceIndex instance = DeviceIndex._();

  static const String _assetPath = 'assets/device_index.json';

  Map<String, KnownDevice> _byCodename = const <String, KnownDevice>{};
  Map<String, String> _codenameByModel = const <String, String>{};
  bool _loaded = false;
  Future<void>? _loading;

  bool get isLoaded => _loaded;

  /// Parses the bundled dictionary once, off the UI isolate.
  Future<void> load() {
    if (_loaded) return Future<void>.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final String raw = await rootBundle.loadString(_assetPath);
      final _ParsedIndex parsed = await compute(_parseIndex, raw);
      _byCodename = parsed.byCodename;
      _codenameByModel = parsed.codenameByModel;
    } on Object catch (e) {
      debugPrint('DeviceIndex: could not load $_assetPath: $e');
      _byCodename = const <String, KnownDevice>{};
      _codenameByModel = const <String, String>{};
    }
    _loaded = true;
    _loading = null;
  }

  /// Looks up a codename or a retail model number, applying the same alias
  /// fallbacks as on-device detection.
  KnownDevice? lookup(String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty || _byCodename.isEmpty) return null;

    for (final String candidate in codenameCandidates(q)) {
      final KnownDevice? hit = _byCodename[candidate];
      if (hit != null) return hit;
    }
    final String? viaModel = _codenameByModel[q];
    if (viaModel != null) return _byCodename[viaModel];
    return null;
  }

  @visibleForTesting
  void seed(Iterable<KnownDevice> devices) {
    _byCodename = <String, KnownDevice>{
      for (final KnownDevice d in devices) d.codename.toLowerCase(): d,
    };
    _codenameByModel = <String, String>{
      for (final KnownDevice d in devices)
        for (final String m in d.models) m.toLowerCase(): d.codename.toLowerCase(),
    };
    _loaded = true;
  }
}

class _ParsedIndex {
  const _ParsedIndex(this.byCodename, this.codenameByModel);
  final Map<String, KnownDevice> byCodename;
  final Map<String, String> codenameByModel;
}

_ParsedIndex _parseIndex(String raw) {
  final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
  final Map<String, KnownDevice> byCodename = <String, KnownDevice>{};
  final Map<String, String> byModel = <String, String>{};
  json.forEach((String codename, dynamic value) {
    final Map<String, dynamic> m = value as Map<String, dynamic>;
    final List<String> models = <String>[
      for (final dynamic x in (m['m'] as List<dynamic>? ?? const <dynamic>[]))
        x.toString(),
    ];
    byCodename[codename] = KnownDevice(
      codename: codename,
      brand: (m['b'] as String?) ?? '',
      name: (m['n'] as String?) ?? '',
      models: models,
    );
    for (final String model in models) {
      byModel.putIfAbsent(model.toLowerCase(), () => codename);
    }
  });
  return _ParsedIndex(byCodename, byModel);
}
