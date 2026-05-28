/// Data models for ROMs, recoveries, and devices listed in Custom RR
/// (https://github.com/monsiu/Custom-RR).
library;

class CatalogEntry {
  const CatalogEntry({
    required this.id,
    required this.name,
    required this.headerAsset,
    required this.shortTagline,
    this.description = const <String>[],
    this.features = const <String>[],
    this.screenshots = const <String>[],
    this.devices = const <DeviceRef>[],
    this.downloadLabel = 'Official Builds',
    required this.downloadUrl,
    this.forumUrl = '',
    this.warning = '',
    this.links = const <CatalogLink>[],
  });

  final String id;
  final String name;
  final String headerAsset;
  final String shortTagline;
  final List<String> description;
  final List<String> features;
  final List<String> screenshots;

  /// Concrete phone models that this entry supports. Each entry pairs a
  /// manufacturer ([DeviceEntry.name]) with a phone model and codename so
  /// the Device page can list real devices, not just brands.
  final List<DeviceRef> devices;

  final String downloadLabel;
  final String downloadUrl;

  /// Optional link to a community discussion page for this ROM/recovery,
  /// typically an XDA Developers forum category or a curated thread.
  /// Empty string when not set. Surfaced on the detail page as a
  /// "Discuss on XDA" button.
  final String forumUrl;

  /// Optional prominent warning shown above the description on the detail
  /// page. Use to flag credibility concerns, abandoned projects served
  /// from a Wayback mirror, or community controversies. Empty when none.
  final String warning;

  /// Optional curated links rendered as clickable chips on the detail
  /// page, between the description and the Key Features section. Use for
  /// project Telegram channels, GitHub orgs, devices pages, etc.
  final List<CatalogLink> links;

  /// Distinct manufacturer names from [devices]. Used to filter ROMs/recoveries
  /// on the manufacturer-level Device page.
  List<String> get supportedManufacturers {
    final Set<String> seen = <String>{};
    for (final DeviceRef d in devices) {
      seen.add(d.brand);
    }
    return seen.toList(growable: false);
  }

  factory CatalogEntry.fromJson(Map<String, dynamic> json) {
    return CatalogEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      headerAsset: json['headerAsset'] as String,
      shortTagline: json['shortTagline'] as String,
      description: _stringList(json['description']),
      features: _stringList(json['features']),
      screenshots: _stringList(json['screenshots']),
      devices: _deviceRefs(json['devices']),
      downloadLabel: (json['downloadLabel'] as String?) ?? 'Official Builds',
      downloadUrl: json['downloadUrl'] as String,
      forumUrl: (json['forumUrl'] as String?) ?? '',
      warning: (json['warning'] as String?) ?? '',
      links: _catalogLinks(json['links']),
    );
  }
}

/// A single phone model supported by a ROM or recovery.
class DeviceRef {
  const DeviceRef({
    required this.brand,
    required this.model,
    this.codename = '',
    this.url = '',
    this.forumUrl = '',
  });

  /// Manufacturer label that must match a [DeviceEntry.name].
  final String brand;

  /// Marketing name of the phone (e.g. "Pixel 6", "Mi 11", "OnePlus 9").
  final String model;

  /// Internal codename used by ROM projects (e.g. "oriole", "venus").
  final String codename;

  /// Optional direct deep link to the per-device download page upstream.
  final String url;

  /// Optional link to a per-device community discussion thread, typically
  /// the XDA Developers thread maintained by the device maintainer.
  final String forumUrl;

  factory DeviceRef.fromJson(Map<String, dynamic> json) {
    return DeviceRef(
      brand: json['brand'] as String,
      model: json['model'] as String,
      codename: (json['codename'] as String?) ?? '',
      url: (json['url'] as String?) ?? '',
      forumUrl: (json['forumUrl'] as String?) ?? '',
    );
  }
}

class DeviceEntry {
  const DeviceEntry({required this.name, required this.imageAsset});

