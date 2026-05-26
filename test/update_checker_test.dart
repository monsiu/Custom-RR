import 'package:custom_rr/data/update_checker.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pure unit tests for [UpdateChecker]'s version-comparison logic.
/// We exercise the @visibleForTesting helpers directly so we never hit
/// the GitHub API from CI.
void main() {
  group('UpdateChecker.stripLeadingV', () {
    test('removes lowercase v', () {
      expect(UpdateChecker.stripLeadingV('v1.2.3'), '1.2.3');
    });

    test('removes uppercase V', () {
      expect(UpdateChecker.stripLeadingV('V0.1.0'), '0.1.0');
    });

    test('leaves bare versions untouched', () {
      expect(UpdateChecker.stripLeadingV('1.2.3'), '1.2.3');
    });

    test('handles empty string', () {
      expect(UpdateChecker.stripLeadingV(''), '');
    });
  });

  group('UpdateChecker.isNewer', () {
    test('higher major is newer', () {
      expect(UpdateChecker.isNewer('2.0.0', '1.9.9'), isTrue);
    });

    test('higher minor is newer', () {
      expect(UpdateChecker.isNewer('1.3.0', '1.2.99'), isTrue);
    });

    test('higher patch is newer', () {
      expect(UpdateChecker.isNewer('1.2.4', '1.2.3'), isTrue);
    });

    test('same version is not newer', () {
      expect(UpdateChecker.isNewer('1.2.3', '1.2.3'), isFalse);
    });

    test('lower version is not newer', () {
      expect(UpdateChecker.isNewer('1.2.2', '1.2.3'), isFalse);
    });

    test('missing components treated as zero (newer side)', () {
      expect(UpdateChecker.isNewer('1.2', '1.1.9'), isTrue);
      expect(UpdateChecker.isNewer('2', '1.99.99'), isTrue);
    });

    test('missing components treated as zero (current side)', () {
      expect(UpdateChecker.isNewer('1.0.1', '1'), isTrue);
      expect(UpdateChecker.isNewer('1.0.0', '1'), isFalse);
    });

    test('build / pre-release suffixes are ignored', () {
      expect(UpdateChecker.isNewer('1.2.3+5', '1.2.3'), isFalse);
      expect(UpdateChecker.isNewer('1.2.4-rc1', '1.2.3'), isTrue);
      expect(UpdateChecker.isNewer('1.2.3-rc1', '1.2.3+9'), isFalse);
    });

    test('non-numeric segments fall back to zero', () {
      expect(UpdateChecker.isNewer('1.2.junk', '1.2.0'), isFalse);
      expect(UpdateChecker.isNewer('1.3.junk', '1.2.99'), isTrue);
    });

    test('empty latest is never newer', () {
      expect(UpdateChecker.isNewer('', '0.1.0'), isFalse);
      expect(UpdateChecker.isNewer('', ''), isFalse);
    });
  });
}
