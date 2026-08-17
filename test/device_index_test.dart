import 'package:custom_rr/data/device_index.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceIndex (real bundled dictionary)', () {
    setUpAll(() async {
      await DeviceIndex.instance.load();
    });

    test('loads the bundled dictionary', () {
      expect(DeviceIndex.instance.isLoaded, isTrue);
      expect(DeviceIndex.instance.lookup('oriole'), isNotNull);
    });

    test('names a device the catalog has no build for', () {
      // The Galaxy Tab A8 has no maintained build, but a search for its
      // codename must still tell the user what their device is.
      final KnownDevice? d = DeviceIndex.instance.lookup('gta8');
      expect(d, isNotNull);
      expect(d!.label, contains('Galaxy Tab A8'));
      expect(d.models, contains('SM-X205'));
    });

    test('resolves a retail model number back to the device', () {
      final KnownDevice? d = DeviceIndex.instance.lookup('SM-X205');
      expect(d, isNotNull);
      expect(d!.codename, 'gta8');
    });

    test('applies codename aliases', () {
      expect(DeviceIndex.instance.lookup('Infinix-X6833B'), isNotNull);
    });

    test('returns null for nonsense', () {
      expect(DeviceIndex.instance.lookup('not-a-real-device'), isNull);
      expect(DeviceIndex.instance.lookup('   '), isNull);
    });
  });

  test('lookup is case and whitespace insensitive', () {
    DeviceIndex.instance.seed(<KnownDevice>[
      const KnownDevice(
        codename: 'gta8',
        brand: 'Samsung',
        name: 'Galaxy Tab A8',
        models: <String>['SM-X205'],
      ),
    ]);
    expect(DeviceIndex.instance.lookup('  GTA8 ')?.codename, 'gta8');
    expect(DeviceIndex.instance.lookup('sm-x205')?.codename, 'gta8');
  });
}
