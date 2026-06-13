import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

/// One announcement item parsed from the repository's GitHub Discussions
/// Announcements category feed.
class GitHubAnnouncement {
  const GitHubAnnouncement({
    required this.title,
    required this.url,
    required this.author,
    required this.published,
    required this.updated,
  });

  final String title;
  final String url;
  final String author;
  final DateTime published;
  final DateTime updated;
}

class _CachedAnnouncements {
  _CachedAnnouncements(this.fetchedAt, this.items);
  final DateTime fetchedAt;
  final List<GitHubAnnouncement> items;
}

/// Fetches and caches the public Atom feed for GitHub Discussions
/// Announcements.
class GitHubDiscussionsFeed {
  GitHubDiscussionsFeed._();

  static final GitHubDiscussionsFeed instance = GitHubDiscussionsFeed._();

  /// Pluggable HTTP client so tests can inject a `MockClient`.
  http.Client httpClient = http.Client();

  static const Duration _ttl = Duration(minutes: 10);
  static const Duration _timeout = Duration(seconds: 8);

  static const String announcementsFeedUrl =
      'https://github.com/monsiu/Custom-RR/discussions/categories/announcements.atom';

  /// Repository-wide feed covering every discussion category, so the
  /// Community screen has fresh content even when no announcement is posted.
  static const String discussionsFeedUrl =
      'https://github.com/monsiu/Custom-RR/discussions.atom';

  _CachedAnnouncements? _announcementsCache;
  _CachedAnnouncements? _discussionsCache;

  /// Latest posts from the Announcements category.
  ///
  /// Throws on hard failures when there is no cached data available.
  Future<List<GitHubAnnouncement>> fetchAnnouncements({
    int limit = 5,
    bool force = false,
  }) {
    return _fetchFeed(
      url: announcementsFeedUrl,
      limit: limit,
      force: force,
      read: () => _announcementsCache,
      write: (_CachedAnnouncements c) => _announcementsCache = c,
    );
  }

  /// Most recent posts across every discussion category.
  ///
  /// Throws on hard failures when there is no cached data available.
  Future<List<GitHubAnnouncement>> fetchRecentDiscussions({
    int limit = 6,
    bool force = false,
  }) {
    return _fetchFeed(
      url: discussionsFeedUrl,
      limit: limit,
      force: force,
      read: () => _discussionsCache,
      write: (_CachedAnnouncements c) => _discussionsCache = c,
    );
  }

  Future<List<GitHubAnnouncement>> _fetchFeed({
    required String url,
    required int limit,
    required bool force,
    required _CachedAnnouncements? Function() read,
    required void Function(_CachedAnnouncements) write,
  }) async {
    final _CachedAnnouncements? cached = read();
    if (!force &&
        cached != null &&
        DateTime.now().difference(cached.fetchedAt) < _ttl) {
      return cached.items.take(limit).toList(growable: false);
    }

    try {
      final http.Response res = await httpClient.get(
        Uri.parse(url),
        headers: const <String, String>{
          'User-Agent': 'CustomRR/1.0 (+https://github.com/monsiu/Custom-RR)',
          'Accept': 'application/atom+xml, application/xml, text/xml',
        },
      ).timeout(_timeout);
      if (res.statusCode != 200) {
        throw GitHubDiscussionsFeedException(
          'GitHub responded with ${res.statusCode}',
        );
      }

      final List<GitHubAnnouncement> items = parseAtom(res.body);
      write(_CachedAnnouncements(DateTime.now(), items));
      return items.take(limit).toList(growable: false);
    } catch (err) {
      if (cached != null) {
        return cached.items.take(limit).toList(growable: false);
      }
      if (err is GitHubDiscussionsFeedException) rethrow;
      throw GitHubDiscussionsFeedException('Could not load discussions');
    }
  }

  /// Visible for tests. Parses an Atom feed into [GitHubAnnouncement]s.
  static List<GitHubAnnouncement> parseAtom(String body) {
    final XmlDocument doc = XmlDocument.parse(body);
    final List<GitHubAnnouncement> out = <GitHubAnnouncement>[];
    for (final XmlElement entry in doc.findAllElements('entry')) {
      final String title = _text(entry, 'title');
      final String url = _entryLink(entry);
      final String author = _author(entry);
      final DateTime? published = DateTime.tryParse(_text(entry, 'published'));
      final DateTime? updated = DateTime.tryParse(_text(entry, 'updated'));
      if (title.isEmpty || url.isEmpty || published == null) continue;
      out.add(
        GitHubAnnouncement(
          title: _squashWhitespace(title),
          url: url,
          author: author.isEmpty ? 'unknown' : _squashWhitespace(author),
          published: published,
          updated: updated ?? published,
        ),
      );
    }
    return out;
  }

  static String _entryLink(XmlElement entry) {
    for (final XmlElement link in entry.findElements('link')) {
      final String rel = (link.getAttribute('rel') ?? '').trim();
      final String href = (link.getAttribute('href') ?? '').trim();
      if (href.isEmpty) continue;
      if (rel == 'alternate' || rel.isEmpty) return href;
    }
    return '';
  }

  static String _author(XmlElement entry) {
    for (final XmlElement author in entry.findElements('author')) {
      final String name = _text(author, 'name');
      if (name.isNotEmpty) return name;
    }
    return '';
  }

  static String _text(XmlElement parent, String tag) {
    for (final XmlElement el in parent.findElements(tag)) {
      final String value = el.innerText.trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static String _squashWhitespace(String input) {
    return input.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class GitHubDiscussionsFeedException implements Exception {
  GitHubDiscussionsFeedException(this.message);
  final String message;

  @override
  String toString() => message;
}
