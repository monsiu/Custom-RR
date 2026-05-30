import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/catalog_repository.dart';
import '../data/freshness_repository.dart';
import '../models.dart';
import '../routes.dart';
import '../util/breakpoints.dart';
import '../util/xda_search.dart';
import '../widgets/catalog_card.dart';
import '../widgets/freshness_badge.dart';
import '../widgets/xda_threads_section.dart';
import '../widgets/zoomable_image_viewer.dart';

/// HTTP headers sent with remote screenshot requests. The descriptive
/// `User-Agent` keeps image hosts (notably Wikimedia Commons) from
/// throttling the default Dart agent and leaving screenshots blank.
const Map<String, String> _kScreenshotHeaders = <String, String>{
  'User-Agent': 'CustomRR/1.0 (+https://github.com/monsiu/Custom-RR)',
};

/// Generic detail page used for both ROMs and recoveries.
///
/// Uses a collapsing [SliverAppBar] with the entry's header image, and
/// constrains body width on wider screens for readability.
class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.entry, required this.heroTag});

  final CatalogEntry entry;
  final Object heroTag;

  Future<void> _openDownloads() async {
    final Uri uri = Uri.parse(entry.downloadUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openXdaSearch(BuildContext context) async {
    final Uri uri = xdaSearchUri('${entry.name} $kXdaQueryPlaceholder');
    await launchXdaSearch(context, uri);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            pinned: true,
            stretch: true,
            expandedHeight: 260,
            title: Text(entry.name),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const <StretchMode>[StretchMode.fadeTitle],
              background: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  ColoredBox(color: scheme.surfaceContainerHighest),
                  Hero(
                    tag: heroTag,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Image.asset(
                        entry.headerAsset,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                  // Scrim so the AppBar title and back arrow remain legible
                  // regardless of underlying image content.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.black.withValues(alpha: 0.55),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.35),
                        ],
                        stops: const <double>[0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Breakpoints.readingMaxWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(entry.shortTagline, style: text.titleMedium),
                      const SizedBox(height: 12),
                      FreshnessBadge(
                        info: FreshnessRepository.instance.forId(entry.id),
                      ),
                      const SizedBox(height: 20),
                      if (entry.warning.isNotEmpty) ...<Widget>[
                        _WarningBanner(message: entry.warning),
                        const SizedBox(height: 20),
                      ],
                      for (final String paragraph
                          in entry.description) ...<Widget>[
                        Text(paragraph, style: text.bodyLarge),
                        const SizedBox(height: 12),
                      ],
                      if (entry.links.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            for (final CatalogLink link in entry.links)
                              _LinkChip(link: link),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (entry.features.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 12),
                        Text('Key Features', style: text.titleLarge),
                        const SizedBox(height: 8),
                        for (final String feature in entry.features)
                          _FeatureRow(
                            text: feature,
                            color: scheme.primary,
                          ),
                      ],
                      if (entry.supportedManufacturers.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 24),
                        _DeviceShowcase(entry: entry),
                      ],
                      // Only render the Screenshots section when the entry
                      // has real, hot-linkable shots. Entries whose upstream
                      // projects publish none (several root managers, a few
                      // ROMs) omit the section entirely instead of showing
                      // the project logo as a placeholder.
                      if (entry.screenshots.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 24),
                        Text('Screenshots', style: text.titleLarge),
                        const SizedBox(height: 12),
                        _Screenshots(
                          urls: entry.screenshots,
                          fallbackAsset: entry.headerAsset,
                        ),
                      ],
                      const SizedBox(height: 32),
                      Center(
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: <Widget>[
                            FilledButton.icon(
                              icon: const Icon(Icons.download_outlined),
                              label: Text(entry.downloadLabel),
                              onPressed: _openDownloads,
                            ),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.search),
                              label: const Text('Search on XDA'),
                              onPressed: () => _openXdaSearch(context),
                            ),
                          ],
                        ),
                      ),
                      if (entry.forumUrl.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 32),
                        XdaThreadsSection(forumUrl: entry.forumUrl),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({required this.link});

  final CatalogLink link;

  IconData _icon() {
    switch (link.iconName) {
      case 'telegram':
        return Icons.send;
      case 'github':
        return Icons.code;
      case 'discord':
        return Icons.chat_bubble_outline;
      case 'matrix':
        return Icons.alternate_email;
      case 'forum':
        return Icons.forum_outlined;
      case 'web':
        return Icons.public;
      default:
        return Icons.link;
    }
  }

  Future<void> _open() async {
    await launchUrl(Uri.parse(link.url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ActionChip(
      avatar: Icon(_icon(), size: 18, color: scheme.primary),
      label: Text(link.label),
      onPressed: _open,
      tooltip: link.url,
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.error, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.warning_amber_rounded, color: scheme.error, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Warning',
                  style: text.titleMedium?.copyWith(
                    color: scheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.check_circle, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class _Screenshots extends StatefulWidget {
  const _Screenshots({required this.urls, required this.fallbackAsset});

  final List<String> urls;
  final String fallbackAsset;

  @override
  State<_Screenshots> createState() => _ScreenshotsState();
}

class _ScreenshotsState extends State<_Screenshots> {
  static const double _tileWidth = 280;
  static const double _tileSpacing = 12;
  static const double _heightDesktop = 480;
  static const double _heightPhone = 360;
  // Phones get a snap-paged PageView, desktop/tablet keeps the scrollable
  // ListView with arrows + scrollbar. 600 dp is the Material breakpoint.
  static const double _phoneBreakpoint = 600;

  final ScrollController _scroll = ScrollController();
  final PageController _pages = PageController();
  bool _atStart = true;
  bool _atEnd = false;
  int _page = 0;

  // One-time "tap to view full screen" affordance. Persisted across
  // launches: once the user has tapped any screenshot tile, the hint
  // never appears again on any detail page.
  static const String _hintPrefsKey = 'hint_tap_screenshot_v1';
  static bool _hintDismissedMemo = false;
  bool _hintReady = false;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _pages.addListener(_onPage);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
    _loadHintState();
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _pages.removeListener(_onPage);
    _pages.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) {
      return;
    }
    final ScrollPosition p = _scroll.position;
    final bool start = p.pixels <= p.minScrollExtent + 1;
    final bool end = p.pixels >= p.maxScrollExtent - 1;
    if (start != _atStart || end != _atEnd) {
      setState(() {
        _atStart = start;
        _atEnd = end;
      });
    }
  }

  void _onPage() {
    if (!_pages.hasClients || _pages.page == null) {
      return;
    }
    final int next = _pages.page!.round();
    if (next != _page) {
      setState(() => _page = next);
    }
  }

  void _nudge(int direction) {
    if (!_scroll.hasClients) {
      return;
    }
    final double target = (_scroll.offset + direction * (_tileWidth + _tileSpacing))
        .clamp(_scroll.position.minScrollExtent, _scroll.position.maxScrollExtent);
    _scroll.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _copyUrl(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text('Screenshot URL copied'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadHintState() async {
    if (_hintDismissedMemo) return;
    try {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      _hintDismissedMemo = sp.getBool(_hintPrefsKey) ?? false;
    } on Object {
      // Prefs unavailable; behave as if the hint hasn't been dismissed.
    }
    if (!mounted) return;
    setState(() {
      _hintReady = true;
      _showHint = !_hintDismissedMemo;
    });
  }

  void _dismissHint() {
    if (!_showHint && _hintDismissedMemo) return;
    _hintDismissedMemo = true;
    if (mounted) setState(() => _showHint = false);
    // Best-effort persist; we already updated the in-memory memo so
    // a failure here just means it might re-appear next launch.
    unawaited(_persistHintDismissed());
  }

  Future<void> _persistHintDismissed() async {
    try {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      await sp.setBool(_hintPrefsKey, true);
    } on Object {
      // Ignore.
    }
  }

  List<Object> _heroTags(List<String> urls) =>
      <Object>[for (int i = 0; i < urls.length; i++) 'shot-$i-${urls[i]}'];

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<String> urls = widget.urls;
    final bool isPhone =
        MediaQuery.sizeOf(context).width < _phoneBreakpoint;
    final double height = isPhone ? _heightPhone : _heightDesktop;
    // When upstream doesn't expose hot-linkable shots, show a single tile
    // with the project's bundled logo so the section is never empty.
    if (urls.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ColoredBox(
          color: scheme.surfaceContainerHighest,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Image.asset(
                widget.fallbackAsset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
      );
    }
    return isPhone
        ? _withTapHint(context, _buildPhone(context, urls))
        : _withTapHint(context, _buildDesktop(context, urls));
  }

  /// Wraps the screenshot strip with a one-time "Tap to view" pill so
  /// users discover the full-screen gallery affordance. The overlay sits
  /// inside an [IgnorePointer] so the underlying tile still receives the
  /// tap (which both opens the gallery and dismisses the hint).
  Widget _withTapHint(BuildContext context, Widget child) {
    return Stack(
      children: <Widget>[
        child,
        Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _hintReady && _showHint ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.touch_app,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tap to view full screen',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required String url,
    required Object heroTag,
    required VoidCallback onTap,
    BorderRadius radius = const BorderRadius.all(Radius.circular(16)),
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    // Decode at roughly the tile's pixel width so 1080x2400 portrait
    // screenshots don't blow the image cache to ~10 MB per ROM page.
    final double dpr = MediaQuery.devicePixelRatioOf(context);
    final double targetWidth = MediaQuery.sizeOf(context).width <
            _phoneBreakpoint
        ? MediaQuery.sizeOf(context).width
        : _tileWidth;
    final int cacheWidth = (targetWidth * dpr).round();
    // Screenshots are either remote URLs or bundled asset paths (used when
    // the upstream host blocks hot-linking). Pick the matching widget.
    final Widget image = isNetworkScreenshot(url)
        ? CachedNetworkImage(
            imageUrl: url,
            // Some hosts (e.g. Wikimedia Commons) throttle or reject the
            // generic Dart user agent the cache manager sends by default,
            // which makes screenshots intermittently fail to load. Send a
            // descriptive UA so requests are treated as a normal client.
            httpHeaders: _kScreenshotHeaders,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            memCacheWidth: cacheWidth,
            maxWidthDiskCache: cacheWidth,
            placeholder: (BuildContext _, String __) => ColoredBox(
              color: scheme.surfaceContainerHighest,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            // Fall back to the entry's bundled hero instead of a
            // broken-image placeholder when a screenshot URL 404s.
            errorWidget:
                (BuildContext _, String __, Object ___) => ColoredBox(
              color: scheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Image.asset(
                  widget.fallbackAsset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          )
        : Image.asset(
            url,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            cacheWidth: cacheWidth,
            errorBuilder:
                (BuildContext _, Object __, StackTrace? ___) => ColoredBox(
              color: scheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Image.asset(
                  widget.fallbackAsset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          );
    return ClipRRect(
      borderRadius: radius,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: () => _copyUrl(context, url),
          child: Hero(
            tag: heroTag,
            child: image,
          ),
        ),
      ),
    );
  }

  Widget _buildPhone(BuildContext context, List<String> urls) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<Object> tags = _heroTags(urls);
    final bool multi = urls.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: _heightPhone,
          child: PageView.builder(
            controller: _pages,
            itemCount: urls.length,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildTile(
                  context,
                  url: urls[index],
                  heroTag: tags[index],
                  onTap: () {
                    _dismissHint();
                    showZoomableGallery(
                      context,
                      images: urls,
                      initialIndex: index,
                      heroTags: tags,
                    );
                  },
                ),
              );
            },
          ),
        ),
        if (multi) ...<Widget>[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (int i = 0; i < urls.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _page == i ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _page == i
                        ? scheme.primary
                        : scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDesktop(BuildContext context, List<String> urls) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final List<Object> tags = _heroTags(urls);
    final bool multi = urls.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          // Extra height keeps room for the always-visible scrollbar track
          // below the tiles so it never overlaps the imagery.
          height: _heightDesktop + 18,
          child: Stack(
            children: <Widget>[
              // Force the scrollbar to stay visible at all times so users
              // (especially on Linux/desktop) immediately see the strip is
              // horizontally scrollable.
              ScrollbarTheme(
                data: ScrollbarThemeData(
                  thumbVisibility: WidgetStateProperty.all(true),
                  trackVisibility: WidgetStateProperty.all(true),
                  thickness: WidgetStateProperty.all(8),
                  radius: const Radius.circular(8),
                  interactive: true,
                ),
                child: Scrollbar(
                  controller: _scroll,
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: ListView.separated(
                    controller: _scroll,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(bottom: 18),
                    itemCount: urls.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: _tileSpacing),
                    itemBuilder: (BuildContext context, int index) {
                      return SizedBox(
                        width: _tileWidth,
                        height: _heightDesktop,
                        child: _buildTile(
                          context,
                          url: urls[index],
                          heroTag: tags[index],
                          onTap: () {
                            _dismissHint();
                            showZoomableGallery(
                              context,
                              images: urls,
                              initialIndex: index,
                              heroTags: tags,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (multi) ...<Widget>[
                // Right-edge gradient fade hinting at off-screen content.
                Positioned.fill(
                  right: 0,
                  child: IgnorePointer(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: AnimatedOpacity(
                        opacity: _atEnd ? 0 : 1,
                        duration: const Duration(milliseconds: 150),
                        child: Container(
                          width: 48,
                          margin: const EdgeInsets.only(bottom: 18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: <Color>[
                                scheme.surface.withValues(alpha: 0),
                                scheme.surface.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Left-edge gradient (mirrors the right edge once scrolled).
                Positioned.fill(
                  left: 0,
                  child: IgnorePointer(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedOpacity(
                        opacity: _atStart ? 0 : 1,
                        duration: const Duration(milliseconds: 150),
                        child: Container(
                          width: 48,
                          margin: const EdgeInsets.only(bottom: 18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                              colors: <Color>[
                                scheme.surface.withValues(alpha: 0),
                                scheme.surface.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Always-visible nav buttons (Linux/desktop has no swipe).
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 18,
                  child: Center(
                    child: _NavButton(
                      icon: Icons.chevron_left,
                      tooltip: 'Scroll left',
                      enabled: !_atStart,
                      onPressed: _atStart ? null : () => _nudge(-1),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 18,
                  child: Center(
                    child: _NavButton(
                      icon: Icons.chevron_right,
                      tooltip: 'Scroll right',
                      enabled: !_atEnd,
                      onPressed: _atEnd ? null : () => _nudge(1),
                    ),
                  ),
                ),
                // Counter pill so it's clear there are more shots even
                // before the scrollbar/arrows are noticed.
                Positioned(
                  top: 12,
                  right: 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.view_carousel_outlined,
                            size: 14,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${urls.length} screenshots, scroll ->',
                            style: text.labelSmall?.copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Circular nav button shown at either edge of the screenshot strip.
/// Disabled (greyed out) at the corresponding edge of the scroll range.
class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.35,
      duration: const Duration(milliseconds: 150),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: scheme.surface.withValues(alpha: 0.92),
          shape: const CircleBorder(),
          elevation: 3,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(icon, size: 28, color: scheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact, searchable, brand-grouped showcase of every phone supported by
/// a ROM or recovery. Replaces the old "Compatible Devices" + "Phone models"
/// flat chip walls (which could top 500 chips for TWRP).
class _DeviceShowcase extends StatefulWidget {
  const _DeviceShowcase({required this.entry});

  final CatalogEntry entry;

  @override
  State<_DeviceShowcase> createState() => _DeviceShowcaseState();
}

class _DeviceShowcaseState extends State<_DeviceShowcase> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Brand -> models, alphabetised both ways. Computed once per build; the
  /// underlying list is immutable so this is cheap.
  Map<String, List<DeviceRef>> get _groups {
    final Map<String, List<DeviceRef>> out = <String, List<DeviceRef>>{};
    for (final DeviceRef d in widget.entry.devices) {
      out.putIfAbsent(d.brand, () => <DeviceRef>[]).add(d);
    }
    for (final List<DeviceRef> list in out.values) {
      list.sort(
        (DeviceRef a, DeviceRef b) =>
            a.model.toLowerCase().compareTo(b.model.toLowerCase()),
      );
    }
    final List<String> brands = out.keys.toList()
      ..sort(
        (String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()),
      );
    return <String, List<DeviceRef>>{
      for (final String b in brands) b: out[b]!,
    };
  }

  bool _matches(DeviceRef d, String q) {
    if (q.isEmpty) return true;
    return d.model.toLowerCase().contains(q) ||
        d.codename.toLowerCase().contains(q) ||
        d.brand.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final Map<String, List<DeviceRef>> groups = _groups;
    final String q = _query.trim().toLowerCase();
    final bool filtering = q.isNotEmpty;
    final int xdaCount = widget.entry.devices
        .where((DeviceRef d) => d.forumUrl.isNotEmpty)
        .length;

    int totalMatches = 0;
    final List<MapEntry<String, List<DeviceRef>>> visible =
        <MapEntry<String, List<DeviceRef>>>[];
    for (final MapEntry<String, List<DeviceRef>> e in groups.entries) {
      final List<DeviceRef> matches = filtering
          ? e.value.where((DeviceRef d) => _matches(d, q)).toList()
          : e.value;
      if (matches.isEmpty) continue;
      visible.add(MapEntry<String, List<DeviceRef>>(e.key, matches));
      totalMatches += matches.length;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text('Supported devices', style: text.titleLarge),
            ),
            Text(
              filtering
                  ? '$totalMatches / ${widget.entry.devices.length}'
                  : '${widget.entry.devices.length} devices, '
                      '${groups.length} brands',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (xdaCount > 0) ...<Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.forum_outlined, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$xdaCount of ${widget.entry.devices.length} '
                    'device${widget.entry.devices.length == 1 ? '' : 's'} '
                    'have an active XDA Development thread. Tap the '
                    'forum icon next to a model to jump in.',
                    style: text.bodySmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          onChanged: (String v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Search model, brand, or codename',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Clear',
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        if (visible.isEmpty)
          Card(
            color: scheme.surfaceContainerHigh,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No devices match "$_query".',
                style: text.bodyMedium,
              ),
            ),
          )
        else
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Theme(
              // Drop the default divider between ExpansionTiles for a
              // cleaner Material 3 look.
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
              ),
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < visible.length; i++) ...<Widget>[
                    if (i > 0) const Divider(height: 1),
                    _BrandGroup(
                      brand: visible[i].key,
                      models: visible[i].value,
                      // Auto-expand when filtering, otherwise only the first
                      // brand starts open so the section stays compact.
                      initiallyExpanded: filtering || i == 0,
                      // Force a rebuild of the ExpansionTile when the filter
                      // toggles so `initiallyExpanded` is re-honoured.
                      key: ValueKey<String>(
                        '${visible[i].key}|${filtering ? 'f' : 'n'}',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _BrandGroup extends StatelessWidget {
  const _BrandGroup({
    super.key,
    required this.brand,
    required this.models,
    required this.initiallyExpanded,
  });

  final String brand;
  final List<DeviceRef> models;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    DeviceEntry? entry;
    for (final DeviceEntry d in CatalogRepository.instance.devices) {
      if (d.name == brand) {
        entry = d;
        break;
      }
    }
    final DeviceEntry? brandEntry = entry;

    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      leading: brandEntry == null
          ? CircleAvatar(
              backgroundColor: scheme.surfaceContainerHighest,
              child: const Icon(Icons.smartphone_outlined, size: 18),
            )
          : CircleAvatar(
              backgroundColor: scheme.surfaceContainerHighest,
              foregroundImage: AssetImage(brandEntry.imageAsset),
            ),
      title: Text(brand),
      subtitle: Text(
        '${models.length} model${models.length == 1 ? '' : 's'}',
      ),
      trailing: brandEntry == null
          ? null
          : IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Open $brand page',
              onPressed: () =>
                  context.push(AppRoutes.deviceDetail(brandEntry.slug)),
            ),
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final DeviceRef d in models)
              _ModelPill(
                brandEntry: brandEntry,
                device: d,
              ),
          ],
        ),
      ],
    );
  }
}

Future<void> _copyCodename(BuildContext context, String codename) async {
  await Clipboard.setData(ClipboardData(text: codename));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Copied "$codename" to clipboard'),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class _ModelPill extends StatelessWidget {
  const _ModelPill({required this.brandEntry, required this.device});

  final DeviceEntry? brandEntry;
  final DeviceRef device;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final bool hasForum = device.forumUrl.isNotEmpty;
    final bool canOpen = brandEntry != null && device.codename.isNotEmpty;
    final Color background = hasForum
        ? scheme.primaryContainer.withValues(alpha: 0.55)
        : scheme.surfaceContainerHigh;
    final Color foreground = hasForum
        ? scheme.onPrimaryContainer
        : scheme.onSurface;
    final Color border = hasForum
        ? scheme.primary.withValues(alpha: 0.35)
        : scheme.outlineVariant;

    return Tooltip(
      message: device.codename.isEmpty
          ? device.model
          : 'Codename: ${device.codename} (long-press to copy)',
      child: Material(
        color: background,
        shape: StadiumBorder(side: BorderSide(color: border)),
        clipBehavior: Clip.antiAlias,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            InkWell(
              onTap: canOpen
                  ? () => context.push(
                        AppRoutes.deviceModelDetail(
                          brandEntry!.slug,
                          device.codename,
                        ),
                      )
                  : null,
              onLongPress: device.codename.isEmpty
                  ? null
                  : () => _copyCodename(context, device.codename),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  8,
                  hasForum ? 10 : 14,
                  8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.smartphone_outlined,
                      size: 16,
                      color: foreground,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      device.model,
                      style: text.labelLarge?.copyWith(color: foreground),
                    ),
                  ],
                ),
              ),
            ),
            if (hasForum) ...<Widget>[
              Container(
                width: 1,
                height: 22,
                color: border,
              ),
              InkWell(
                onTap: () => launchUrl(
                  Uri.parse(device.forumUrl),
                  mode: LaunchMode.externalApplication,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Tooltip(
                    message: 'XDA thread for ${device.model}',
                    child: Icon(
                      Icons.forum_outlined,
                      size: 18,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
