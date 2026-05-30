import 'dart:io';

import 'package:custom_rr/data/catalog_repository.dart';
import 'package:custom_rr/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final String json = File('assets/catalog.json').readAsStringSync();
    await CatalogRepository.instance.load(overrideJson: json);
  });

  final CatalogRepository repo = CatalogRepository.instance;

  test('every ROM has a name, tagline, and URL', () {
    for (final CatalogEntry e in repo.roms) {
      expect(e.name.isNotEmpty, isTrue, reason: 'ROM ${e.id} missing name');
      expect(
        e.shortTagline.isNotEmpty,
        isTrue,
        reason: 'ROM ${e.id} missing tagline',
      );
      expect(
        e.downloadUrl.isNotEmpty,
        isTrue,
        reason: 'ROM ${e.id} missing URL',
      );
    }
  });

  test('every recovery has a name, tagline, and URL', () {
    for (final CatalogEntry e in repo.recoveries) {
      expect(e.name.isNotEmpty, isTrue);
      expect(e.shortTagline.isNotEmpty, isTrue);
      expect(e.downloadUrl.isNotEmpty, isTrue);
    }
  });

  test('every device has a name and image asset', () {
    for (final DeviceEntry d in repo.devices) {
      expect(d.name.isNotEmpty, isTrue);
      expect(d.imageAsset.isNotEmpty, isTrue);
    }
  });

  test('all referenced image assets exist on disk', () {
    final Iterable<String> assets = <String>[
      for (final CatalogEntry e in repo.roms) e.headerAsset,
      for (final CatalogEntry e in repo.recoveries) e.headerAsset,
      for (final DeviceEntry d in repo.devices) d.imageAsset,
      // Bundled-asset screenshots (non-http entries) must exist too.
      for (final CatalogEntry e in repo.roms)
        for (final String s in e.screenshots)
          if (!s.startsWith('http')) s,
      for (final CatalogEntry e in repo.recoveries)
        for (final String s in e.screenshots)
          if (!s.startsWith('http')) s,
    ];
    for (final String path in assets) {
      expect(
        File(path).existsSync(),
        isTrue,
        reason: 'Missing asset on disk: $path',
      );
    }
  });

  test('catalog entry ids are unique within each section', () {
    final Set<String> romIds = <String>{};
    for (final CatalogEntry e in repo.roms) {
      expect(romIds.add(e.id), isTrue, reason: 'Duplicate rom id ${e.id}');
    }
    final Set<String> recIds = <String>{};
    for (final CatalogEntry e in repo.recoveries) {
      expect(recIds.add(e.id), isTrue, reason: 'Duplicate recovery id ${e.id}');
    }
  });

  test('every device reference resolves to a real manufacturer', () {
    final Set<String> deviceNames =
        repo.devices.map((DeviceEntry d) => d.name).toSet();
    for (final CatalogEntry e in <CatalogEntry>[
      ...repo.roms,
      ...repo.recoveries,
    ]) {
      for (final DeviceRef d in e.devices) {
        expect(
          deviceNames.contains(d.brand),
          isTrue,
          reason: '${e.id} references unknown manufacturer "${d.brand}"',
        );
        expect(
          d.model.isNotEmpty,
          isTrue,
          reason: '${e.id} has a device with empty model',
        );
      }
    }
  });

  test('device slug round-trips through repository lookup', () {
    for (final DeviceEntry d in repo.devices) {
      final DeviceEntry? found = repo.deviceBySlug(d.slug);
      expect(found, isNotNull, reason: 'No device for slug ${d.slug}');
      expect(found!.name, d.name);
    }
  });

  test('romById and recoveryById find every entry', () {
    for (final CatalogEntry e in repo.roms) {
      expect(repo.romById(e.id)?.id, e.id);
    }
    for (final CatalogEntry e in repo.recoveries) {
      expect(repo.recoveryById(e.id)?.id, e.id);
    }
  });
}
