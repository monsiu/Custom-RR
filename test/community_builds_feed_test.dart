import 'dart:convert';

import 'package:custom_rr/services/community_builds_feed.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pure unit tests for [CommunityBuildsFeed]'s parsing and junk-filtering.
/// We exercise the @visibleForTesting helpers directly so CI never hits the
/// OpenDesktop / Pling API.
void main() {
  String body(List<Map<String, dynamic>> data, {int total = 100}) {
    return jsonEncode(<String, dynamic>{
      'status': 'ok',
      'statuscode': 100,
      'totalitems': total,
      'itemsperpage': data.length,
      'data': data,
    });
  }

  group('parseResponse', () {
    test('maps the core fields of a ROM listing', () {
      final String json = body(
        <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1422395,
            'name': 'NusantaraROM - Lavender',
            'personid': 'andrraarp',
            'summary': 'NusantaraProject ROM for Redmi Note 7  (lavender)',
            'downloads': '214233',
            'score': 87,
            'changed': '2023-05-16T02:15:50+00:00',
            'detailpage': 'https://www.pling.com/p/1422395',
            'previewpic1': 'https://images.pling.com/x.png',
            'smallpreviewpic1': 'https://images.pling.com/small.png',
          },
        ],
        total: 3461,
      );

      final CommunityBuildsResult res = CommunityBuildsFeed.parseResponse(
        json,
        page: 0,
        pageSize: 20,
      );

      expect(res.totalItems, 3461);
      expect(res.builds, hasLength(1));
      final CommunityBuild b = res.builds.first;
      expect(b.id, 1422395);
      expect(b.name, 'NusantaraROM - Lavender');
      expect(b.maintainer, 'andrraarp');
      expect(b.downloads, 214233);
      expect(b.score, 87);
      expect(b.rating, closeTo(8.7, 0.001));
      expect(b.detailPage, 'https://www.pling.com/p/1422395');
      // Prefers the small preview when present.
      expect(b.previewImage, 'https://images.pling.com/small.png');
      // Summary whitespace is collapsed.
      expect(b.summary, 'NusantaraProject ROM for Redmi Note 7 (lavender)');
      expect(b.updated.year, 2023);
    });

    test('falls back to a constructed detail page when missing', () {
      final String json = body(<Map<String, dynamic>>[
        <String, dynamic>{'id': 999, 'name': 'Some ROM'},
      ]);
      final CommunityBuildsResult res = CommunityBuildsFeed.parseResponse(
        json,
        page: 0,
        pageSize: 20,
      );
      expect(res.builds.single.detailPage, 'https://www.pling.com/p/999');
      expect(res.builds.single.previewImage, isNull);
    });

    test('skips items with no id or empty name', () {
      final String json = body(<Map<String, dynamic>>[
        <String, dynamic>{'name': 'no id'},
        <String, dynamic>{'id': 5, 'name': ''},
        <String, dynamic>{'id': 6, 'name': 'Good ROM'},
      ]);
      final CommunityBuildsResult res = CommunityBuildsFeed.parseResponse(
        json,
        page: 0,
        pageSize: 20,
      );
      expect(res.builds, hasLength(1));
      expect(res.builds.single.name, 'Good ROM');
    });

    test('filters out recoveries and kernels mislabelled as ROMs', () {
      final String json = body(<Map<String, dynamic>>[
        <String, dynamic>{'id': 1, 'name': 'OrangeFox Recovery Project'},
        <String, dynamic>{'id': 2, 'name': 'TWRP for whyred'},
        <String, dynamic>{'id': 3, 'name': 'TOM Kernel', 'summary': 'kernel'},
        <String, dynamic>{'id': 4, 'name': 'crDroid Android'},
      ]);
      final CommunityBuildsResult res = CommunityBuildsFeed.parseResponse(
        json,
        page: 0,
        pageSize: 20,
      );
      expect(res.builds.map((CommunityBuild b) => b.name), <String>[
        'crDroid Android',
      ]);
      // totalItems stays the RAW api total so pagination still works.
      expect(res.totalItems, 100);
    });

    test('hasMore reflects the raw total, not the filtered count', () {
      final String json = body(
        <Map<String, dynamic>>[
          <String, dynamic>{'id': 1, 'name': 'A ROM'},
        ],
        total: 100,
      );
      final CommunityBuildsResult res = CommunityBuildsFeed.parseResponse(
        json,
        page: 0,
        pageSize: 20,
      );
      expect(res.hasMore, isTrue);

      final CommunityBuildsResult last = CommunityBuildsFeed.parseResponse(
        body(
          <Map<String, dynamic>>[
            <String, dynamic>{'id': 1, 'name': 'A ROM'},
          ],
          total: 10,
        ),
        page: 0,
        pageSize: 20,
      );
      expect(last.hasMore, isFalse);
    });
  });

  group('isLikelyNonRom', () {
    test('flags recoveries, kernels, gapps, magisk, wallpapers', () {
      expect(CommunityBuildsFeed.isLikelyNonRom('OrangeFox', ''), isTrue);
      expect(CommunityBuildsFeed.isLikelyNonRom('My TWRP', ''), isTrue);
      expect(CommunityBuildsFeed.isLikelyNonRom('A Kernel', ''), isTrue);
      expect(CommunityBuildsFeed.isLikelyNonRom('NikGapps', ''), isTrue);
      expect(CommunityBuildsFeed.isLikelyNonRom('Magisk module', ''), isTrue);
      expect(CommunityBuildsFeed.isLikelyNonRom('Cool Wallpaper', ''), isTrue);
    });

    test('keeps real ROM names', () {
      expect(CommunityBuildsFeed.isLikelyNonRom('crDroid Android', ''), isFalse);
      expect(
        CommunityBuildsFeed.isLikelyNonRom('NusantaraROM - Lavender', ''),
        isFalse,
      );
      expect(
        CommunityBuildsFeed.isLikelyNonRom('Pixel Experience', 'AOSP rom'),
        isFalse,
      );
    });
  });

  group('CommunityBuildSort', () {
    test('exposes the OCS sortmode values', () {
      expect(CommunityBuildSort.downloads.apiValue, 'down');
      expect(CommunityBuildSort.latest.apiValue, 'new');
      expect(CommunityBuildSort.rating.apiValue, 'high');
    });
  });

  group('extractDeviceTags', () {
    test('keeps device codenames and vendors, drops license/build noise', () {
      // From a real listing: NusantaraROM - X00T.
      final List<String> tags = CommunityBuildsFeed.extractDeviceTags(
        'apache-license,nusantara,official,original-product,asus,x00t',
        maintainer: 'andrraarp',
      );
      expect(tags, containsAll(<String>['asus', 'x00t']));
      expect(tags, isNot(contains('apache-license')));
      expect(tags, isNot(contains('official')));
      expect(tags, isNot(contains('original-product')));
    });

    test('drops the maintainer username', () {
      final List<String> tags = CommunityBuildsFeed.extractDeviceTags(
        'sonicbsv,crdroid,xiaomi,asus,x00td,gplv2-later,markw',
        maintainer: 'sonicbsv',
      );
      expect(tags, isNot(contains('sonicbsv')));
      expect(tags, isNot(contains('gplv2-later')));
      expect(tags, containsAll(<String>['xiaomi', 'asus', 'x00td', 'markw']));
    });

    test('returns empty when all tags are noise', () {
      expect(
        CommunityBuildsFeed.extractDeviceTags('apache-license,original-product'),
        isEmpty,
      );
      expect(CommunityBuildsFeed.extractDeviceTags(''), isEmpty);
    });

    test('de-duplicates and caps at six', () {
      final List<String> tags = CommunityBuildsFeed.extractDeviceTags(
        'redmi,redmi,a,b,c,d,e,f,g',
      );
      expect(tags.length, 6);
      expect(tags.where((String t) => t == 'redmi').length, 1);
    });

    test('parseResponse populates deviceTags', () {
      final String json = jsonEncode(<String, dynamic>{
        'totalitems': 1,
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'name': 'NusantaraROM - Whyred',
            'personid': 'andrraarp',
            'tags': 'apache-license,redmi,xiaomi,whyred,official',
          },
        ],
      });
      final CommunityBuildsResult res = CommunityBuildsFeed.parseResponse(
        json,
        page: 0,
        pageSize: 20,
      );
      expect(
        res.builds.single.deviceTags,
        containsAll(<String>['redmi', 'xiaomi', 'whyred']),
      );
    });
  });

  group('extractDeviceTagsFromDescription', () {
    test('pulls a single parenthetical codename', () {
      expect(
        CommunityBuildsFeed.extractDeviceTagsFromDescription(
          'Corvus OS for Poco F1 (beryllium)',
        ),
        <String>['beryllium'],
      );
    });

    test('pulls slash-separated codenames and lowercases them', () {
      expect(
        CommunityBuildsFeed.extractDeviceTagsFromDescription(
          'NusantaraProject ROM for Redmi Note 8 /8T Unified ( ginkgo / willow )',
        ),
        <String>['ginkgo', 'willow'],
      );
      expect(
        CommunityBuildsFeed.extractDeviceTagsFromDescription(
          'Corvus OS Official for Asus ZenFone Max Pro M1 (X00TD)',
        ),
        <String>['x00td'],
      );
    });

    test('strips HTML before parsing', () {
      expect(
        CommunityBuildsFeed.extractDeviceTagsFromDescription(
          '<p>Custom ROM for Redmi Note 7 ( lavender )</p>',
        ),
        <String>['lavender'],
      );
    });

    test('rejects multi-word and feature parentheticals', () {
      // "Quick Tap" has a space -> not a codename.
      expect(
        CommunityBuildsFeed.extractDeviceTagsFromDescription(
          'Awaken OS brings (Quick Tap) and more',
        ),
        isEmpty,
      );
      // "Redmi Note 7/7s": "Redmi Note 7" has spaces, "7s" is too short.
      expect(
        CommunityBuildsFeed.extractDeviceTagsFromDescription(
          'Custom Rom For Lavender ( Redmi Note 7/7s )',
        ),
        isEmpty,
      );
      // Build-type words in parens are filtered.
      expect(
        CommunityBuildsFeed.extractDeviceTagsFromDescription(
          'My ROM (Vanilla) (GApps) (Official)',
        ),
        isEmpty,
      );
    });

    test('returns empty for descriptions with no parentheticals', () {
      expect(
        CommunityBuildsFeed.extractDeviceTagsFromDescription(
          'A custom rom based on aosp',
        ),
        isEmpty,
      );
      expect(CommunityBuildsFeed.extractDeviceTagsFromDescription(''), isEmpty);
    });

    test('parseResponse falls back to description when tags are noise', () {
      final String json = jsonEncode(<String, dynamic>{
        'totalitems': 1,
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'name': 'corvus_whyred',
            'personid': 'corvusos',
            'tags': 'original-product,apache-license',
            'description': 'Corvus OS for Redmi Note 5 Pro (whyred)',
          },
        ],
      });
      final CommunityBuildsResult res = CommunityBuildsFeed.parseResponse(
        json,
        page: 0,
        pageSize: 20,
      );
      expect(res.builds.single.deviceTags, <String>['whyred']);
    });

    test('parseResponse prefers tags over description when tags have devices',
        () {
      final String json = jsonEncode(<String, dynamic>{
        'totalitems': 1,
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'name': 'Some ROM',
            'tags': 'redmi,lavender',
            'description': 'Some ROM for device (whyred)',
          },
        ],
      });
      final CommunityBuildsResult res = CommunityBuildsFeed.parseResponse(
        json,
        page: 0,
        pageSize: 20,
      );
      expect(res.builds.single.deviceTags, <String>['redmi', 'lavender']);
    });
  });

  group('buildMatchesCodename', () {
    CommunityBuild make({
      String name = '',
      String summary = '',
      List<String> tags = const <String>[],
    }) {
      return CommunityBuild(
        id: 1,
        name: name,
        maintainer: '',
        summary: summary,
        downloads: 0,
        score: 0,
        updated: DateTime.utc(2026),
        detailPage: '',
        deviceTags: tags,
      );
    }

    test('matches when codename is an exact device tag', () {
      expect(
        CommunityBuildsFeed.buildMatchesCodename(
          make(name: 'NusantaraROM', tags: <String>['redmi', 'whyred']),
          'whyred',
        ),
        isTrue,
      );
    });

    test('matches a whole word in the name or summary', () {
      expect(
        CommunityBuildsFeed.buildMatchesCodename(
          make(name: 'Corvus OS for Poco F1 (beryllium)'),
          'beryllium',
        ),
        isTrue,
      );
      expect(
        CommunityBuildsFeed.buildMatchesCodename(
          make(summary: 'Built for lavender devices'),
          'lavender',
        ),
        isTrue,
      );
    });

    test('is case-insensitive', () {
      expect(
        CommunityBuildsFeed.buildMatchesCodename(
          make(name: 'ROM for BERYLLIUM'),
          'beryllium',
        ),
        isTrue,
      );
    });

    test('does not match a codename embedded in a larger token', () {
      expect(
        CommunityBuildsFeed.buildMatchesCodename(
          make(name: 'Some whyreduxx build'),
          'whyred',
        ),
        isFalse,
      );
    });

    test('does not match an unrelated build', () {
      expect(
        CommunityBuildsFeed.buildMatchesCodename(
          make(name: 'Pixel ROM', tags: <String>['oriole']),
          'beryllium',
        ),
        isFalse,
      );
    });

    test('empty codename never matches', () {
      expect(
        CommunityBuildsFeed.buildMatchesCodename(make(name: 'anything'), ''),
        isFalse,
      );
    });
  });
}
