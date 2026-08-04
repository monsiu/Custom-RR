import 'package:custom_rr/widgets/whats_new.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WhatsNewController.shouldShowFor', () {
    test('stays quiet on a fresh install (no recorded version)', () {
      expect(
        WhatsNewController.shouldShowFor(lastSeen: null, current: '1.3.7'),
        isFalse,
      );
    });

    test('stays quiet when the version has not changed', () {
      expect(
        WhatsNewController.shouldShowFor(lastSeen: '1.3.7', current: '1.3.7'),
        isFalse,
      );
    });

    test('arms after an update to a new version', () {
      expect(
        WhatsNewController.shouldShowFor(lastSeen: '1.3.6', current: '1.3.7'),
        isTrue,
      );
    });
  });

  test('highlights are non-empty and concise', () {
    expect(kWhatsNewHighlights, isNotEmpty);
    expect(kWhatsNewHighlights.length, lessThanOrEqualTo(4));
    for (final String item in kWhatsNewHighlights) {
      expect(item.trim(), isNotEmpty);
    }
  });
}
