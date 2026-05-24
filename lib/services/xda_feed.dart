import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

/// One thread parsed from an XDA Developers (xenForo) forum RSS feed.
///
/// We deliberately only keep title, author, publish date, link, and a short
/// excerpt. We never store or render the full post body in-app: clicking a
/// thread opens it in the user's browser via `url_launcher`, which is the
/// correct way to syndicate forum content under XenForo / XDA terms.
class XdaThread {
  const XdaThread({
    required this.title,
    required this.url,
    this.author,
    this.published,
    this.excerpt,
  });

  final String title;
  final String url;
  final String? author;
  final DateTime? published;
  final String? excerpt;
}

class _CachedFeed {
  _CachedFeed(this.fetchedAt, this.threads);
  final DateTime fetchedAt;
  final List<XdaThread> threads;
}

/// Fetches and caches per-forum RSS feeds from xdaforums.com.
///
/// XDA exposes a public RSS endpoint for every forum category at
/// `<forum-url>/index.rss`. This service:
///   * derives that feed URL from a curated `forumUrl` if it matches the
///     xenForo `/forums/<slug>.<id>/` pattern (returns null otherwise);
///   * fetches it with a short timeout;
///   * parses titles / authors / dates / excerpts with `package:xml`;
///   * caches results in-memory for [_ttl] so navigating in and out of
///     a device page does not re-hit the network on every visit.
class XdaFeedService {
  XdaFeedService._();

  static final XdaFeedService instance = XdaFeedService._();

  /// Pluggable HTTP client so tests can inject a `MockClient`.
  http.Client httpClient = http.Client();

  static const Duration _ttl = Duration(minutes: 15);
  static const Duration _timeout = Duration(seconds: 8);
  static const int _maxThreads = 8;

  final Map<String, _CachedFeed> _cache = <String, _CachedFeed>{};

  /// Visible for tests / preview tools. Pre-populates the in-memory cache
  /// so the widget renders synchronously without any HTTP round-trip.
  void primeCacheForTesting(String feedUrl, List<XdaThread> threads) {
    _cache[feedUrl] = _CachedFeed(DateTime.now(), threads);
  }

  /// Returns the RSS feed URL for [forumUrl] if it points at a xenForo
  /// forum category on xdaforums.com, otherwise null. Search-result URLs
  /// and non-XDA URLs return null because xenForo does not expose RSS
  /// for those. Both the short `/f/<slug>.<id>/` form and the canonical
  /// `/forums/<slug>.<id>/` form are accepted, and the canonical form is
  /// used for the RSS endpoint. Any query string on the input URL (for
  /// example `?prefix_id=33` for the Development sub-listing) is forwarded
  /// to the RSS endpoint so the feed is filtered the same way.
  static String? feedUrlFor(String forumUrl) {
    final RegExpMatch? m = RegExp(
      r'^https?://xdaforums\.com/(?:f|forums)/([^/?#]+)/?(\?[^#]*)?',
    ).firstMatch(forumUrl);
    if (m == null) return null;
    final String slug = m.group(1)!;
    final String query = m.group(2) ?? '';
    return 'https://xdaforums.com/forums/$slug/index.rss$query';
  }

  /// Fetch (and cache) up to [_maxThreads] recent threads from [feedUrl].
  /// Returns an empty list on any network or parse error rather than
  /// throwing, so widgets can render a graceful empty/offline state.
  Future<List<XdaThread>> fetch(String feedUrl) async {
    final _CachedFeed? cached = _cache[feedUrl];
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt) < _ttl) {
      return cached.threads;
    }
    try {
      final http.Response res = await httpClient.get(
        Uri.parse(feedUrl),
        headers: <String, String>{
          'User-Agent': 'CustomRR/1.0 (+https://github.com/monsiu/Custom-RR)',
          'Accept': 'application/rss+xml, application/xml, text/xml',
        },
      ).timeout(_timeout);
      if (res.statusCode != 200) {
        return <XdaThread>[];
      }
      final List<XdaThread> threads =
          parseRss(res.body).take(_maxThreads).toList();
      _cache[feedUrl] = _CachedFeed(DateTime.now(), threads);
      return threads;
    } catch (_) {
      return <XdaThread>[];
    }
  }

  /// Visible for tests. Parses a xenForo RSS 2.0 document into [XdaThread]s.
  static List<XdaThread> parseRss(String body) {
    final XmlDocument doc = XmlDocument.parse(body);
    final List<XdaThread> out = <XdaThread>[];
    for (final XmlElement item in doc.findAllElements('item')) {
      final String title = _text(item, 'title');
      final String link = _text(item, 'link');
      if (title.isEmpty || link.isEmpty) continue;
      out.add(
        XdaThread(
          title: title,
          url: link,
          author: _firstNonEmpty(<String>[
            _text(item, 'dc:creator'),
            _text(item, 'author'),
          ]),
          published: _parseDate(_text(item, 'pubDate')),
          excerpt: _firstNonEmpty(<String>[
            _text(item, 'description'),
            _text(item, 'content:encoded'),
          ]).let(_stripHtml),
        ),
      );
    }
    return out;
  }

  static String _text(XmlElement parent, String tag) {
    for (final XmlElement el in parent.findElements(tag)) {
      return el.innerText.trim();
    }
    return '';
  }

  static String? _firstNonEmpty(List<String> values) {
    for (final String v in values) {
      if (v.isNotEmpty) return v;
    }
    return null;
  }

  static DateTime? _parseDate(String input) {
    if (input.isEmpty) return null;
    try {
      // RFC 822 / RFC 1123, e.g. "Mon, 12 May 2025 04:01:23 +0000".
      return HttpDate.parse(input);
    } catch (_) {
      try {
        return DateTime.parse(input);
      } catch (_) {
        return null;
      }
    }
  }

  static String _stripHtml(String input) {
    final String noTags = input.replaceAll(RegExp(r'<[^>]*>'), ' ');
    final String collapsed = noTags.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.length <= 220) return collapsed;
    return '${collapsed.substring(0, 217)}...';
  }
}

extension on String? {
  String? let(String Function(String) f) {
    final String? self = this;
    if (self == null || self.isEmpty) return null;
    return f(self);
  }
}

/// Minimal RFC 822 / RFC 1123 date parser. We avoid a dependency on
/// `dart:io`'s `HttpDate` because that pulls in IO on web builds.
class HttpDate {
  static DateTime parse(String input) {
    // Format: "Mon, 12 May 2025 04:01:23 +0000" or with named offset (GMT).
    final RegExpMatch? m = RegExp(
      r'^[A-Za-z]{3},\s+(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})\s+'
      r'(\d{2}):(\d{2}):(\d{2})\s+(?:GMT|UTC|([+-]\d{4}))$',
    ).firstMatch(input.trim());
    if (m == null) throw FormatException('Bad RFC 822 date: $input');
    const Map<String, int> months = <String, int>{
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    final int day = int.parse(m.group(1)!);
    final int month = months[m.group(2)] ?? 1;
    final int year = int.parse(m.group(3)!);
    final int hour = int.parse(m.group(4)!);
    final int minute = int.parse(m.group(5)!);
    final int second = int.parse(m.group(6)!);
    final String? offset = m.group(7);
    DateTime t = DateTime.utc(year, month, day, hour, minute, second);
    if (offset != null) {
      final int sign = offset.startsWith('-') ? 1 : -1;
      final int oh = int.parse(offset.substring(1, 3));
      final int om = int.parse(offset.substring(3, 5));
      t = t.add(Duration(hours: sign * oh, minutes: sign * om));
    }
    return t;
  }
}
