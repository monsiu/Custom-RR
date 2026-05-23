import 'package:flutter/material.dart';

import '../data/wishlist_repository.dart';

/// IconButton that toggles a (brand, codename) entry in the [WishlistRepository].
/// Rebuilds via [AnimatedBuilder] on the singleton repository's notifier.
class StarButton extends StatelessWidget {
  const StarButton({
    super.key,
    required this.brand,
    required this.codename,
    this.tooltipName,
    this.iconSize = 24,
  });

  final String brand;
  final String codename;

  /// Display name to surface in the tooltip ("Star the Pixel 6 Pro").
  /// Defaults to the codename when null.
  final String? tooltipName;

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final WishlistRepository repo = WishlistRepository.instance;
    return AnimatedBuilder(
      animation: repo,
      builder: (BuildContext context, _) {
        final bool starred = repo.contains(brand, codename);
        final String name = tooltipName ?? codename;
        return IconButton(
          tooltip: starred
              ? 'Remove $name from My Devices'
              : 'Add $name to My Devices',
          iconSize: iconSize,
          color: starred ? Colors.amber.shade600 : scheme.onSurfaceVariant,
          icon: Icon(starred ? Icons.star_rounded : Icons.star_outline_rounded),
          onPressed: () async {
            await repo.toggle(brand, codename);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  starred
                      ? 'Removed $name from My Devices'
                      : 'Added $name to My Devices',
                ),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }
}
