import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/catalog_repository.dart';
import '../data/freshness_repository.dart';
import '../data/selected_device_controller.dart';
import '../models.dart';
import '../routes.dart';
import '../util/request_project.dart';
import '../util/xda_search.dart';
import '../widgets/app_shell.dart';
import '../widgets/catalog_card.dart';
import '../widgets/treble_hint.dart';

/// Shared list-or-grid catalog page used by both ROMs and Recoveries.
/// Includes a search field that filters entries by name or tagline.
class CatalogPage extends StatefulWidget {
  const CatalogPage({
    super.key,
    required this.title,
    required this.entries,
    required this.heroPrefix,
    required this.selectedRoute,
    required this.detailPathBuilder,
    this.defunct = const <DefunctEntry>[],
    this.entryKind = 'build',
    this.requestKind,
    this.filterByDevice = false,
  });

  final String title;
  final List<CatalogEntry> entries;
  final String heroPrefix;
  final String selectedRoute;
  final String Function(String id) detailPathBuilder;

  /// Short noun describing what a single entry is (e.g. "custom ROM" or
  /// "recovery"). Surfaced in tooltips and the XDA search query so users
  /// understand what they are looking at when hovering or searching.
  final String entryKind;

  /// Optional list of projects that are no longer actively maintained.
  /// Rendered as non-clickable chips below the main grid when there is no
  /// search query; tapping a chip just surfaces a snackbar explaining why
  /// the project is greyed out.
  final List<DefunctEntry> defunct;

  /// When non-null, a "Don't see your ROM/recovery? Request it" footer is
  /// shown at the bottom of the list and in the empty-search state. The value
  /// is a short label such as 'ROM' or 'recovery'. Left null (e.g. for Roots)
  /// to hide the footer entirely.
  final String? requestKind;

  /// When true, the list is narrowed to entries that support the user's
  /// selected device (see [SelectedDeviceController]). A dismissible banner
  /// lets the user fall back to the full list. Off for catalogs without
  /// per-device builds (e.g. Roots).
  final bool filterByDevice;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

/// A custom ROM/recovery that is no longer actively maintained and so does
/// not warrant a full detail page.
class DefunctEntry {
  const DefunctEntry({
    required this.name,
    required this.note,
    this.officialUrl = '',
    this.lastBuild = '',
    this.successor = '',
  });
  final String name;
  final String note;

  /// Optional URL of the project's original official site. Even when the
  /// site itself is dead, the card routes through the Wayback Machine so
  /// the user has a chance of seeing an archived snapshot.
  final String officialUrl;

  /// Optional short label for the last known official build, e.g. a year
  /// or version string ("2021", "Android 11"). Rendered as a small chip
  /// on the card so users can gauge how stale the project is.
  final String lastBuild;

  /// Optional comma-separated names of actively maintained projects users
  /// could look at instead. Rendered as a "Try instead" hint.
  final String successor;
}

class _CatalogPageState extends State<CatalogPage> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  _SortMode _sort = _SortMode.defaultOrder;

  /// When true, the device filter is temporarily ignored on this page so the
  /// user can browse every build without forgetting their selected device.
  bool _ignoreDeviceFilter = false;

  @override
  void initState() {
    super.initState();
    if (widget.filterByDevice) {
      SelectedDeviceController.instance.addListener(_onDeviceChanged);
    }
  }

