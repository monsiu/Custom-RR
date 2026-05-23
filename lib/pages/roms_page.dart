import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/catalog_repository.dart';
import '../data/freshness_repository.dart';
import '../models.dart';
import '../routes.dart';
import '../widgets/app_shell.dart';
import '../widgets/catalog_card.dart';

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
  });

  final String title;
  final List<CatalogEntry> entries;
  final String heroPrefix;
  final String selectedRoute;
  final String Function(String id) detailPathBuilder;

  /// Optional list of projects that are no longer actively maintained.
  /// Rendered as non-clickable chips below the main grid when there is no
  /// search query; tapping a chip just surfaces a snackbar explaining why
  /// the project is greyed out.
  final List<DefunctEntry> defunct;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

/// A custom ROM/recovery that is no longer actively maintained and so does
/// not warrant a full detail page.
class DefunctEntry {
  const DefunctEntry({required this.name, required this.note});
  final String name;
  final String note;
}

class _CatalogPageState extends State<CatalogPage> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  _SortMode _sort = _SortMode.defaultOrder;

  @override
  void dispose() {
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
    final String q = _query.trim().toLowerCase();
    List<CatalogEntry> visible = q.isEmpty
        ? List<CatalogEntry>.from(widget.entries)
        : widget.entries
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
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return AppShell(
      title: widget.title,
      selectedRoute: widget.selectedRoute,
      body: Column(
        children: <Widget>[
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
              ],
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Text(
                      'No ${widget.title.toLowerCase()} match "$_query".',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
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
                        return CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: <Widget>[
                            if (columns == 1)
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 4,
                                ),
                                sliver: SliverList.builder(
                                  itemCount: visible.length,
                                  itemBuilder:
                                      (BuildContext context, int index) =>
                                          _entryCard(context, visible[index]),
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
                                  itemCount: visible.length,
                                  itemBuilder:
                                      (BuildContext context, int index) =>
                                          _entryCard(context, visible[index]),
                                ),
                              ),
                            if (showDefunct)
                              SliverToBoxAdapter(
                                child: _DefunctSection(
                                  entries: widget.defunct,
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
      onTap: () {
        // Preload the full-size header so the detail page doesn't briefly
        // show an empty hero target during the route transition.
        precacheImage(AssetImage(entry.headerAsset), context);
        context.push(widget.detailPathBuilder(entry.id));
      },
    );
  }
}

enum _SortMode { defaultOrder, nameAsc, nameDesc, freshestFirst, oldestFirst }

/// Lower = fresher. Unknown sorts to the end.
int _freshnessRank(CatalogEntry e) {
  final FreshnessInfo info = FreshnessRepository.instance.forId(e.id);
  if (info.status == FreshnessStatus.unknown || info.daysAgo < 0) {
    return 1 << 30;
  }
  return info.daysAgo;
}

class _DefunctSection extends StatelessWidget {
  const _DefunctSection({required this.entries});

  final List<DefunctEntry> entries;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Divider(color: scheme.outlineVariant),
          const SizedBox(height: 12),
          Text(
            'No longer maintained',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'These projects have stopped shipping updates and are kept here '
            'for reference only.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final DefunctEntry e in entries)
                Tooltip(
                  message: e.note,
                  child: ActionChip(
                    avatar: Icon(
                      Icons.do_not_disturb_on_outlined,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    label: Text(
                      e.name,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: scheme.onSurfaceVariant,
                      ),
                    ),
                    backgroundColor: scheme.surfaceContainerHighest,
                    side: BorderSide(color: scheme.outlineVariant),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${e.name} is ${e.note}'),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class RomsPage extends StatelessWidget {
  const RomsPage({super.key});

  static const List<DefunctEntry> _defunct = <DefunctEntry>[
    DefunctEntry(
      name: 'AOSP Extended',
      note: 'no longer maintained — development stopped in 2021.',
    ),
    DefunctEntry(
      name: 'MoKee',
      note: 'no longer maintained — the project has been inactive for years.',
    ),
    DefunctEntry(
      name: 'Resurrection Remix',
      note:
          'effectively dead — no recent official builds; rare community ports only.',
    ),
    DefunctEntry(
      name: 'Dirty Unicorns',
      note: 'no longer maintained — the team disbanded in 2020.',
    ),
    DefunctEntry(
      name: 'Octavi OS',
      note: 'no longer maintained — official builds ended in 2023.',
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
    );
  }
}
