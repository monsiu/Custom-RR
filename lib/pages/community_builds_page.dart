import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../routes.dart';
import '../services/community_builds_feed.dart';
import '../widgets/app_shell.dart';
import '../widgets/community_build_card.dart';

/// Live browser for the community ROM uploads on OpenDesktop's "Phone ROMS"
/// category (Pling OCS API). These are unvetted, third-party builds shown
/// behind a disclaimer and kept entirely separate from the curated catalog.
class CommunityBuildsPage extends StatefulWidget {
  const CommunityBuildsPage({super.key, this.initialSearch = ''});

  /// Optional initial search term, e.g. a device codename deep-linked from a
  /// device page (`/community-builds?q=beryllium`).
  final String initialSearch;

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
    _query = widget.initialSearch.trim();
    _searchController.text = _query;
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

  void _onDeviceChipTap(String tag) {
    _debounce?.cancel();
    _searchController.text = tag;
    _query = tag;
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
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
      title: 'Community ROMs',
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
          Text('Community ROMs', style: text.headlineSmall),
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
        itemBuilder: (BuildContext context, int index) => CommunityBuildCard(
          item: _builds[index],
          onOpen: () => _open(_builds[index].detailPage),
          onDeviceTap: _onDeviceChipTap,
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
