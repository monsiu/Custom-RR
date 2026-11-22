import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/sync_catalog.dart'
    show writeCatalogIfChanged, degradedSourcesSummary, strictSourcesExitCode;

void main() {
  late Directory tempDirectory;
  late File catalogFile;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('custom_rr_catalog_');
    catalogFile = File('${tempDirectory.path}/catalog.json');
  });

  tearDown(() {
    tempDirectory.deleteSync(recursive: true);
  });

  test('semantic no-op preserves catalog bytes', () {
    final Map<String, dynamic> existing = <String, dynamic>{
      '_generated': 'tool/sync_catalog.dart',
      '_generatedAt': '2026-07-01T00:00:00.000Z',
      'roms': <Map<String, String>>[
        <String, String>{'id': 'lineage', 'name': 'LineageOS'},
      ],
    };
    final Map<String, dynamic> next = <String, dynamic>{
      ...existing,
      '_generatedAt': '2026-07-17T00:00:00.000Z',
    };
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    final String original = '${encoder.convert(existing)}\n';
    catalogFile.writeAsStringSync(original);

    expect(writeCatalogIfChanged(catalogFile, next), isFalse);
    expect(catalogFile.readAsStringSync(), original);
  });

  test('semantic change rewrites catalog', () {
    catalogFile.writeAsStringSync('''
{
  "_generated": "tool/sync_catalog.dart",
  "_generatedAt": "2026-07-01T00:00:00.000Z",
  "roms": []
}
''');
    final Map<String, dynamic> next = <String, dynamic>{
      '_generated': 'tool/sync_catalog.dart',
      '_generatedAt': '2026-07-17T00:00:00.000Z',
      'roms': <Map<String, String>>[
        <String, String>{'id': 'lineage', 'name': 'LineageOS'},
      ],
    };

    expect(writeCatalogIfChanged(catalogFile, next), isTrue);
    expect(
      (jsonDecode(catalogFile.readAsStringSync())
          as Map<String, dynamic>)['roms'],
      isNotEmpty,
    );
  });

  group('source health tripwire', () {
    test('clean run produces no summary and exit code 0', () {
      expect(degradedSourcesSummary(const <String>[]), isEmpty);
      expect(strictSourcesExitCode(const <String>[], strict: true), 0);
      expect(strictSourcesExitCode(const <String>[], strict: false), 0);
    });

    test('a parse failure is only fatal under --strict-sources', () {
      final List<String> failures = <String>['https://example.test/devices.json'];
      // Default: surface it, but do not fail (keeps the drift check and local
      // runs working even while an upstream source is broken).
      expect(strictSourcesExitCode(failures, strict: false), 0);
      // Strict: fail so the weekly sync notices instead of shipping a catalog
      // that is silently missing that source's devices.
      expect(strictSourcesExitCode(failures, strict: true), 3);
    });

    test('summary names every degraded source', () {
      final String summary = degradedSourcesSummary(
        <String>['https://a.test/x.json', 'https://b.test/y.json'],
      );
      expect(summary, contains('2 source(s)'));
      expect(summary, contains('https://a.test/x.json'));
      expect(summary, contains('https://b.test/y.json'));
    });
  });
}