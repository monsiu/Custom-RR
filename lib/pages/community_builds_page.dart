import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../routes.dart';
import '../services/community_builds_feed.dart';
import '../widgets/app_shell.dart';
import '../widgets/shimmer_box.dart';

/// Live browser for the community ROM uploads on OpenDesktop's "Phone ROMS"
/// category (Pling OCS API). These are unvetted, third-party builds shown
/// behind a disclaimer and kept entirely separate from the curated catalog.
class CommunityBuildsPage extends StatefulWidget {
  const CommunityBuildsPage({super.key});

  @override
  State<CommunityBuildsPage> createState() => _CommunityBuildsPageState();
}

class _CommunityBuildsPageState extends State<CommunityBuildsPage> {
  final List<CommunityBuild> _builds = <CommunityBuild>[];
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  CommunityBuildSort _sort = CommunityBuildSort.downloads;
  String _query = '';
  int _page = 0;
  bool _loading = false;
  bool _hasMore = true;
  Object? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  Future<void> _loadFirstPage({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 0;
      _hasMore = true;
      _builds.clear();
    });
    try {
      final CommunityBuildsResult res = await CommunityBuildsFeed.instance.fetch(
        sort: _sort,
        search: _query,
        page: 0,
        force: force,
      );
      if (!mounted) return;
      setState(() {
        _builds.addAll(res.builds);
        _hasMore = res.hasMore;
        _loading = false;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = err;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    final int next = _page + 1;
    try {
      final CommunityBuildsResult res = await CommunityBuildsFeed.instance.fetch(
        sort: _sort,
        search: _query,
        page: next,
      );
      if (!mounted) return;
      setState(() {
        _page = next;
        _builds.addAll(res.builds);
        _hasMore = res.hasMore;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      // Soft-fail pagination: keep what we have, allow a retry on next scroll.
      setState(() {
        _hasMore = false;
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      final String q = value.trim();
      if (q == _query) return;
      _query = q;
      _loadFirstPage();
    });
  }

  void _changeSort(CommunityBuildSort sort) {
    if (sort == _sort) return;
    setState(() => _sort = sort);
    _loadFirstPage();
  }

  Future<void> _open(String url) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    bool ok = false;
    try {
      ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      ok = false;
    }
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open the link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Community builds',
      selectedRoute: AppRoutes.communityBuilds,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: RefreshIndicator(
            onRefresh: () => _loadFirstPage(force: true),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                SliverToBoxAdapter(child: _header(context)),
                _buildList(context),
                SliverToBoxAdapter(child: _footer(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Community builds', style: text.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Live listings from the OpenDesktop "Phone ROMS" community, mostly '
            'per-device builds shared by individual maintainers.',
            style: text.bodyLarge,
          ),
          const SizedBox(height: 14),
          const _DisclaimerCard(),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search by ROM, device, or maintainer…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Clear',
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (final CommunityBuildSort s in CommunityBuildSort.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(s.label),
                      selected: _sort == s,
                      onSelected: (_) => _changeSort(s),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    if (_error != null && _builds.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _ErrorState(onRetry: () => _loadFirstPage(force: true)),
      );
    }
    if (_loading && _builds.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_builds.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyState(),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList.builder(
        itemCount: _builds.length,
        itemBuilder: (BuildContext context, int index) => _BuildCard(
          item: _builds[index],
          onOpen: () => _open(_builds[index].detailPage),
        ),
      ),
    );
  }

  Widget _footer(BuildContext context) {
    if (_builds.isEmpty) return const SizedBox(height: 24);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Center(
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : _hasMore
                ? OutlinedButton(
                    onPressed: _loadMore,
                    child: const Text('Load more'),
                  )
                : Text(
                    'That is everything for this filter.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: scheme.errorContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'These are unvetted, third-party uploads, not part of the '
                'Custom RR catalog and not reviewed by us. Flash at your own '
                'risk: verify the maintainer and your exact device model '
                'before installing. Links open on OpenDesktop.',
                style: text.bodyMedium?.copyWith(
                  color: scheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuildCard extends StatelessWidget {
  const _BuildCard({required this.item, required this.onOpen});

  final CommunityBuild item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: item.previewImage == null
                      ? _thumbFallback(scheme)
                      : CachedNetworkImage(
                          imageUrl: item.previewImage!,
                          fit: BoxFit.cover,
                          memCacheWidth: 192,
                          placeholder: (_, __) => const ShimmerBox(),
                          errorWidget: (_, __, ___) => _thumbFallback(scheme),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.name,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.maintainer.isNotEmpty)
                      Text(
                        'by ${item.maintainer}',
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    if (item.summary.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        item.summary,
                        style: text.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (item.deviceTags.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: <Widget>[
                          for (final String tag in item.deviceTags)
                            _DeviceChip(label: tag),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        _meta(
                          context,
                          Icons.download_rounded,
                          _compactCount(item.downloads),
                        ),
                        if (item.score > 0)
                          _meta(
                            context,
                            Icons.star_rounded,
                            item.rating.toStringAsFixed(1),
                          ),
                        _meta(
                          context,
                          Icons.schedule,
                          _relativeTime(item.updated),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.open_in_new, size: 18, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbFallback(ColorScheme scheme) {
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Icon(Icons.android, color: scheme.onSurfaceVariant),
    );
  }

  Widget _meta(BuildContext context, IconData icon, String label) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 15, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Small pill showing a device codename or vendor parsed from a build's tags.
class _DeviceChip extends StatelessWidget {
  const _DeviceChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: text.labelSmall?.copyWith(
          color: scheme.onSecondaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.search_off, size: 48, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            'No community builds matched your search.',
            style: text.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.cloud_off, size: 48, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            'Could not load community builds. Check your connection and try '
            'again.',
            style: text.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Formats a download count compactly, e.g. 238756 -> "238.8K".
String _compactCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

String _relativeTime(DateTime dt) {
  final Duration diff = DateTime.now().toUtc().difference(dt);
  if (diff.inDays >= 365) {
    final int y = diff.inDays ~/ 365;
    return '$y year${y == 1 ? '' : 's'} ago';
  }
  if (diff.inDays >= 30) {
    final int mo = diff.inDays ~/ 30;
    return '$mo month${mo == 1 ? '' : 's'} ago';
  }
  if (diff.inDays >= 1) {
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }
  if (diff.inHours >= 1) {
    return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
  }
  return 'recently';
}
