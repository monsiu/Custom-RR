import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/xda_feed.dart';

/// Renders a "Recent XDA discussions" section for a given forum URL.
///
/// If [forumUrl] is empty, or does not match the xdaforums.com forum-category
/// pattern, the widget renders nothing (zero vertical space). When it does
/// match, the latest threads from the forum's public RSS feed are listed,
/// each tappable to open the thread in the user's browser.
class XdaThreadsSection extends StatefulWidget {
  const XdaThreadsSection({
    super.key,
    required this.forumUrl,
    this.title = 'Recent XDA discussions',
  });

  final String forumUrl;
  final String title;

  @override
  State<XdaThreadsSection> createState() => _XdaThreadsSectionState();
}

class _XdaThreadsSectionState extends State<XdaThreadsSection> {
  late Future<List<XdaThread>> _future;
  String? _feedUrl;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant XdaThreadsSection old) {
    super.didUpdateWidget(old);
    if (old.forumUrl != widget.forumUrl) _resolve();
  }

  void _resolve() {
    _feedUrl = XdaFeedService.feedUrlFor(widget.forumUrl);
    _future = _feedUrl == null
        ? Future<List<XdaThread>>.value(<XdaThread>[])
        : XdaFeedService.instance.fetch(_feedUrl!);
  }

  @override
  Widget build(BuildContext context) {
    if (_feedUrl == null) return const SizedBox.shrink();
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(Icons.forum_outlined, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(widget.title, style: text.titleLarge)),
            TextButton.icon(
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open on XDA'),
              onPressed: () => launchUrl(
                Uri.parse(widget.forumUrl),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<XdaThread>>(
          future: _future,
          builder: (BuildContext context, AsyncSnapshot<List<XdaThread>> snap) {
            if (snap.connectionState != ConnectionState.done) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.primary,
                    ),
                  ),
                ),
              );
            }
            final List<XdaThread> threads = snap.data ?? <XdaThread>[];
            if (threads.isEmpty) {
              // XDA sits behind a Bunny Shield bot challenge, so in-app
              // RSS fetches usually get blocked. Degrade gracefully to a
              // big, obvious call-to-action that opens the forum in the
              // user's browser (where the challenge is solved transparently).
              return Card(
                margin: EdgeInsets.zero,
                color: scheme.surfaceContainerHigh,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => launchUrl(
                    Uri.parse(widget.forumUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.forum_outlined, color: scheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Browse this device on XDA',
                                style: text.titleSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Recent threads cannot be loaded in-app '
                                "(XDA's anti-bot challenge blocks "
                                'background fetches). Open the forum in '
                                'your browser to see the latest posts.',
                                style: text.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.open_in_new, color: scheme.primary),
                      ],
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: <Widget>[
                for (final XdaThread t in threads)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        Icons.chat_bubble_outline,
                        color: scheme.primary,
                      ),
                      title: Text(
                        t.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        <String>[
                          if (t.author != null && t.author!.isNotEmpty)
                            t.author!,
                          if (t.published != null) _relative(t.published!),
                        ].join('  ·  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () => launchUrl(
                        Uri.parse(t.url),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Threads syndicated from the public XDA forum RSS feed. '
                    'Trademarks belong to their respective owners.',
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  String _relative(DateTime when) {
    final Duration d = DateTime.now().toUtc().difference(when.toUtc());
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 30) return '${d.inDays}d ago';
    if (d.inDays < 365) return '${(d.inDays / 30).floor()}mo ago';
    return '${(d.inDays / 365).floor()}y ago';
  }
}
