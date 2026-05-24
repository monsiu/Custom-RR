import 'package:flutter/material.dart';

import '../models.dart';

/// Compact pill showing how recent a ROM/recovery build is.
///
/// Colour reflects [FreshnessInfo.status]:
///   green   = active   (build in last 60 days)
///   amber   = stale    (60-180 days)
///   red     = abandoned(> 180 days)
///   grey    = unknown
///
/// Use [compact] = true inside cards (icon only + age string).
class FreshnessBadge extends StatelessWidget {
  const FreshnessBadge({
    super.key,
    required this.info,
    this.compact = false,
  });

  final FreshnessInfo info;
  final bool compact;

  ({Color bg, Color fg, IconData icon, String label}) _style(
    BuildContext context,
  ) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    switch (info.status) {
      case FreshnessStatus.active:
        return (
          bg: Colors.green.shade600,
          fg: Colors.white,
          icon: Icons.check_circle,
          label: 'Active',
        );
      case FreshnessStatus.stale:
        return (
          bg: Colors.amber.shade700,
          fg: Colors.black,
          icon: Icons.schedule,
          label: 'Stale',
        );
      case FreshnessStatus.abandoned:
        return (
          bg: Colors.red.shade700,
          fg: Colors.white,
          icon: Icons.warning_amber_rounded,
          label: 'Abandoned',
        );
      case FreshnessStatus.unknown:
        return (
          bg: scheme.surfaceContainerHighest,
          fg: scheme.onSurfaceVariant,
          icon: Icons.help_outline,
          label: 'Unknown',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ({Color bg, Color fg, IconData icon, String label}) s = _style(
      context,
    );
    final String age = info.daysAgo >= 0 ? info.relativeBuilt : '-';
    final String text = compact ? age : '${s.label}  ·  $age';
    return Tooltip(
      message: info.daysAgo < 0
          ? 'Build freshness unknown.'
          : 'Latest known build: ${info.lastBuild} (${info.version}).',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: s.bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(s.icon, size: compact ? 12 : 14, color: s.fg),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                color: s.fg,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
