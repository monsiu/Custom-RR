import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/sync_catalog.dart' show writeCatalogIfChanged;

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
}