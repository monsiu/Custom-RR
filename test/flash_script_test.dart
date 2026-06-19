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
