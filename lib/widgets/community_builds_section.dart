import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../routes.dart';
import '../services/community_builds_feed.dart';
import 'community_build_card.dart';

/// Live "Unofficial community builds" section, fetched from the OpenDesktop
/// "Phone ROMS" community and matched to a device [term] (a codename like
/// `beryllium`, or a brand/vendor like `Xiaomi` when [isBrand] is true).
///
/// Rendered below the catalogued ROMs/recoveries on device pages with a clear
/// "not vetted" disclaimer. The section hides itself entirely while loading
/// and whenever there are no matches, so pages with no community uploads stay
/// clean. Shown on both the per-model page and the brand page.
class CommunityBuildsSection extends StatefulWidget {
  const CommunityBuildsSection({
    super.key,
    required this.term,
    required this.label,
    this.isBrand = false,
    this.limit = 6,
  });

  /// What to search and match against (codename or brand name).
  final String term;

  /// Display label used in the disclaimer and the "browse all" action.
  final String label;

  /// When true, wording is phrased for a manufacturer rather than one device.
  final bool isBrand;

  /// Maximum number of builds to show inline before the "browse all" link.
  final int limit;

  @override
  State<CommunityBuildsSection> createState() => _CommunityBuildsSectionState();
}

class _CommunityBuildsSectionState extends State<CommunityBuildsSection> {
  late Future<List<CommunityBuild>> _future;

  @override
  void initState() {
    super.initState();
    _future = CommunityBuildsFeed.instance.fetchMatching(
      widget.term,
      limit: widget.limit,
    );
  }

  @override
  void didUpdateWidget(CommunityBuildsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.term != widget.term || oldWidget.limit != widget.limit) {
      _future = CommunityBuildsFeed.instance.fetchMatching(
        widget.term,
        limit: widget.limit,
      );
    }
  }

  Future<void> _open(String url) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    bool ok = false;
    try {
      ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
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
    return FutureBuilder<List<CommunityBuild>>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<List<CommunityBuild>> snap) {
        final List<CommunityBuild> builds =
            snap.data ?? const <CommunityBuild>[];
        // Stay invisible while loading and whenever there is nothing to show,
        // so this secondary section never adds noise to a device page.
        if (builds.isEmpty) return const SizedBox.shrink();

        final ColorScheme scheme = Theme.of(context).colorScheme;
        final TextTheme text = Theme.of(context).textTheme;
        final String disclaimer = widget.isBrand
            ? 'These are unvetted, third-party uploads for ${widget.label} '
                'devices, not part of the Custom RR catalog and not reviewed '
                'by us. Flash at your own risk and confirm a build matches '
                'your exact model. Links open on OpenDesktop.'
            : 'These are unvetted, third-party uploads for ${widget.label}, '
                'not part of the Custom RR catalog and not reviewed by us. '
                'Flash at your own risk and confirm the build really matches '
                'your device. Links open on OpenDesktop.';
        final String browseLabel = widget.isBrand
            ? 'Browse all ${widget.label} community builds'
            : 'Browse all builds for ${widget.label}';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.science_outlined, color: scheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Unofficial community builds',
                    style: text.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
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
                    Icon(
                      Icons.warning_amber_rounded,
                      color: scheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        disclaimer,
                        style: text.bodyMedium?.copyWith(
                          color: scheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            for (final CommunityBuild b in builds)
              CommunityBuildCard(
                item: b,
                onOpen: () => _open(b.detailPage),
              ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.push(
                  '${AppRoutes.communityBuilds}'
                  '?q=${Uri.encodeQueryComponent(widget.term)}',
                ),
                icon: const Icon(Icons.travel_explore, size: 18),
                label: Text(browseLabel),
              ),
            ),
          ],
        );
      },
    );
  }
}
