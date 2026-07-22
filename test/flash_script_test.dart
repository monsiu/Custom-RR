import 'package:custom_rr/models.dart';
import 'package:custom_rr/pages/flash_script_page.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pure unit tests for the flash-script builders. They take explicit
/// parameters (no widget state, no catalog singleton) so we can assert the
/// generated shell text directly. These guard the kind of bug that slipped in
/// before: non-contiguous step numbering when options were toggled.
void main() {
  CatalogEntry entry(String id, String name, String url) => CatalogEntry(
        id: id,
        name: name,
        headerAsset: '',
        shortTagline: '',
        downloadUrl: url,
      );

  final CatalogEntry rom =
      entry('lineageos', 'LineageOS', 'https://download.lineageos.org');
  final CatalogEntry recovery =
      entry('twrp', 'TWRP', 'https://twrp.me/devices');

  /// Extracts the `#   N)` step numbers from a generated script, in order.
  List<int> stepNumbers(String script) {
    final RegExp re = RegExp(r'^#\s+(\d+)\)', multiLine: true);
    return re
        .allMatches(script)
        .map((RegExpMatch m) => int.parse(m.group(1)!))
        .toList();
  }

  group('buildFlashScript step numbering is always contiguous', () {
    for (final bool gapps in <bool>[true, false]) {
      for (final bool magisk in <bool>[true, false]) {
        for (final bool wipe in <bool>[true, false]) {
          test('gapps=$gapps magisk=$magisk wipe=$wipe', () {
            final String script = buildFlashScript(
              brand: 'Google',
              codename: 'sunfish',
              rom: rom,
              recovery: recovery,
              wantsGapps: gapps,
              wantsMagisk: magisk,
              wipeData: wipe,
            );
            final List<int> steps = stepNumbers(script);
            expect(steps, isNotEmpty);
            expect(
              steps,
              List<int>.generate(steps.length, (int i) => i + 1),
              reason: 'step numbers must run 1..n with no gaps or repeats',
            );
          });
        }
      }
    }
  });

  group('buildFlashScript content', () {
    test('header carries the device brand and codename', () {
      final String script = buildFlashScript(
        brand: 'Google',
        codename: 'sunfish',
        rom: rom,
        recovery: recovery,
        wantsGapps: true,
        wantsMagisk: false,
        wipeData: true,
      );
      expect(script, contains('# Device : Google sunfish'));
    });

    test('uses wait_fastboot instead of a fixed sleep', () {
      final String script = buildFlashScript(
        brand: 'Google',
        codename: 'sunfish',
        rom: rom,
        recovery: recovery,
        wantsGapps: true,
        wantsMagisk: false,
        wipeData: true,
      );
      expect(script, contains('wait_fastboot'));
      expect(script, isNot(contains('sleep 8')));
    });

    test('gapps and magisk lines follow their toggles', () {
      final String withExtras = buildFlashScript(
        brand: 'Google',
        codename: 'sunfish',
        rom: rom,
        recovery: recovery,
        wantsGapps: true,
        wantsMagisk: true,
        wipeData: true,
      );
      expect(withExtras, contains('gapps.zip'));
      expect(withExtras, contains('magisk.zip'));
      expect(withExtras, contains(kMagiskReleasesUrl));

      final String none = buildFlashScript(
        brand: 'Google',
        codename: 'sunfish',
        rom: rom,
        recovery: recovery,
        wantsGapps: false,
        wantsMagisk: false,
        wipeData: true,
      );
      expect(none, isNot(contains('gapps.zip')));
      expect(none, isNot(contains('magisk.zip')));
    });
  });

  group('buildFlashScript Samsung flow', () {
    String samsungScript() => buildFlashScript(
          brand: 'Samsung',
          codename: 'a52q',
          rom: rom,
          recovery: recovery,
          wantsGapps: true,
          wantsMagisk: false,
          wipeData: true,
        );

    test('uses Download mode + Heimdall instead of fastboot', () {
      final String script = samsungScript();
      expect(script, contains('adb reboot download'));
      expect(script, contains('wait_download'));
      expect(script, contains('heimdall flash --RECOVERY'));
      // The fastboot recovery flow must NOT be handed to a Samsung device.
      expect(script, isNot(contains('adb reboot bootloader')));
      expect(script, isNot(contains('fastboot boot recovery.img')));
      expect(script, isNot(contains('wait_fastboot')));
    });

    test('step numbering stays contiguous on the Samsung path', () {
      final List<int> steps = stepNumbers(samsungScript());
      expect(steps, isNotEmpty);
      expect(
        steps,
        List<int>.generate(steps.length, (int i) => i + 1),
        reason: 'step numbers must run 1..n with no gaps or repeats',
      );
    });

    test('non-Samsung brands keep the fastboot flow', () {
      final String script = buildFlashScript(
        brand: 'Google',
        codename: 'sunfish',
        rom: rom,
        recovery: recovery,
        wantsGapps: true,
        wantsMagisk: false,
        wipeData: true,
      );
      expect(script, contains('adb reboot bootloader'));
      expect(script, contains('fastboot boot recovery.img'));
      expect(script, isNot(contains('heimdall')));
    });
  });

  group('buildFlashScript brand profiles', () {
    String scriptFor(String brand, {String codename = 'device'}) =>
        buildFlashScript(
          brand: brand,
          codename: codename,
          rom: rom,
          recovery: recovery,
          wantsGapps: true,
          wantsMagisk: true,
          wipeData: true,
        );

    test('Xiaomi keeps fastboot but adds Mi Unlock + anti-rollback', () {
      final String s = scriptFor('Xiaomi', codename: 'sweet');
      expect(s, contains('Mi Unlock'));
      expect(s, contains('Anti-rollback'));
      expect(s, contains('adb reboot bootloader'));
      expect(s, contains('fastboot boot recovery.img'));
      expect(s, isNot(contains('adb reboot download')));
      expect(s, isNot(contains('heimdall')));
    });

    test('Redmi and POCO share the Xiaomi profile', () {
      for (final String brand in <String>['Redmi', 'POCO']) {
        expect(scriptFor(brand), contains('Mi Unlock'),
            reason: '$brand should use the Mi Unlock flow');
      }
    });

    test('Motorola documents get_unlock_data', () {
      final String s = scriptFor('Motorola');
      expect(s, contains('fastboot oem get_unlock_data'));
      expect(s, contains('fastboot oem unlock <CODE>'));
      expect(s, contains('fastboot boot recovery.img'));
    });

    test('Sony documents the Open Devices code and DRM caution', () {
      final String s = scriptFor('Sony');
      expect(s, contains('Open Devices'));
      expect(s, contains('fastboot oem unlock 0x<CODE>'));
      expect(s, contains('DRM'));
    });

    test('realme documents the Deep Testing unlock app', () {
      final String s = scriptFor('realme');
      expect(s, contains('Deep Testing'));
      expect(s, contains('fastboot flashing unlock'));
    });

    test('an unlisted brand uses the standard fastboot unlock', () {
      final String s = scriptFor('OnePlus');
      expect(s, contains('fastboot flashing unlock'));
      expect(s, contains('adb reboot bootloader'));
      expect(s, isNot(contains('heimdall')));
      expect(s, isNot(contains('Mi Unlock')));
    });

    test('step numbering stays contiguous across brand profiles', () {
      for (final String brand in <String>[
        'Xiaomi',
        'Motorola',
        'Sony',
        'realme',
        'OnePlus',
        'Samsung',
      ]) {
        final List<int> steps = stepNumbers(scriptFor(brand));
        expect(steps, isNotEmpty, reason: '$brand should have steps');
        expect(
          steps,
          List<int>.generate(steps.length, (int i) => i + 1),
          reason: '$brand step numbers must run 1..n',
        );
      }
    });
  });

  group('buildGsiScript', () {
    test('targets the brand, never a specific device model', () {
      final String script = buildGsiScript(
        brand: 'Google',
        recovery: null,
        wantsGapps: false,
        wantsMagisk: false,
        wipeData: true,
      );
      expect(script, contains('# Target : Google Project Treble device'));
      // The per-device script signature must not appear in the GSI flow.
      expect(script, isNot(contains('# Device :')));
    });

    test('empty brand still produces a valid generic target', () {
      final String script = buildGsiScript(
        brand: null,
        recovery: null,
        wantsGapps: false,
        wantsMagisk: false,
        wipeData: true,
      );
      expect(script, contains('# Target : Any Project Treble device'));
    });

    test('non-Samsung flow has no custom recovery and patches boot.img', () {
      final String script = buildGsiScript(
        brand: 'Google',
        recovery: null,
        wantsGapps: true,
        wantsMagisk: true,
        wipeData: true,
      );
      expect(script, contains('installs NO custom recovery'));
      expect(script, contains('fastboot flash boot magisk_patched.img'));
      expect(script, isNot(contains('wait_download')));
    });

    test('Samsung flow uses Download mode and wait_download', () {
      final String script = buildGsiScript(
        brand: 'Samsung',
        recovery: recovery,
        wantsGapps: false,
        wantsMagisk: false,
        wipeData: true,
      );
      expect(script, contains('adb reboot download'));
      expect(script, contains('wait_download'));
      expect(script, contains('heimdall flash --RECOVERY'));
    });

    test('brand cautions surface in the GSI flow (Xiaomi ARB, Sony DRM)', () {
      final String xiaomi = buildGsiScript(
        brand: 'Xiaomi',
        recovery: null,
        wantsGapps: false,
        wantsMagisk: false,
        wipeData: true,
      );
      expect(xiaomi, contains('Anti-rollback'));
      final String sony = buildGsiScript(
        brand: 'Sony',
        recovery: null,
        wantsGapps: false,
        wantsMagisk: false,
        wipeData: true,
      );
      expect(sony, contains('DRM'));
    });

    test('uses wait helpers instead of a fixed sleep', () {
      final String script = buildGsiScript(
        brand: 'Google',
        recovery: null,
        wantsGapps: false,
        wantsMagisk: false,
        wipeData: true,
      );
      expect(script, contains('wait_fastboot'));
      expect(script, isNot(contains('sleep 8')));
    });
  });
}
