import 'dart:io';

import 'package:custom_rr/data/catalog_repository.dart';
import 'package:custom_rr/models.dart';
import 'package:custom_rr/util/codename_aliases.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('codenameCandidates', () {
    test('normalizes case and whitespace', () {
      expect(codenameCandidates('  FAJITA '), <String>['fajita']);
    });

    test('returns empty for blank input', () {
      expect(codenameCandidates(''), isEmpty);
      expect(codenameCandidates('   '), isEmpty);
    });

    test('strips Transsion vendor prefixes', () {
      expect(
        codenameCandidates('Infinix-X6833B'),
        <String>['infinix-x6833b', 'x6833b'],
      );
      expect(codenameCandidates('TECNO_KJ5'), contains('kj5'));
    });

    test('strips realme regional suffixes', () {
      expect(
        codenameCandidates('rmx2151l1'),
        <String>['rmx2151l1', 'rmx2151'],
      );
      // A bare model number stays as-is.
      expect(codenameCandidates('rmx2151'), <String>['rmx2151']);
    });

    test('maps unified-build and stock-name aliases last', () {
      expect(codenameCandidates('olive'), <String>['olive', 'mi439']);
      expect(codenameCandidates('OnePlus6T'), <String>['oneplus6t', 'fajita']);
    });

    test('unknown codenames produce only themselves', () {
      expect(codenameCandidates('weirdphone'), <String>['weirdphone']);
    });
  });

  group('catalogCodenameMatches', () {
    test('matches exact codenames', () {
      expect(catalogCodenameMatches('fajita', 'fajita'), isTrue);
      expect(catalogCodenameMatches('FAJITA', 'fajita'), isTrue);
      expect(catalogCodenameMatches('fajita', 'olive'), isFalse);
    });

    test('matches components of combined codenames', () {
      expect(catalogCodenameMatches('rmx2001/rmx2151', 'rmx2151'), isTrue);
      expect(catalogCodenameMatches('cheeseburger/dumpling', 'dumpling'),
          isTrue);
      expect(catalogCodenameMatches('G4, F500', 'f500'), isTrue);
      expect(catalogCodenameMatches('rmx2001/rmx2151', 'rmx2'), isFalse);
    });
  });

  group('deviceRefByCodenameOnly with aliases (real catalog)', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final String json = File('assets/catalog.json').readAsStringSync();
      await CatalogRepository.instance.load(overrideJson: json);
    });

    final CatalogRepository repo = CatalogRepository.instance;

    test('vendor-prefixed Infinix codename finds the catalog device', () {
      final DeviceRef? ref = repo.deviceRefByCodenameOnly('Infinix-X6833B');
      expect(ref, isNotNull);
      expect(ref!.codename.toLowerCase(), 'x6833b');
    });

    test('realme regional variant finds the combined TWRP device', () {
      final DeviceRef? ref = repo.deviceRefByCodenameOnly('rmx2151l1');
      expect(ref, isNotNull);
      expect(
        catalogCodenameMatches(ref!.codename, 'rmx2151'),
        isTrue,
        reason: 'expected a codename covering rmx2151, got ${ref.codename}',
      );
    });

    test('Redmi 8 (olive) resolves to the unified mi439 build', () {
      final DeviceRef? ref = repo.deviceRefByCodenameOnly('olive');
      expect(ref, isNotNull);
      expect(ref!.codename.toLowerCase(), 'mi439');
    });

    test('stock OnePlus6T resolves to fajita', () {
      final DeviceRef? ref = repo.deviceRefByCodenameOnly('OnePlus6T');
      expect(ref, isNotNull);
      expect(ref!.codename.toLowerCase(), 'fajita');
    });

    test('exact catalog codenames still match directly', () {
      final DeviceRef? ref = repo.deviceRefByCodenameOnly('fajita');
      expect(ref, isNotNull);
      expect(ref!.codename.toLowerCase(), 'fajita');
    });

    test('unknown codenames still return null', () {
      expect(repo.deviceRefByCodenameOnly('not-a-real-codename-xyz'), isNull);
    });
  });
}
