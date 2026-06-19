import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/catalog_repository.dart';
import '../models.dart';
import '../routes.dart';
import '../util/breakpoints.dart';
import '../widgets/brand_image.dart';
import '../widgets/home_on_back.dart';
import '../widgets/treble_hint.dart';

/// Device detail page: lists the ROMs and recoveries that explicitly
/// support this manufacturer (per the `devices` arrays in catalog.json).
class DevicePage extends StatelessWidget {
  const DevicePage({super.key, required this.device});

  final DeviceEntry device;

  @override
  Widget build(BuildContext context) {
    final CatalogRepository repo = CatalogRepository.instance;
    final List<CatalogEntry> roms = repo.romsForDevice(device.name);
    final List<CatalogEntry> recoveries = repo.recoveriesForDevice(device.name);
    final List<DeviceRef> models = repo.modelsForDevice(device.name);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    // Keep the header image below the status bar instead of hugging it.
    final double topInset = MediaQuery.paddingOf(context).top;

    return HomeOnBack(
      child: Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            pinned: true,
            stretch: true,
            expandedHeight: 220,
            title: Text(device.name),
            flexibleSpace: FlexibleSpaceBar(
              background: ColoredBox(
                color: scheme.surfaceContainerHighest,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(40, 40 + topInset, 40, 40),
                  child: Hero(
                    tag: 'device-${device.slug}',
                    child: BrandImage(
                      asset: device.imageAsset,
                      semanticLabel: device.name,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Breakpoints.readingMaxWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${roms.length} ROM${roms.length == 1 ? '' : 's'} '
                        'and ${recoveries.length} '
                        'recover${recoveries.length == 1 ? 'y' : 'ies'} '
                        'cover ${device.name} devices.',
                        style: text.titleMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (models.isNotEmpty) ...<Widget>[
                        _ModelShowcase(
                          deviceSlug: device.slug,
                          models: models,
                        ),
                        const SizedBox(height: 32),
                      ],
                      _Section(
                        title: 'Compatible ROMs',
                        entries: roms,
                        emptyMessage:
                            'No catalogued ROM lists ${device.name} as supported. Check the project sites for community builds.',
                        onTap: (CatalogEntry e) =>
                            context.push(AppRoutes.romDetail(e.id)),
                      ),
                      const SizedBox(height: 32),
                      _Section(
                        title: 'Compatible Recoveries',
                        entries: recoveries,
                        emptyMessage:
                            'No catalogued recovery lists ${device.name} as supported.',
                        onTap: (CatalogEntry e) =>
                            context.push(AppRoutes.recoveryDetail(e.id)),
                      ),
                      const SizedBox(height: 16),
                      TrebleHintBanner(
                        kind: roms.isEmpty ? 'no-roms' : 'device',
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.entries,
    required this.emptyMessage,
    required this.onTap,
  });

  final String title;
  final List<CatalogEntry> entries;
  final String emptyMessage;
  final ValueChanged<CatalogEntry> onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: text.titleLarge),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          Card(
            margin: EdgeInsets.zero,
            color: scheme.surfaceContainerHigh,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(emptyMessage, style: text.bodyMedium),
            ),
          )
        else
          ...entries.map(
            (CatalogEntry e) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: ColoredBox(
                      color: scheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Image.asset(
                          e.headerAsset,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    ),
                  ),
                ),
                title: Text(e.name),
                subtitle: Text(
                  e.shortTagline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onTap(e),
              ),
            ),
          ),
      ],
    );
  }
}

/// Collapsible, searchable list of phone models for a brand. Replaces the
/// chip wall that bombarded users on vendors like Xiaomi (often 100+ models).
/// Header always shows the total count; the body is collapsed by default
/// and reveals a search field + ActionChips when expanded.
class _ModelShowcase extends StatefulWidget {
  const _ModelShowcase({required this.deviceSlug, required this.models});

  final String deviceSlug;
  final List<DeviceRef> models;

  @override
  State<_ModelShowcase> createState() => _ModelShowcaseState();
}

class _ModelShowcaseState extends State<_ModelShowcase> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _matches(DeviceRef m, String q) {
    if (q.isEmpty) return true;
    return m.model.toLowerCase().contains(q) ||
        m.codename.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String q = _query.trim().toLowerCase();
    final List<DeviceRef> filtered = q.isEmpty
        ? widget.models
        : widget.models
            .where((DeviceRef m) => _matches(m, q))
            .toList(growable: false);
    final bool filtering = q.isNotEmpty;
    final String countLabel = filtering
        ? '${filtered.length} / ${widget.models.length}'
        : '${widget.models.length}';

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        // Hide the default divider lines so the tile reads as a single card.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          // Force re-honoring initiallyExpanded when filtering toggles, so a
          // search query opens the body even if the user collapsed it.
          key: ValueKey<String>('models|${filtering ? 'f' : 'n'}'),
          initiallyExpanded: filtering,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: const Icon(Icons.smartphone_outlined),
          title: Text('Phone models', style: text.titleLarge),
          subtitle: Text(
            filtering ? '$countLabel match' : '$countLabel total',
          ),
          children: <Widget>[
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onChanged: (String v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search model or codename',
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
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No models match "$_query".',
                  style: text.bodyMedium,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final DeviceRef m in filtered)
                    Tooltip(
                      message: m.codename.isEmpty
                          ? m.model
                          : '${m.model}\nCodename: ${m.codename}',
                      child: ActionChip(
                        avatar: const Icon(
                          Icons.smartphone_outlined,
                          size: 18,
                        ),
                        label: Text(
                          m.model,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () => context.push(
                          AppRoutes.deviceModelDetail(
                            widget.deviceSlug,
                            m.codename,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
