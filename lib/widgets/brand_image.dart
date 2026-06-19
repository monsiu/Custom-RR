import 'package:flutter/material.dart';

/// Generic placeholder that ships in every build. Used as the fallback when a
/// brand's specific asset is unavailable.
const String kBrandFallbackAsset = 'images/branding.png';

/// Renders a manufacturer's bundled brand image, gracefully falling back to
/// the generic placeholder (and then a smartphone icon) if the asset is
/// missing from the current build.
///
/// Brand image paths come from the catalog, which is refreshed remotely. A
/// newer remote catalog can therefore reference a brand asset that an older,
/// not-yet-updated app bundle does not ship. Without a guard that renders a
/// broken image; this keeps it tidy until the user updates the app.
class BrandImage extends StatelessWidget {
  const BrandImage({
    super.key,
    required this.asset,
    this.fit = BoxFit.contain,
    this.semanticLabel,
  });

  final String asset;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      fit: fit,
      filterQuality: FilterQuality.medium,
      semanticLabel: semanticLabel,
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
        if (asset == kBrandFallbackAsset) {
          return Icon(
            Icons.smartphone_outlined,
            color: Theme.of(context).colorScheme.primary,
          );
        }
        return Image.asset(
          kBrandFallbackAsset,
          fit: fit,
          filterQuality: FilterQuality.medium,
          semanticLabel: semanticLabel,
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stack) => Icon(
            Icons.smartphone_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }
}
