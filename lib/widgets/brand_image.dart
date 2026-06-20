import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'shimmer_box.dart';

/// Generic placeholder that ships in every build. Shown whenever a catalog
/// logo is unavailable (offline before first fetch, or not yet pushed to the
/// repo). While a logo is actively downloading a [ShimmerBox] is shown instead.
const String kBrandFallbackAsset = 'images/branding.png';

/// Base URL for repo-hosted images. Served through the jsDelivr CDN, which
/// mirrors the GitHub repo at the `@main` branch. jsDelivr gives proper cache
/// headers and global edge delivery (and works on networks that block
/// raw.githubusercontent.com), while still serving the latest pushed art, so
/// adding or correcting a logo only needs a push to the repo, not an app
/// update.
const String kRemoteImageBase =
    'https://cdn.jsdelivr.net/gh/monsiu/Custom-RR@main/';

/// Cache-busting version appended to every remote image URL as `?v=N`.
///
/// [CachedNetworkImage] keys its on-disk cache on the full URL, so a logo that
/// is OVERWRITTEN in place (same path, e.g. a corrected `images/lineageos.png`)
/// would keep showing the old cached copy for existing users. Bump this number
/// whenever you replace existing art in place and push: the changed `?v=`
/// makes every client refetch once (also a fresh cache key on the CDN). Adding
/// a NEW image under a new path does not need a bump.
const int kRemoteImageVersion = 1;

/// Renders any catalog logo (a device/brand `imageAsset` or a ROM/recovery
/// `headerAsset`) from the network, exactly like the catalog screenshots.
///
/// These images are NOT bundled in the app; they live in the repo's `images/`
/// folder and are loaded over the network via [CachedNetworkImage] (cached to
/// disk after first load). Because both the catalog data and the artwork it
/// points at are fetched from the repo, adding or correcting a logo only needs
/// a push to the repo, not an app update. A [ShimmerBox] shows while the image
/// downloads; the bundled generic placeholder ([kBrandFallbackAsset]) shows
/// when offline before the image has been cached.
class BrandImage extends StatelessWidget {
  const BrandImage({
    super.key,
    required this.asset,
    this.fit = BoxFit.contain,
    this.semanticLabel,
    this.cacheWidth,
  });

  /// Repo-relative image path from the catalog, e.g. `images/device_x.png`.
  final String asset;
  final BoxFit fit;
  final String? semanticLabel;

  /// Optional decode width cap (logical px * DPR) to avoid decoding full-res
  /// PNGs into the image cache on dense grids.
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    // The generic placeholder is bundled, so it never needs the network.
    if (asset == kBrandFallbackAsset) return _fallback(context);

    return CachedNetworkImage(
      imageUrl: '$kRemoteImageBase$asset?v=$kRemoteImageVersion',
      fit: fit,
      filterQuality: FilterQuality.medium,
      memCacheWidth: cacheWidth,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (BuildContext context, String _) => const ShimmerBox(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      errorWidget: (BuildContext context, String _, Object __) =>
          _fallback(context),
    );
  }

  /// The generic placeholder (always bundled), then a neutral icon.
  Widget _fallback(BuildContext context) {
    return Image.asset(
      kBrandFallbackAsset,
      fit: fit,
      filterQuality: FilterQuality.medium,
      semanticLabel: semanticLabel,
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
          Icon(
        Icons.smartphone_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
