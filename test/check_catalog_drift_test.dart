import 'package:flutter_test/flutter_test.dart';

import '../tool/check_catalog_drift.dart' show structuralDrift, deviceCount, catalogShape;

Map<String, dynamic> catalog({
  required String romName,
  required List<String> lineageDevices,
}) =>
    <String, dynamic>{
      '_generated': 'tool/sync_catalog.dart',
      '_generatedAt': '2026-11-22T00:00:00.000Z',
      'roms': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'lineage',
          'name': romName,
          'description': 'AOSP-based',
          'devices': <Map<String, dynamic>>[
            for (final String d in lineageDevices)
              <String, dynamic>{'codename': d, 'models': <String>['M-$d']},
          ],
        },
      ],
      // Top-level vendor roster, derived from upstream; must be ignored.
      'devices': <String>['Acme', 'Globex'],
    };

void main() {
  test('device-list churn is not structural drift (the flaky case)', () {
    final Map<String, dynamic> committed =
        catalog(romName: 'LineageOS', lineageDevices: <String>['a', 'b', 'c']);
    // Upstream grew by one device and the vendor roster shifted; a transient
    // scrape could just as easily have dropped devices. Neither is drift.
    final Map<String, dynamic> regenerated =
        catalog(romName: 'LineageOS', lineageDevices: <String>['a', 'b', 'c', 'd'])
          ..['devices'] = <String>['Acme'];
    expect(structuralDrift(committed, regenerated), isFalse);
    expect(deviceCount(committed), 3);
    expect(deviceCount(regenerated), 4);
  });

  test('a changed generated timestamp alone is not drift', () {
    final Map<String, dynamic> committed =
        catalog(romName: 'LineageOS', lineageDevices: <String>['a']);
    final Map<String, dynamic> regenerated =
        catalog(romName: 'LineageOS', lineageDevices: <String>['a'])
          ..['_generatedAt'] = '2027-01-01T00:00:00.000Z';
    expect(structuralDrift(committed, regenerated), isFalse);
  });

  test('a change to code-derived ROM metadata IS drift', () {
    final Map<String, dynamic> committed =
        catalog(romName: 'LineageOS', lineageDevices: <String>['a']);
    // Renaming a ROM comes from the generator, not upstream: it must be caught.
    final Map<String, dynamic> regenerated =
        catalog(romName: 'LineageOS (renamed)', lineageDevices: <String>['a']);
    expect(structuralDrift(committed, regenerated), isTrue);
  });

  test('shape drops the volatile device/models fields', () {
    final Object? shape =
        catalogShape(catalog(romName: 'LineageOS', lineageDevices: <String>['a', 'b']));
    final String encoded = shape.toString();
    expect(encoded, contains('lineage'));
    expect(encoded, isNot(contains('codename')));
    expect(encoded, isNot(contains('M-a')));
  });
}