  final String name;
  final String imageAsset;

  factory DeviceEntry.fromJson(Map<String, dynamic> json) {
    return DeviceEntry(
      name: json['name'] as String,
      imageAsset: json['imageAsset'] as String,
    );
  }

  /// Manufacturer name turned into a URL-safe slug for deep links.
  String get slug => name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'(^-|-$)'), '');
}

List<String> _stringList(Object? value) {
  if (value == null) return const <String>[];
  return (value as List<dynamic>).cast<String>();
}

List<DeviceRef> _deviceRefs(Object? value) {
  if (value == null) return const <DeviceRef>[];
  return (value as List<dynamic>)
      .map((dynamic e) => DeviceRef.fromJson(e as Map<String, dynamic>))
      .toList(growable: false);
}

List<CatalogLink> _catalogLinks(Object? value) {
  if (value == null) return const <CatalogLink>[];
  return (value as List<dynamic>)
      .map((dynamic e) => CatalogLink.fromJson(e as Map<String, dynamic>))
      .toList(growable: false);
}

/// A curated external link rendered as a clickable chip on a ROM or
/// recovery detail page. [iconName] is a small enum-style string
/// ('telegram', 'github', 'web', 'discord', 'matrix', 'forum') mapped to a
/// concrete Material icon at render time; empty falls back to a generic
/// link icon.
class CatalogLink {
  const CatalogLink({
    required this.label,
    required this.url,
    this.iconName = '',
  });

  final String label;
  final String url;
  final String iconName;

  factory CatalogLink.fromJson(Map<String, dynamic> json) {
    return CatalogLink(
      label: json['label'] as String,
      url: json['url'] as String,
      iconName: (json['iconName'] as String?) ?? '',
    );
  }
}

/// Build-freshness status for a catalog entry. Drives the colour and label
/// of the freshness badge shown on ROM/recovery cards and detail pages.
enum FreshnessStatus {
  active,
  stale,
  abandoned,
  unknown;

  static FreshnessStatus parse(String? raw) {
    switch (raw) {
      case 'active':
        return FreshnessStatus.active;
      case 'stale':
        return FreshnessStatus.stale;
      case 'abandoned':
        return FreshnessStatus.abandoned;
      default:
        return FreshnessStatus.unknown;
    }
  }
}

/// Latest-build information for a catalog entry (ROM or recovery).
class FreshnessInfo {
  const FreshnessInfo({
    required this.status,
    required this.lastBuild,
    required this.daysAgo,
    required this.version,
    required this.source,
  });

  final FreshnessStatus status;
  final String lastBuild;
  final int daysAgo;
  final String version;
  final String source;

  static const FreshnessInfo unknown = FreshnessInfo(
    status: FreshnessStatus.unknown,
    lastBuild: '',
    daysAgo: -1,
    version: '',
    source: '',
  );

  factory FreshnessInfo.fromJson(Map<String, dynamic> json) {
    return FreshnessInfo(
      status: FreshnessStatus.parse(json['status'] as String?),
      lastBuild: (json['lastBuild'] as String?) ?? '',
      daysAgo: (json['daysAgo'] as num?)?.toInt() ?? -1,
      version: (json['version'] as String?) ?? '',
      source: (json['source'] as String?) ?? '',
    );
  }

  /// Human label: "3 days ago", "6 months ago", etc.
  String get relativeBuilt {
    if (daysAgo < 0) return 'unknown';
    if (daysAgo == 0) return 'today';
    if (daysAgo == 1) return 'yesterday';
    if (daysAgo < 30) return '$daysAgo days ago';
    if (daysAgo < 365) {
      final int m = (daysAgo / 30).round();
      return '$m month${m == 1 ? '' : 's'} ago';
    }
    final int y = (daysAgo / 365).round();
    return '$y year${y == 1 ? '' : 's'} ago';
  }
}
