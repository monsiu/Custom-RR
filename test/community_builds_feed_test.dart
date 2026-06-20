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
      final String json = body(<Map<String, dynamic>>[
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
      ], total: 3461);

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
        body(<Map<String, dynamic>>[
          <String, dynamic>{'id': 1, 'name': 'A ROM'},
        ], total: 10),
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
}
