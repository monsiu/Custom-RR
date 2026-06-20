import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../routes.dart';
import '../services/github_discussions_feed.dart';
import '../util/breakpoints.dart';
import '../widgets/app_shell.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  Future<List<GitHubAnnouncement>>? _recent;

  static final Uri _allDiscussions = Uri.parse(
    'https://github.com/monsiu/Custom-RR/discussions',
  );
  static final Uri _announcements = Uri.parse(
    'https://github.com/monsiu/Custom-RR/discussions/categories/announcements',
  );
  static final Uri _qa = Uri.parse(
    'https://github.com/monsiu/Custom-RR/discussions/categories/q-a',
  );
  static final Uri _ideas = Uri.parse(
    'https://github.com/monsiu/Custom-RR/discussions/categories/ideas',
  );
  static final Uri _polls = Uri.parse(
    'https://github.com/monsiu/Custom-RR/discussions/categories/polls',
  );
  static final Uri _showAndTell = Uri.parse(
    'https://github.com/monsiu/Custom-RR/discussions/categories/show-and-tell',
  );
  static final Uri _issues = Uri.parse(
    'https://github.com/monsiu/Custom-RR/issues',
  );
  static final Uri _discord = Uri.parse('https://discord.gg/uWZR8vR855');

  @override
  void initState() {
    super.initState();
    _recent = GitHubDiscussionsFeed.instance.fetchRecentDiscussions(limit: 6);
  }

  Future<void> _refresh() async {
    final Future<List<GitHubAnnouncement>> next = GitHubDiscussionsFeed.instance
        .fetchRecentDiscussions(limit: 6, force: true);
    setState(() => _recent = next);
    try {
      await next;
    } catch (_) {
      // The error is surfaced by the FutureBuilder below.
    }
  }

  Future<void> _open(Uri uri) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    bool opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open the link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Community',
      selectedRoute: AppRoutes.community,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
              physics: const AlwaysScrollableScrollPhysics(),
              children: <Widget>[
                Text(
                  'Community forum',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Text(
                  'Join discussions, ask questions, propose ideas, and follow announcements for Custom RR.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 18),
                _ForumLinksCard(
                  onOpen: _open,
                  allDiscussions: _allDiscussions,
                  announcements: _announcements,
                  qa: _qa,
                  ideas: _ideas,
                  polls: _polls,
                  showAndTell: _showAndTell,
                  issues: _issues,
                ),
                const SizedBox(height: 18),
                _CommunityBuildsCard(
                  onOpen: () => context.push(AppRoutes.communityBuilds),
                ),
                const SizedBox(height: 18),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.forum_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Recent discussions',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Refresh',
                              onPressed: _refresh,
                              icon: const Icon(Icons.refresh),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        FutureBuilder<List<GitHubAnnouncement>>(
                          future: _recent,
                          builder: (
                            BuildContext context,
                            AsyncSnapshot<List<GitHubAnnouncement>> snap,
                          ) {
                            if (snap.connectionState != ConnectionState.done) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            if (snap.hasError) {
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(0, 6, 0, 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Could not load discussions right now.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      onPressed: () => _open(_allDiscussions),
                                      icon: const Icon(Icons.open_in_new),
                                      label: const Text(
                                        'Open the forum in browser',
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            final List<GitHubAnnouncement> items =
                                snap.data ?? const <GitHubAnnouncement>[];
                            if (items.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(0, 6, 0, 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'No discussions yet. Be the first to '
                                      'start one!',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      onPressed: () => _open(_allDiscussions),
                                      icon: const Icon(
                                        Icons.add_comment_outlined,
                                      ),
                                      label: const Text('Start a discussion'),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return Column(
                              children: <Widget>[
                                for (int i = 0;
                                    i < items.length;
                                    i++) ...<Widget>[
                                  Tooltip(
                                    message:
                                        '${_formatDate(items[i].published)} · by ${items[i].author}',
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 0,
                                      ),
                                      dense: Breakpoints.isCompact(context),
                                      leading:
                                          const Icon(Icons.article_outlined),
                                      title: Text(items[i].title),
                                      subtitle: Text(
                                        '${_relativeTime(items[i].published)} · by ${items[i].author}',
                                      ),
                                      trailing: const Icon(Icons.open_in_new),
                                      onTap: () =>
                                          _open(Uri.parse(items[i].url)),
                                    ),
                                  ),
                                  if (i < items.length - 1)
                                    const Divider(height: 1),
                                ],
                                const SizedBox(height: 2),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    onPressed: () => _open(_allDiscussions),
                                    icon: const Icon(Icons.forum_outlined),
                                    label: const Text('View all discussions'),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _DiscordCard(onOpen: () => _open(_discord)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscordCard extends StatelessWidget {
  const _DiscordCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.discord, color: scheme.onPrimaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Prefer to chat in real time?',
                    style: text.titleMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Hop into the Discord to reach out directly, get the latest '
              'updates and release pings, swap flashing tips, and hang out '
              'with the rest of the Custom RR community.',
              style: text.bodyMedium?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.discord),
                label: const Text('Join the Discord'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForumLinksCard extends StatelessWidget {
  const _ForumLinksCard({
    required this.onOpen,
    required this.allDiscussions,
    required this.announcements,
    required this.qa,
    required this.ideas,
    required this.polls,
    required this.showAndTell,
    required this.issues,
  });  final Future<void> Function(Uri uri) onOpen;
  final Uri allDiscussions;
  final Uri announcements;
  final Uri qa;
  final Uri ideas;
  final Uri polls;
  final Uri showAndTell;
  final Uri issues;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          children: <Widget>[
            _ForumLinkTile(
              icon: Icons.forum_outlined,
              title: 'All discussions',
              subtitle: 'Everything in the forum',
              onTap: () => onOpen(allDiscussions),
            ),
            _ForumLinkTile(
              icon: Icons.campaign_outlined,
              title: 'Announcements',
              subtitle: 'Release notes and project updates',
              onTap: () => onOpen(announcements),
            ),
            _ForumLinkTile(
              icon: Icons.help_outline,
              title: 'Q&A',
              subtitle: 'Ask for help and troubleshooting tips',
              onTap: () => onOpen(qa),
            ),
            _ForumLinkTile(
              icon: Icons.lightbulb_outline,
              title: 'Ideas',
              subtitle: 'Feature proposals and suggestions',
              onTap: () => onOpen(ideas),
            ),
            _ForumLinkTile(
              icon: Icons.poll_outlined,
              title: 'Polls',
              subtitle: 'Vote on roadmap and priorities',
              onTap: () => onOpen(polls),
            ),
            _ForumLinkTile(
              icon: Icons.emoji_objects_outlined,
              title: 'Show and tell',
              subtitle: 'Share setups, screenshots, and wins',
              onTap: () => onOpen(showAndTell),
            ),
            const Divider(height: 18),
            _ForumLinkTile(
              icon: Icons.bug_report_outlined,
              title: 'Bug reports (Issues)',
              subtitle: 'Use GitHub Issues for confirmed bugs',
              onTap: () => onOpen(issues),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForumLinkTile extends StatelessWidget {
  const _ForumLinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.open_in_new),
      onTap: onTap,
    );
  }
}

String _formatDate(DateTime dt) {
  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final DateTime local = dt.toLocal();
  final String month = months[local.month - 1];
  return '$month ${local.day}, ${local.year}';
}

String _relativeTime(DateTime dt) {
  final Duration diff = DateTime.now().difference(dt);
  if (diff.isNegative || diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) {
    final int m = diff.inMinutes;
    return '$m minute${m == 1 ? '' : 's'} ago';
  }
  if (diff.inHours < 24) {
    final int h = diff.inHours;
    return '$h hour${h == 1 ? '' : 's'} ago';
  }
  if (diff.inDays < 30) {
    final int d = diff.inDays;
    return '$d day${d == 1 ? '' : 's'} ago';
  }
  if (diff.inDays < 365) {
    final int mo = diff.inDays ~/ 30;
    return '$mo month${mo == 1 ? '' : 's'} ago';
  }
  final int y = diff.inDays ~/ 365;
  return '$y year${y == 1 ? '' : 's'} ago';
}

/// Promo card linking to the live "Community builds" browser.
class _CommunityBuildsCard extends StatelessWidget {
  const _CommunityBuildsCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
          child: Row(
            children: <Widget>[
              Icon(Icons.download_rounded, color: scheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Browse community builds',
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Thousands of per-device ROM uploads shared by the '
                      'community. Unvetted, browse with care.',
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

