import 'dart:convert';
import 'dart:io';

import 'package:custom_rr/models.dart';
import 'package:custom_rr/util/codename_aliases.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors the ranking in FindPhonePage._search. Kept here so the behaviour is
/// pinned by tests without pumping the whole widget tree.
List<DeviceRef> search(List<DeviceRef> all, String rawQuery) {
  final String q = rawQuery.trim().toLowerCase();
  if (q.isEmpty) return const <DeviceRef>[];
  final List<String> candidates = codenameCandidates(q);
  final List<(int, DeviceRef)> scored = <(int, DeviceRef)>[];
  for (final DeviceRef d in all) {
    final String codename = d.codename.toLowerCase();
    final Iterable<String> numbers = d.models.map((String m) => m.toLowerCase());
    int score = -1;
    if (numbers.any((String m) => m == q)) {
      score = 0;
    } else if (candidates
        .any((String c) => catalogCodenameMatches(codename, c))) {
      score = 1;
    } else if (numbers.any((String m) => m.contains(q))) {
      score = 2;
    } else if (codename.contains(q)) {
      score = 3;
    } else if (d.model.toLowerCase().contains(q)) {
      score = 4;
    } else if (d.brand.toLowerCase().contains(q)) {
      score = 5;
    }
    if (score >= 0) scored.add((score, d));
  }
  scored.sort(((int, DeviceRef) a, (int, DeviceRef) b) {
    if (a.$1 != b.$1) return a.$1.compareTo(b.$1);
    return a.$2.model.toLowerCase().compareTo(b.$2.model.toLowerCase());
  });
  return scored.map(((int, DeviceRef) e) => e.$2).toList();
}

void main() {
  final List<DeviceRef> catalogDevices = <DeviceRef>[];

  setUpAll(() {
    final Map<String, dynamic> raw =
        jsonDecode(File('assets/catalog.json').readAsStringSync())
            as Map<String, dynamic>;
    final Map<String, DeviceRef> seen = <String, DeviceRef>{};
    for (final String section in <String>['roms', 'recoveries']) {
      for (final dynamic e in raw[section] as List<dynamic>) {
        for (final dynamic d in (e as Map<String, dynamic>)['devices']
                as List<dynamic>? ??
            const <dynamic>[]) {
          final DeviceRef ref =
              DeviceRef.fromJson(d as Map<String, dynamic>);
          if (ref.codename.isEmpty) continue;
          seen.putIfAbsent('${ref.brand}|${ref.codename}', () => ref);
        }
      }
    }
    catalogDevices.addAll(seen.values);
  });

  group('device search (real catalog)', () {
    test('a phone that reports an alias codename still finds its build', () {
      // A Redmi 8 reports `olive`, but every project builds it as `mi439`.
      final List<DeviceRef> hits = search(catalogDevices, 'olive');
      expect(hits, isNotEmpty,
          reason: 'searching the reported codename must not dead-end');
      expect(hits.first.codename.toLowerCase(), 'mi439');
    });

    test('realme regional suffixes resolve to the published codename', () {
      final List<DeviceRef> hits = search(catalogDevices, 'rmx2151l1');
      expect(hits, isNotEmpty);
      expect(hits.first.codename.toLowerCase(), contains('rmx2151'));
    });

    test('stock OnePlus marketing codename resolves', () {
      final List<DeviceRef> hits = search(catalogDevices, 'OnePlus6T');
      expect(hits, isNotEmpty);
      expect(hits.first.codename.toLowerCase(), 'fajita');
    });

    test('retail model numbers are searchable and rank first', () {
      final List<DeviceRef> hits = search(catalogDevices, 'SM-A525F');
      expect(hits, isNotEmpty,
          reason: 'people search the number printed on the box');
      expect(hits.first.models.map((String m) => m.toLowerCase()),
          contains('sm-a525f'));
    });

    test('an exact codename outranks a substring match', () {
      final List<DeviceRef> hits = search(catalogDevices, 'raven');
      expect(hits.first.codename.toLowerCase(), 'raven');
    });

    test('unknown queries still return nothing', () {
      expect(search(catalogDevices, 'definitely-not-a-phone'), isEmpty);
    });
  });

  test('catalog carries retail model numbers', () {
    final int withModels =
        catalogDevices.where((DeviceRef d) => d.models.isNotEmpty).length;
    expect(withModels, greaterThan(200),
        reason: 'model numbers come from the LineageOS wiki models: field');
  });
}
