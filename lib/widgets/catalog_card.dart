import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models.dart';
import '../util/xda_search.dart';
import 'brand_image.dart';
import 'freshness_badge.dart';

/// Placeholder text appended to XDA search queries so users immediately see
/// what they need to replace with their own device model.
const String kXdaQueryPlaceholder = 'input your model here';

/// Builds a search URL for XDA Forums content for [query].
///
/// XDA's own `/search/` endpoint requires being logged in, so this routes
/// the query through Google with a `site:xdaforums.com` filter instead.
/// That works without an account and tends to surface higher quality
/// threads in practice.
Uri xdaSearchUri(String query) => Uri.https(
      'www.google.com',
      '/search',
      <String, String>{'q': 'site:xdaforums.com $query'},
    );

/// Card used in ROM / Recovery list pages.
///
/// Features:
/// - 16:9 aspect-ratio header image (asset or network) with gradient scrim
///   so the title remains legible even over busy artwork.
/// - Subtle hover-scale animation on platforms with a pointer.
/// - Wrapped in a [Semantics] node with a meaningful description.
class CatalogCard extends StatefulWidget {
  const CatalogCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.assetImage,
    this.networkImage,
    this.heroTag,
    this.freshness,
    this.trailing,
    this.xdaSearchName = '',
    this.xdaSearchKind = 'build',
  }) : assert(
          assetImage != null || networkImage != null,
          'Provide either assetImage or networkImage',
        );

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? assetImage;
  final String? networkImage;
  final Object? heroTag;
  final FreshnessInfo? freshness;
  final Widget? trailing;

  /// Name to seed an XDA search with. When non-empty, the card shows a
  /// small "Search XDA" pill over the image that opens an XDA forums
  /// search pre-filled with this name plus a placeholder reminding the
  /// user to add their device model.
  final String xdaSearchName;

  /// Short noun describing what [xdaSearchName] is (e.g. "custom ROM" or
  /// "recovery"). Used to make the pill's tooltip and search query more
  /// specific.
  final String xdaSearchKind;

  @override
  State<CatalogCard> createState() => _CatalogCardState();
}

class _CatalogCardState extends State<CatalogCard> {
  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    final Widget rawImage = widget.assetImage != null
        ? BrandImage(
            asset: widget.assetImage!,
            // Decode at roughly the displayed pixel size (cards top out
            // around ~300 logical px; 720 covers 2x DPR). This avoids
            // decoding full-resolution PNGs into the image cache, which
            // is the biggest single perf win for the grid pages.
            cacheWidth: 720,
          )
        : CachedNetworkImage(
            imageUrl: widget.networkImage!,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            memCacheWidth: 720,
            placeholder: (BuildContext _, String __) => ColoredBox(
              color: scheme.surfaceContainerHighest,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (BuildContext _, String __, Object ___) => ColoredBox(
              color: scheme.surfaceContainerHighest,
              child: const Icon(Icons.broken_image_outlined, size: 48),
            ),
          );

    // Whole image is shown (BoxFit.contain). A neutral surface colour fills
    // the letterbox bars so the card still feels solid even when the image
    // aspect ratio differs from 16:9.
    final Widget image = AspectRatio(
      aspectRatio: 16 / 9,
      child: ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: rawImage,
        ),
      ),
    );

    final Widget imageStack = Stack(
      children: <Widget>[
        image,
        if (widget.freshness != null &&
            widget.freshness!.status != FreshnessStatus.unknown)
          Positioned(
            top: 8,
            right: 8,
            child: FreshnessBadge(
              info: widget.freshness!,
              compact: true,
            ),
          ),
        if (widget.xdaSearchName.isNotEmpty)
          Positioned(
            bottom: 8,
            right: 8,
            child: _XdaPill(
              searchName: widget.xdaSearchName,
              searchKind: widget.xdaSearchKind,
            ),
          ),
      ],
    );

    final Widget card = Card(
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (widget.heroTag != null)
              Hero(tag: widget.heroTag!, child: imageStack)
            else
              imageStack,
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.trailing != null) widget.trailing!,
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Semantics(
      label: '${widget.title}. ${widget.subtitle}',
      button: true,
      child: _HoverScale(child: card),
    );
  }
}

/// Wraps [child] in a tiny hover-scale animation without rebuilding the
/// child on hover state changes. The scale value is held in this small
/// stateful widget, so only the [AnimatedScale] node above the cached
/// `child` rebuilds; the card content stays untouched.
class _HoverScale extends StatefulWidget {
  const _HoverScale({required this.child});

  final Widget child;

  @override
  State<_HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<_HoverScale> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Compact "Search XDA" pill overlaid on the card image. Tapping opens an
/// XDA search pre-filled with the entry name plus a placeholder reminding
/// users to add their own device model, without triggering the card's main
/// [InkWell].
class _XdaPill extends StatelessWidget {
  const _XdaPill({required this.searchName, required this.searchKind});

  final String searchName;
  final String searchKind;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String kind = searchKind.trim();
    final String tooltip = kind.isEmpty
        ? 'Search for $searchName on XDA Forums'
        : 'Search for the $searchName $kind on XDA Forums '
            '(remember to add your device model)';
    final String query = kind.isEmpty
        ? '$searchName $kXdaQueryPlaceholder'
        : '$searchName $kind $kXdaQueryPlaceholder';
    return Tooltip(
      message: tooltip,
      child: Material(
        color: scheme.surface.withValues(alpha: 0.92),
        shape: const StadiumBorder(),
        elevation: 1,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => launchXdaSearch(context, xdaSearchUri(query)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.search, size: 14, color: scheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Search XDA',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
