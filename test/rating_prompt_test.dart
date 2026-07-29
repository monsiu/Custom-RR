import 'package:custom_rr/widgets/rating_nudge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const int day = 24 * 60 * 60 * 1000;
  const int now = 1000 * day;

  bool ask({
    bool applicable = true,
    bool rated = false,
    bool dismissed = false,
    int happyMoments = 2,
    int nowMs = now,
    int snoozeUntilMs = 0,
    int sheetLastShownMs = 0,
  }) {
    return RatingNudge.shouldAskAfterHappyMoment(
      applicable: applicable,
      rated: rated,
      dismissed: dismissed,
      happyMoments: happyMoments,
      nowMs: nowMs,
      snoozeUntilMs: snoozeUntilMs,
      sheetLastShownMs: sheetLastShownMs,
    );
  }

  group('RatingNudge.shouldAskAfterHappyMoment', () {
    test('asks once enough happy moments accumulate', () {
      expect(ask(), isTrue);
    });

    test('never asks on non-Play builds', () {
      expect(ask(applicable: false), isFalse);
    });

    test('never asks again after rating or permanent dismissal', () {
      expect(ask(rated: true), isFalse);
      expect(ask(dismissed: true), isFalse);
    });

    test('waits for a couple of download opens first', () {
      expect(ask(happyMoments: 0), isFalse);
      expect(ask(happyMoments: 1), isFalse);
      expect(ask(happyMoments: 2), isTrue);
      expect(ask(happyMoments: 50), isTrue);
    });

    test('respects an active snooze', () {
      expect(ask(snoozeUntilMs: now + day), isFalse);
      expect(ask(snoozeUntilMs: now - day), isTrue);
      expect(ask(snoozeUntilMs: now), isTrue);
    });

    test('applies a cooldown between sheet showings', () {
      expect(ask(sheetLastShownMs: now - day), isFalse);
      expect(ask(sheetLastShownMs: now - 6 * day), isFalse);
      expect(ask(sheetLastShownMs: now - 7 * day), isTrue);
      expect(ask(sheetLastShownMs: now - 30 * day), isTrue);
    });
  });
}
