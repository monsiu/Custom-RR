import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../services/community_builds_feed.dart';
import 'shimmer_box.dart';

/// A card rendering one [CommunityBuild]: thumbnail, name, maintainer, summary,
/// device-tag chips, and download/rating/updated metadata. Tapping the card
/// runs [onOpen] (usually opening the listing's OpenDesktop page). When
/// [onDeviceTap] is provided, the device chips become tappable (used to filter
/// the community-builds list by that codename or vendor).
class CommunityBuildCard extends StatelessWidget {
  const CommunityBuildCard({
    super.key,
    required this.item,
    required this.onOpen,
    this.onDeviceTap,
  });

  final CommunityBuild item;
  final VoidCallback onOpen;
  final void Function(String tag)? onDeviceTap;

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
                          placeholder: (_, _) => const ShimmerBox(),
                          errorWidget: (_, _, _) => _thumbFallback(scheme),
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
                            CommunityDeviceChip(
                              label: tag,
                              onTap: onDeviceTap == null
                                  ? null
                                  : () => onDeviceTap!(tag),
                            ),
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
                          compactCount(item.downloads),
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
                          relativeTimeShort(item.updated),
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
/// Tappable when [onTap] is provided.
class CommunityDeviceChip extends StatelessWidget {
  const CommunityDeviceChip({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final Widget pill = Container(
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
    if (onTap == null) return pill;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: pill,
    );
  }
}

/// Formats a download count compactly, e.g. 238756 -> "238.8K".
String compactCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

/// Relative-time label like "3 days ago" / "2 months ago".
String relativeTimeShort(DateTime dt) {
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
