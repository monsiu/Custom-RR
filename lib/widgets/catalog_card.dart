import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models.dart';
import 'freshness_badge.dart';

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

  @override
  State<CatalogCard> createState() => _CatalogCardState();
}

class _CatalogCardState extends State<CatalogCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    final Widget rawImage = widget.assetImage != null
        ? Image.asset(
            widget.assetImage!,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          )
        : CachedNetworkImage(
            imageUrl: widget.networkImage!,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
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
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: AnimatedScale(
          scale: _hovering ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: card,
        ),
      ),
    );
  }
}