  void _onDeviceChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (widget.filterByDevice) {
      SelectedDeviceController.instance.removeListener(_onDeviceChanged);
    }
    _controller.dispose();
    super.dispose();
  }

  bool _matches(CatalogEntry e, String q) {
    if (q.isEmpty) return true;
    return e.name.toLowerCase().contains(q) ||
        e.shortTagline.toLowerCase().contains(q) ||
        e.id.toLowerCase().contains(q);
  }

  Future<void> _refresh() async {
    // Refreshes the in-memory catalog from the bundled asset. A full remote
    // refresh would be wired here once the catalog can be fetched at runtime.
    await CatalogRepository.instance.reload();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final SelectedDeviceController dev = SelectedDeviceController.instance;
    final bool deviceFilterActive =
        widget.filterByDevice && dev.hasSelection && !_ignoreDeviceFilter;
    // Narrow to entries that list the selected (brand, codename) before any
    // search or sort is applied.
    final List<CatalogEntry> baseEntries = deviceFilterActive
        ? widget.entries
            .where(
              (CatalogEntry e) => e.devices.any(
                (DeviceRef d) =>
                    d.brand == dev.brand && d.codename == dev.codename,
              ),
            )
            .toList(growable: false)
        : widget.entries;

    final String q = _query.trim().toLowerCase();
    List<CatalogEntry> visible = q.isEmpty
        ? List<CatalogEntry>.from(baseEntries)
        : baseEntries
            .where((CatalogEntry e) => _matches(e, q))
            .toList(growable: false);
    switch (_sort) {
      case _SortMode.defaultOrder:
        break;
      case _SortMode.nameAsc:
        visible = List<CatalogEntry>.from(visible)
          ..sort(
            (CatalogEntry a, CatalogEntry b) =>
                a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
        break;
      case _SortMode.nameDesc:
        visible = List<CatalogEntry>.from(visible)
          ..sort(
            (CatalogEntry a, CatalogEntry b) =>
                b.name.toLowerCase().compareTo(a.name.toLowerCase()),
          );
        break;
      case _SortMode.freshestFirst:
        visible = List<CatalogEntry>.from(visible)
          ..sort(
            (CatalogEntry a, CatalogEntry b) =>
                _freshnessRank(a).compareTo(_freshnessRank(b)),
          );
        break;
      case _SortMode.oldestFirst:
        visible = List<CatalogEntry>.from(visible)
          ..sort(
            (CatalogEntry a, CatalogEntry b) =>
                _freshnessRank(b).compareTo(_freshnessRank(a)),
          );
        break;
    }
    final List<CatalogEntry> official = visible
        .where((CatalogEntry e) => !e.unofficial)
        .toList(growable: false);
    final List<CatalogEntry> unofficial = visible
        .where((CatalogEntry e) => e.unofficial)
        .toList(growable: false);
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return AppShell(
      title: widget.title,
      selectedRoute: widget.selectedRoute,
      body: Column(
        children: <Widget>[
          if (widget.filterByDevice && dev.hasSelection)
            _DeviceFilterBanner(
              label: dev.label,
              active: deviceFilterActive,
              onShowAll: () => setState(() => _ignoreDeviceFilter = true),
              onApply: () => setState(() => _ignoreDeviceFilter = false),
              onChange: () => context.push(AppRoutes.findPhone),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    onChanged: (String v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Search ${widget.title.toLowerCase()}',
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
                ),
                const SizedBox(width: 8),
                PopupMenuButton<_SortMode>(
                  tooltip: 'Sort',
                  icon: const Icon(Icons.sort),
                  initialValue: _sort,
                  onSelected: (_SortMode m) => setState(() => _sort = m),
                  itemBuilder: (BuildContext _) =>
                      const <PopupMenuEntry<_SortMode>>[
                    PopupMenuItem<_SortMode>(
                      value: _SortMode.defaultOrder,
                      child: Text('Default'),
                    ),
                    PopupMenuItem<_SortMode>(
                      value: _SortMode.freshestFirst,
                      child: Text('Last release (newest first)'),
                    ),
                    PopupMenuItem<_SortMode>(
                      value: _SortMode.oldestFirst,
                      child: Text('Last release (oldest first)'),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem<_SortMode>(
                      value: _SortMode.nameAsc,
                      child: Text('Name (A → Z)'),
                    ),
                    PopupMenuItem<_SortMode>(
                      value: _SortMode.nameDesc,
                      child: Text('Name (Z → A)'),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: 'Why XDA? Tap to learn more',
                  icon: const Icon(Icons.info),
                  color: scheme.primary,
                  onPressed: () => _showXdaInfo(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (deviceFilterActive && q.isEmpty) ...<Widget>[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'No catalogued '
                              '${widget.entryKind == 'recovery' ? 'recovery' : 'ROM'}'
                              ' lists ${dev.label} as supported.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: <Widget>[
                              FilledButton.tonalIcon(
                                icon: const Icon(Icons.clear_all),
                                label: const Text('Show all'),
                                onPressed: () =>
                                    setState(() => _ignoreDeviceFilter = true),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.smartphone_outlined),
                                label: const Text('Pick a different device'),
                                onPressed: () =>
                                    context.push(AppRoutes.findPhone),
                              ),
                            ],
                          ),
                        ] else
                          Text(
                            'No ${widget.title.toLowerCase()} match "$_query".',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        if (widget.requestKind != null && !deviceFilterActive)
                          _RequestProjectFooter(kind: widget.requestKind!),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                        final double w = constraints.maxWidth;
                        final int columns = w < 720 ? 1 : (w < 1100 ? 2 : 3);
                        // Show the defunct strip only when the user is
                        // browsing the full list (not searching).
                        final bool showDefunct =
                            q.isEmpty && widget.defunct.isNotEmpty;
                        List<Widget> entrySlivers(List<CatalogEntry> items) =>
                            <Widget>[
                              if (columns == 1)
                                SliverPadding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 4,
                                  ),
                                  sliver: SliverList.builder(
                                    itemCount: items.length,
                                    itemBuilder:
                                        (BuildContext context, int index) =>
                                            _entryCard(context, items[index]),
                                  ),
                                )
                              else
                                SliverPadding(
                                  padding: const EdgeInsets.all(12),
                                  sliver: SliverGrid.builder(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 1.15,
                                    ),
                                    itemCount: items.length,
                                    itemBuilder:
                                        (BuildContext context, int index) =>
                                            _entryCard(context, items[index]),
                                  ),
                                ),
                            ];
                        return CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: <Widget>[
                            ...entrySlivers(official),
                            if (unofficial.isNotEmpty) ...<Widget>[
                              const SliverToBoxAdapter(
                                child: _UnofficialHeader(),
                              ),
                              ...entrySlivers(unofficial),
                            ],
                            if (showDefunct)
                              SliverToBoxAdapter(
                                child: _DefunctSection(
                                  entries: widget.defunct,
                                ),
                              ),
                            if (widget.entryKind == 'custom ROM' &&
                                q.isEmpty)
                              const SliverToBoxAdapter(
                                child: _CommunityRomsCard(),
                              ),
                            if (widget.entryKind == 'custom ROM')
                              const SliverToBoxAdapter(
                                child: TrebleHintBanner(kind: 'ROM'),
                              ),
                            if (widget.requestKind != null)
                              SliverToBoxAdapter(
                                child: _RequestProjectFooter(
                                  kind: widget.requestKind!,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _entryCard(BuildContext context, CatalogEntry entry) {
    final String tag = '${widget.heroPrefix}-${entry.id}';
    return CatalogCard(
      title: entry.name,
      subtitle: entry.shortTagline,
      assetImage: entry.headerAsset,
      heroTag: tag,
      freshness: FreshnessRepository.instance.forId(entry.id),
      xdaSearchName: entry.name,
      xdaSearchKind: widget.entryKind,
      onTap: () => context.push(widget.detailPathBuilder(entry.id)),
    );
  }
}

/// Dismissible banner shown above the ROMs/Recoveries list when a device is
/// selected. Explains the active filter and offers escape hatches: browse
/// everything ("Show all") or switch device ("Change"). When the filter has
/// been turned off for this page it flips to an affordance to re-apply it.
class _DeviceFilterBanner extends StatelessWidget {
  const _DeviceFilterBanner({
    required this.label,
    required this.active,
    required this.onShowAll,
    required this.onApply,
    required this.onChange,
  });

  final String label;
  final bool active;
  final VoidCallback onShowAll;
  final VoidCallback onApply;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      color: scheme.secondaryContainer,
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: <Widget>[
          Icon(
            active ? Icons.filter_alt : Icons.filter_alt_off,
            size: 18,
            color: scheme.onSecondaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              active ? 'Showing builds for $label' : 'Showing all builds',
              style: text.bodyMedium?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
          if (active) ...<Widget>[
            TextButton(
              onPressed: onChange,
              child: const Text('Change'),
            ),
            TextButton(
              onPressed: onShowAll,
              child: const Text('Show all'),
            ),
          ] else
            TextButton.icon(
              onPressed: onApply,
              icon: const Icon(Icons.filter_alt, size: 16),
              label: const Text('Filter'),
            ),
        ],
      ),
    );
  }
}

/// "Don't see your ROM/recovery? Request it" prompt shown at the bottom of
/// the ROMs and Recoveries lists (and in the empty-search state). Opens a
/// prefilled GitHub issue via [openProjectRequest].
class _RequestProjectFooter extends StatelessWidget {
  const _RequestProjectFooter({required this.kind});

  /// Short label such as 'ROM' or 'recovery'.
  final String kind;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: <Widget>[
          Text(
            "Don't see your $kind?",
            style: text.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Tell us which one to add next.',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.playlist_add),
            label: Text('Request a $kind'),
            onPressed: () => openProjectRequest(kind: kind),
          ),
        ],
      ),
    );
  }
}

enum _SortMode { defaultOrder, nameAsc, nameDesc, freshestFirst, oldestFirst }

/// Shows a small dialog explaining why the app surfaces XDA Forums links
/// so prominently. Reused by both ROMs and Recoveries pages.
Future<void> _showXdaInfo(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      final ColorScheme scheme = Theme.of(context).colorScheme;
      return AlertDialog(
        icon: Icon(Icons.forum_outlined, color: scheme.primary),
        title: const Text('Why XDA Forums?'),
        content: const SingleChildScrollView(
          child: Text(
            'XDA Developers is the largest community for custom Android '
            'development. It hosts a huge archive of unofficial and '
            'community-maintained builds that you will not find on the '
            'official project sites:\n\n'
            '\u2022 Unofficial ports for devices the team has dropped or '
            'never supported.\n'
            '\u2022 Builds compiled by individual maintainers, often more '
            'up to date than the last official release.\n'
            '\u2022 Beta and test builds shared before they hit official '
            'channels.\n'
            '\u2022 Archived threads for ROMs and recoveries that are no '
            'longer maintained.\n\n'
            'Tip: always read the original thread for install instructions, '
            'known issues and the maintainer\'s reputation before flashing '
            'anything from XDA.',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      );
    },
  );
}

/// Lower = fresher. Unknown sorts to the end.
int _freshnessRank(CatalogEntry e) {
  final FreshnessInfo info = FreshnessRepository.instance.forId(e.id);
  if (info.status == FreshnessStatus.unknown || info.daysAgo < 0) {
    return 1 << 30;
  }
  return info.daysAgo;
}

/// Bridge to the live OpenDesktop community-builds browser, shown at the
/// bottom of the Custom ROMs list (full-list view only). Kept visually
/// distinct and clearly labelled "unvetted" so it never reads as part of the
/// curated catalog above it, while still giving ROM browsers an obvious way
/// to discover it.
class _CommunityRomsCard extends StatelessWidget {
  const _CommunityRomsCard();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(AppRoutes.communityBuilds),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
            child: Row(
              children: <Widget>[
                Icon(Icons.download_outlined, color: scheme.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Looking for more?',
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Browse thousands of community ROM uploads from '
                        'OpenDesktop. These are unvetted, third-party builds, '
                        'flash at your own risk.',
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Section header shown above community-maintained entries flagged as
/// [CatalogEntry.unofficial]. These are real catalog entries with full
/// detail pages; the header just sets expectations before the user taps.
class _UnofficialHeader extends StatelessWidget {
  const _UnofficialHeader();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Divider(color: scheme.outlineVariant),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Icon(
                Icons.science_outlined,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Unofficial builds',
                style: text.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'What counts as unofficial?',
                icon: const Icon(Icons.info_outline, size: 20),
                color: scheme.onSurfaceVariant,
                visualDensity: VisualDensity.compact,
                onPressed: () => _showUnofficialInfo(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Community-maintained builds for specific devices, published by '
            'independent developers rather than an official project. Read '
            "the maintainer's thread carefully before flashing.",
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Explains the official vs unofficial split used by the catalog. Opened
/// from the info button next to the "Unofficial builds" section header.
Future<void> _showUnofficialInfo(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      final ColorScheme scheme = Theme.of(context).colorScheme;
      return AlertDialog(
        icon: Icon(Icons.science_outlined, color: scheme.primary),
        title: const Text('Official vs unofficial'),
        content: const SingleChildScrollView(
          child: Text(
            'Official builds come from the ROM project itself: the team '
            'maintains the device, publishes builds on its own site or '
            'channels, and supports them under the project\u2019s name.\n\n'
            'Unofficial builds are made by independent developers, usually '
            'for one specific device. Custom RR lists a build as unofficial '
            'when any of these apply:\n\n'
            '\u2022 It is not published or endorsed by the project it is '
            'based on (for example a LineageOS port the LineageOS team does '
            'not ship).\n'
            '\u2022 It is maintained by an individual or a small community, '
            'typically distributed through an XDA thread.\n'
            '\u2022 The device is not on the project\u2019s official '
            'supported list.\n\n'
            'Unofficial does not mean bad: many are excellent and fill gaps '
            'the official projects leave. But quality, update cadence, and '
            'support depend entirely on the maintainer, so always read the '
            'thread, check the known issues, and keep a backup before '
            'flashing.',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      );
    },
  );
}

class _DefunctSection extends StatelessWidget {
  const _DefunctSection({required this.entries});

  final List<DefunctEntry> entries;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Divider(color: scheme.outlineVariant),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Icon(
                Icons.archive_outlined,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'No longer maintained',
                style: text.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'These projects have stopped shipping updates and are kept here '
            'for reference. You can still search XDA for archived community '
            'threads, or try the Wayback Machine snapshot of their old site.',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (BuildContext _, BoxConstraints constraints) {
              // Phones get one full-width card per row so the layout
              // matches the regular ROM list above; on wider screens we
              // keep the multi-column wrap with a comfortable ~320 cap.
              const double spacing = 12;
              const double targetWidth = 320;
              final double available = constraints.maxWidth;
              final int columns = available < targetWidth + spacing
                  ? 1
                  : ((available + spacing) / (targetWidth + spacing))
                      .floor()
                      .clamp(1, 4);
              final double itemWidth =
                  (available - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: <Widget>[
                  for (final DefunctEntry e in entries)
                    SizedBox(width: itemWidth, child: _DefunctCard(entry: e)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Larger card representation of a [DefunctEntry] with explicit
/// "Search on XDA" and "Old official site" actions. The card itself is
/// non-navigable; only the action buttons launch external URLs.
class _DefunctCard extends StatelessWidget {
  const _DefunctCard({required this.entry});

  final DefunctEntry entry;

  Future<void> _openXdaSearch(BuildContext context) => launchXdaSearch(
        context,
        xdaSearchUri('${entry.name} $kXdaQueryPlaceholder'),
        alwaysWarn: true,
      );

  Future<void> _openWaybackArchive() => launchUrl(
        Uri.parse('https://web.archive.org/web/2024/${entry.officialUrl}'),
        mode: LaunchMode.externalApplication,
      );

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final bool hasOfficial = entry.officialUrl.isNotEmpty;
    return Card(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Icon(
                    Icons.do_not_disturb_on_outlined,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        entry.name,
                        style: text.titleMedium?.copyWith(
                          color: scheme.onSurface,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.errorContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Archived',
                          style: text.labelSmall?.copyWith(
                            color: scheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              entry.note,
              style: text.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (entry.lastBuild.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.event_outlined,
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Last build: ${entry.lastBuild}',
                      style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (entry.successor.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.swap_horiz_outlined,
                    size: 14,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Try instead: ${entry.successor}',
                      style: text.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Search on XDA'),
                  onPressed: () => _openXdaSearch(context),
                ),
                if (hasOfficial)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text('Old official site'),
                    onPressed: _openWaybackArchive,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RomsPage extends StatelessWidget {
  const RomsPage({super.key});

  static const List<DefunctEntry> _defunct = <DefunctEntry>[
    DefunctEntry(
      name: 'AOSP Extended',
      note: 'No longer maintained. Development stopped in 2021.',
      officialUrl: 'https://www.aospextended.com/',
      lastBuild: '2021 (Android 11)',
      successor: 'Pixel Experience, crDroid',
    ),
    DefunctEntry(
      name: 'MoKee',
      note: 'No longer maintained. The project has been inactive for years.',
      officialUrl: 'https://www.mokeedev.com/',
      lastBuild: '2020',
      successor: 'LineageOS',
    ),
    DefunctEntry(
      name: 'Resurrection Remix',
      note:
          'Effectively dead. No recent official builds; rare community ports only.',
      officialUrl: 'https://resurrectionremix.com/',
      lastBuild: '2021 (Android 11)',
      successor: 'Evolution X, crDroid',
    ),
    DefunctEntry(
      name: 'Dirty Unicorns',
      note: 'No longer maintained. The team disbanded in 2020.',
      officialUrl: 'https://www.dirtyunicorns.com/',
      lastBuild: '2020 (Android 10)',
      successor: 'crDroid, Evolution X',
    ),
    DefunctEntry(
      name: 'Octavi OS',
      note: 'No longer maintained. Official builds ended in 2023.',
      officialUrl: 'https://octavi-os.com/',
      lastBuild: '2023 (Android 13)',
      successor: 'crDroid, Pixel Experience',
    ),
    DefunctEntry(
      name: 'Havoc-OS',
      note:
          'No longer maintained. Active development stalled after the Android 11 cycle.',
      officialUrl: 'https://havoc-os.com/',
      lastBuild: '2022 (Android 11)',
      successor: 'crDroid, Evolution X',
    ),
    DefunctEntry(
      name: 'ArrowOS',
      note:
          'Abandoned. The arrowos.net site has been offline since 2023 with no successor announced.',
      officialUrl: 'https://arrowos.net/',
      lastBuild: '2023 (Android 13)',
      successor: 'crDroid, Evolution X, DerpFest',
    ),
    DefunctEntry(
      name: 'POSP (Potato Open Sauce Project)',
      note:
          'Defunct. The project stopped publishing builds and the maintainer team has moved on.',
      officialUrl: 'https://posp.co/',
      lastBuild: '2023 (Android 13)',
      successor: 'crDroid, Evolution X',
    ),
    DefunctEntry(
      name: 'RisingOS (original)',
      note:
          'On hiatus. Development of the original project has paused; a community fork (RisingOS Revived) has picked up the codebase. See the RisingOS Revived page in this app.',
      officialUrl: 'https://risingos.org/',
      lastBuild: '2024 (Android 15)',
      successor: 'RisingOS Revived',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return CatalogPage(
      title: 'Custom ROMs',
      entries: CatalogRepository.instance.roms,
      heroPrefix: 'rom',
      selectedRoute: AppRoutes.roms,
      detailPathBuilder: AppRoutes.romDetail,
      defunct: _defunct,
      entryKind: 'custom ROM',
      requestKind: 'ROM',
      filterByDevice: true,
    );
  }
}
