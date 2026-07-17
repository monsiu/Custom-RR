import 'package:custom_rr/services/github_discussions_feed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GitHubDiscussionsFeed.parseAtom', () {
    test('parses namespaced GitHub Atom entries', () {
      const String feed = '''
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <entry>
    <title>  New   ROM announcement  </title>
    <link rel="self" href="https://github.com/feed-entry" />
    <link rel="alternate" href="https://github.com/monsiu/Custom-RR/discussions/42" />
    <author><name>  Example   Maintainer </name></author>
    <published>2026-07-16T10:00:00Z</published>
    <updated>2026-07-17T11:30:00Z</updated>
  </entry>
</feed>
''';

      final List<GitHubAnnouncement> items =
          GitHubDiscussionsFeed.parseAtom(feed);

      expect(items, hasLength(1));
      final GitHubAnnouncement item = items.single;
      expect(item.title, 'New ROM announcement');
      expect(
        item.url,
        'https://github.com/monsiu/Custom-RR/discussions/42',
      );
      expect(item.author, 'Example Maintainer');
      expect(item.published, DateTime.utc(2026, 7, 16, 10));
      expect(item.updated, DateTime.utc(2026, 7, 17, 11, 30));
    });

    test('falls back to unknown author and published date', () {
      const String feed = '''
<feed xmlns="http://www.w3.org/2005/Atom">
  <entry>
    <title>Announcement</title>
    <link href="https://github.com/monsiu/Custom-RR/discussions/43" />
    <published>2026-07-16T10:00:00Z</published>
  </entry>
</feed>
''';

      final GitHubAnnouncement item =
          GitHubDiscussionsFeed.parseAtom(feed).single;

      expect(item.author, 'unknown');
      expect(item.updated, item.published);
    });
  });
}
