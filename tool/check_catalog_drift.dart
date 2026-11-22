// Verifies that the committed assets/catalog.json matches what
// tool/sync_catalog.dart would produce *right now*. Used in CI so a PR that
// edits sync_catalog.dart without regenerating the JSON fails fast.
//
// It compares only the parts of the catalog that come from the generator's own
// code (the ROM/recovery/root entries and their metadata), not the per-device
// `devices`/`models` lists, which are scraped live from upstream. Those lists
// change whenever upstream adds a device or a source times out mid-fetch, which
// is non-deterministic and has nothing to do with "did you regenerate the JSON
// after editing the generator". Comparing them made this check fail on routine
// upstream churn and on transient CI fetch hiccups. Device-list content is
// validated instead by the weekly sync-catalog PR and the source-health check.
//
// Usage:
//   dart run tool/check_catalog_drift.dart
//
// Exit codes:
//   0  structure in sync (device-list churn, if any, is reported but tolerated)
//   1  structural drift (a generator change was not committed)
//   2  internal error (couldn't run the sync script)

import 'dart:convert';
import 'dart:io';

/// The code-derived shape of the catalog: top-level keys and, for each section
/// entry, every field except the scraped `devices`/`models` lists. Also drops
/// the wall-clock `_generatedAt` and the top-level `devices` vendor roster,
/// both of which are derived from upstream and/or the clock.
Object? catalogShape(Map<String, dynamic> catalog) {
  final Map<String, dynamic> shape = <String, dynamic>{};
  for (final MapEntry<String, dynamic> e in catalog.entries) {
    if (e.key == '_generatedAt' || e.key == 'devices') continue;
    if (e.key == 'roms' || e.key == 'recoveries' || e.key == 'roots') {
      shape[e.key] = <dynamic>[
        for (final dynamic entry in (e.value as List<dynamic>? ?? const <dynamic>[]))
          _entryShape(entry),
      ];
    } else {
      shape[e.key] = e.value;
    }
  }
  return shape;
}

Object? _entryShape(dynamic entry) {
  if (entry is! Map<String, dynamic>) return entry;
  final Map<String, dynamic> out = <String, dynamic>{};
  for (final MapEntry<String, dynamic> e in entry.entries) {
    if (e.key == 'devices' || e.key == 'models') continue;
    out[e.key] = e.value;
  }
  return out;
}

/// Total number of device refs across the ROM/recovery sections. Used only to
/// describe the churn in the report, never to pass or fail.
int deviceCount(Map<String, dynamic> catalog) {
  int n = 0;
  for (final String section in <String>['roms', 'recoveries']) {
    for (final dynamic entry in (catalog[section] as List<dynamic>? ?? const <dynamic>[])) {
      if (entry is Map<String, dynamic>) {
        n += (entry['devices'] as List<dynamic>? ?? const <dynamic>[]).length;
      }
    }
  }
  return n;
}

/// True when the two catalogs differ in their code-derived structure.
bool structuralDrift(Map<String, dynamic> committed, Map<String, dynamic> regenerated) =>
    jsonEncode(catalogShape(committed)) != jsonEncode(catalogShape(regenerated));

Future<void> main() async {
  final File committed = File('assets/catalog.json');
  if (!committed.existsSync()) {
    stderr.writeln('check_catalog_drift: assets/catalog.json is missing');
    exit(2);
  }

  final String before = committed.readAsStringSync();

  final ProcessResult run = await Process.run(
    Platform.resolvedExecutable,
    <String>['run', 'tool/sync_catalog.dart'],
  );
  if (run.exitCode != 0) {
    stderr.writeln('check_catalog_drift: sync_catalog.dart failed');
    stderr.writeln(run.stdout);
    stderr.writeln(run.stderr);
    committed.writeAsStringSync(before);
    exit(2);
  }

  final String after = committed.readAsStringSync();
  // Always restore the committed file so we don't dirty the working tree.
  committed.writeAsStringSync(before);

  final Map<String, dynamic> a = jsonDecode(before) as Map<String, dynamic>;
  final Map<String, dynamic> b = jsonDecode(after) as Map<String, dynamic>;

  if (structuralDrift(a, b)) {
    stderr.writeln('check_catalog_drift: STRUCTURAL DRIFT detected.');
    stderr.writeln('  The ROM/recovery/root entries the generator produces no '
        'longer match the committed catalog.');
    stderr.writeln('  committed top-level keys: ${(a.keys.toList()..sort())}');
    stderr.writeln('  regenerated top-level keys: ${(b.keys.toList()..sort())}');
    stderr.writeln('');
    stderr.writeln('Run:');
    stderr.writeln('  dart run tool/sync_catalog.dart');
    stderr.writeln('and commit the updated assets/catalog.json.');
    exit(1);
  }

  final int committedDevices = deviceCount(a);
  final int regeneratedDevices = deviceCount(b);
  if (committedDevices != regeneratedDevices) {
    stdout.writeln('check_catalog_drift: structure in sync. Device lists differ '
        '($committedDevices committed vs $regeneratedDevices regenerated); this '
        'is upstream churn or an incomplete scrape and is tolerated here. The '
        'weekly sync-catalog PR owns refreshing device lists.');
  } else {
    stdout.writeln('check_catalog_drift: in sync.');
  }
}
