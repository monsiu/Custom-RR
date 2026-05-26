import 'package:custom_rr/data/freshness_repository.dart';
import 'package:custom_rr/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests for [FreshnessRepository] payload parsing. Uses
/// [FreshnessRepository.load]'s `overrideJson` hook so the tests stay
/// hermetic (no rootBundle, no HTTP, no SharedPreferences IO).
void main() {
  const String samplePayload = '''
{
  "entries": {
    "lineageos": {
      "status": "active",
      "lastBuild": "2026-05-20",
      "daysAgo": 3,
      "version": "21",
      "source": "https://example.test/lineageos"
    },
    "oldrom": {
      "status": "abandoned",
      "lastBuild": "2018-03-01",
      "daysAgo": 2900,
      "version": "8.1",
      "source": "https://example.test/oldrom"
    },
    "partial": {
      "status": "stale"
    }
  }
}
''';

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await FreshnessRepository.instance.load(overrideJson: samplePayload);
  });

  final FreshnessRepository repo = FreshnessRepository.instance;

  test('parses active entry with all fields', () {
    final FreshnessInfo info = repo.forId('lineageos');
    expect(info.status, FreshnessStatus.active);
    expect(info.lastBuild, '2026-05-20');
    expect(info.daysAgo, 3);
    expect(info.version, '21');
    expect(info.source, 'https://example.test/lineageos');
  });

  test('parses abandoned entry', () {
    final FreshnessInfo info = repo.forId('oldrom');
    expect(info.status, FreshnessStatus.abandoned);
    expect(info.daysAgo, 2900);
  });

  test('tolerates partial entries (missing optional fields)', () {
    final FreshnessInfo info = repo.forId('partial');
    expect(info.status, FreshnessStatus.stale);
    expect(info.lastBuild, '');
    expect(info.daysAgo, -1);
    expect(info.version, '');
    expect(info.source, '');
  });

  test('unknown id returns FreshnessInfo.unknown sentinel', () {
    final FreshnessInfo info = repo.forId('does-not-exist');
    expect(info.status, FreshnessStatus.unknown);
    expect(info, same(FreshnessInfo.unknown));
  });

  group('FreshnessInfo.relativeBuilt', () {
    test('today / yesterday / days', () {
      expect(_info(daysAgo: 0).relativeBuilt, 'today');
      expect(_info(daysAgo: 1).relativeBuilt, 'yesterday');
      expect(_info(daysAgo: 5).relativeBuilt, '5 days ago');
      expect(_info(daysAgo: 29).relativeBuilt, '29 days ago');
    });

    test('months', () {
      expect(_info(daysAgo: 30).relativeBuilt, '1 month ago');
      expect(_info(daysAgo: 60).relativeBuilt, '2 months ago');
      expect(_info(daysAgo: 200).relativeBuilt, '7 months ago');
    });

    test('years', () {
      expect(_info(daysAgo: 365).relativeBuilt, '1 year ago');
      expect(_info(daysAgo: 800).relativeBuilt, '2 years ago');
    });

    test('negative is unknown', () {
      expect(_info(daysAgo: -1).relativeBuilt, 'unknown');
    });
  });

  group('FreshnessStatus.parse', () {
    test('canonical values', () {
      expect(FreshnessStatus.parse('active'), FreshnessStatus.active);
      expect(FreshnessStatus.parse('stale'), FreshnessStatus.stale);
      expect(FreshnessStatus.parse('abandoned'), FreshnessStatus.abandoned);
    });
    test('null / unrecognised fall back to unknown', () {
      expect(FreshnessStatus.parse(null), FreshnessStatus.unknown);
      expect(FreshnessStatus.parse(''), FreshnessStatus.unknown);
      expect(FreshnessStatus.parse('garbage'), FreshnessStatus.unknown);
    });
  });
}

FreshnessInfo _info({required int daysAgo}) => FreshnessInfo(
      status: FreshnessStatus.active,
      lastBuild: '',
      daysAgo: daysAgo,
      version: '',
      source: '',
    );
