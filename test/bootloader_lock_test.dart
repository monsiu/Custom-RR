import 'package:custom_rr/util/bootloader_lock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bootloaderLockForModel', () {
    test('US carrier (U) models are locked', () {
      for (final String m in <String>['SM-A015U', 'SM-N981U', 'SM-S908U', 'SM-F711U', 'SM-G781U']) {
        final BootloaderLock? lock = bootloaderLockForModel(m);
        expect(lock, isNotNull, reason: '$m should be locked');
        expect(lock!.region, 'US');
      }
    });

    test('US unlocked (U1) models are still locked', () {
      final BootloaderLock? lock = bootloaderLockForModel('SM-A037U1');
      expect(lock, isNotNull);
      expect(lock!.region, 'US');
    });

    test('Canada (W) models are locked', () {
      final BootloaderLock? lock = bootloaderLockForModel('SM-G988W');
      expect(lock?.region, 'Canada');
    });

    test('US prepaid / Tracfone (SM-S…DL) models are locked', () {
      final BootloaderLock? lock = bootloaderLockForModel('SM-S111DL');
      expect(lock?.region, 'US prepaid');
    });

    test('legacy SAMSUNG- prefix is tolerated', () {
      expect(bootloaderLockForModel('SAMSUNG-SM-G930U'), isNotNull);
    });

    test('casing and whitespace do not matter', () {
      expect(bootloaderLockForModel('  sm-a015u '), isNotNull);
    });

    test('international Samsung variants unlock normally', () {
      for (final String m in <String>['SM-A015F', 'SM-A013M', 'SM-A037G', 'SM-G973F', 'SM-S908B']) {
        expect(bootloaderLockForModel(m), isNull, reason: '$m should not be flagged');
      }
    });

    test('non-Samsung model numbers are not flagged', () {
      for (final String m in <String>['CPH2653', 'RMX3939', 'Pixel 6', '2201116SG', '']) {
        expect(bootloaderLockForModel(m), isNull);
      }
    });

    test('Galaxy S23 US (SM-S911U) is locked but international (SM-S911B) is not', () {
      expect(bootloaderLockForModel('SM-S911U'), isNotNull);
      expect(bootloaderLockForModel('SM-S911B'), isNull);
    });
  });

  group('bootloaderLockForModels', () {
    test('flags a codename whose variant set includes a locked model', () {
      final BootloaderLock? lock = bootloaderLockForModels(<String>['SM-A015F', 'SM-A015U', 'SM-A015M']);
      expect(lock, isNotNull);
      expect(lock!.model, 'SM-A015U');
    });

    test('does not flag an all-international variant set', () {
      expect(bootloaderLockForModels(<String>['SM-A015F', 'SM-A015M', 'SM-A015G']), isNull);
    });

    test('empty set is null', () {
      expect(bootloaderLockForModels(const <String>[]), isNull);
    });
  });
}
