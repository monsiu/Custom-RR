import 'package:custom_rr/services/xda_feed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('XdaFeedService.parseRss', () {
    test('parses namespaced RSS metadata and strips excerpt HTML', () {
      const String feed = '''
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:content="http://purl.org/rss/1.0/modules/content/">
  <channel>
    <item>
      <title>Galaxy S25 FE development</title>
      <link>https://xdaforums.com/t/example.123/</link>
      <dc:creator>xda-user</dc:creator>
      <pubDate>Thu, 16 Jul 2026 10:20:30 +0000</pubDate>
      <description><![CDATA[<p>First <strong>development</strong> update.</p>]]></description>
      <content:encoded><![CDATA[Ignored fallback content]]></content:encoded>
    </item>
  </channel>
</rss>
''';

      final List<XdaThread> threads = XdaFeedService.parseRss(feed);

      expect(threads, hasLength(1));
      final XdaThread thread = threads.single;
      expect(thread.title, 'Galaxy S25 FE development');
      expect(thread.url, 'https://xdaforums.com/t/example.123/');
      expect(thread.author, 'xda-user');
      expect(thread.published, DateTime.utc(2026, 7, 16, 10, 20, 30));
      expect(thread.excerpt, 'First development update.');
    });

    test('skips incomplete items and accepts ISO dates', () {
      const String feed = '''
<rss version="2.0"><channel>
  <item><title>Missing link</title></item>
  <item>
    <title>Complete thread</title>
    <link>https://xdaforums.com/t/complete.456/</link>
    <author>fallback-author</author>
    <pubDate>2026-07-17T12:00:00Z</pubDate>
  </item>
</channel></rss>
''';

      final XdaThread thread = XdaFeedService.parseRss(feed).single;

      expect(thread.title, 'Complete thread');
      expect(thread.author, 'fallback-author');
      expect(thread.published, DateTime.utc(2026, 7, 17, 12));
      expect(thread.excerpt, isNull);
    });
  });
}
