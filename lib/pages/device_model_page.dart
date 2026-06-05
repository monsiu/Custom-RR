import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/catalog_repository.dart';
import '../data/freshness_repository.dart';
import '../models.dart';
import '../routes.dart';
import '../util/breakpoints.dart';
import '../widgets/freshness_badge.dart';
import '../widgets/star_button.dart';
import '../widgets/xda_threads_section.dart';

/// Per-phone-model detail page. Lists every ROM and recovery that supports
/// the exact (brand, codename) combo. Reached by tapping a model chip on
/// the Device page or a ROM/recovery detail page.
class DeviceModelPage extends StatelessWidget {
  const DeviceModelPage({
    super.key,
    required this.brand,
    required this.codename,
  });

  final String brand;
  final String codename;

  @override
  Widget build(BuildContext context) {
    final CatalogRepository repo = CatalogRepository.instance;
    final DeviceRef? ref = repo.deviceRefByCodename(brand, codename);
    final List<CatalogEntry> roms = repo.romsForCodename(brand, codename);
    final List<CatalogEntry> recoveries =
        repo.recoveriesForCodename(brand, codename);
    final DeviceEntry? brandEntry = () {
      for (final DeviceEntry d in repo.devices) {
        if (d.name == brand) return d;
      }
      return null;
    }();
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final String modelLabel = ref?.model ?? codename;
    // Keep the header image below the status bar instead of hugging it.
    final double topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            pinned: true,
            stretch: true,
            expandedHeight: 200,
            title: Text('$brand $modelLabel'),
            actions: <Widget>[
              StarButton(
                brand: brand,
                codename: codename,
                tooltipName: '$brand $modelLabel',
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: ColoredBox(
                color: scheme.surfaceContainerHighest,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 24 + topInset, 24, 24),
                  child: CachedNetworkImage(
                    imageUrl:
                        'https://wiki.lineageos.org/images/devices/$codename.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    fadeInDuration: const Duration(milliseconds: 200),
                    placeholder: (BuildContext context, String url) => Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    errorWidget:
                        (BuildContext context, String url, Object error) =>
                            brandEntry == null
                                ? Icon(
                                    Icons.smartphone_outlined,
                                    color: scheme.primary,
                                    size: 96,
                                  )
                                : Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Image.asset(
                                      brandEntry.imageAsset,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.medium,
                                    ),
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          Chip(
                            avatar: const Icon(
                              Icons.business_outlined,
                              size: 16,
                            ),
                            label: Text(brand),
                            visualDensity: VisualDensity.compact,
                          ),
                          Chip(
                            avatar: const Icon(Icons.tag, size: 16),
                            label: Text(codename),
                            visualDensity: VisualDensity.compact,
                          ),
                          if (brandEntry != null)
                            ActionChip(
                              avatar: const Icon(
                                Icons.dashboard_outlined,
                                size: 16,
                              ),
                              label: Text('All $brand'),
                              onPressed: () => context.push(
                                AppRoutes.deviceDetail(brandEntry.slug),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${roms.length} ROM${roms.length == 1 ? '' : 's'} '
                        'and ${recoveries.length} '
                        'recover${recoveries.length == 1 ? 'y' : 'ies'} '
                        'list this device as supported.',
                        style: text.titleMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.tonalIcon(
                          icon: const Icon(Icons.terminal),
                          label: const Text('Generate flash script'),
                          onPressed: () {
                            final Uri uri = Uri(
                              path: AppRoutes.flashScript,
                              queryParameters: <String, String>{
                                'brand': brand,
                                'codename': codename,
                                if (roms.isNotEmpty) 'rom': roms.first.id,
                                if (recoveries.isNotEmpty)
                                  'recovery': recoveries.first.id,
                              },
                            );
                            context.push(uri.toString());
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (ref != null && ref.forumUrl.isNotEmpty) ...<Widget>[
                        XdaThreadsSection(forumUrl: ref.forumUrl),
                        const SizedBox(height: 32),
                      ] else ...<Widget>[
                        _XdaSearchFallback(
                          brand: brand,
                          model: modelLabel,
                          codename: codename,
                        ),
                        const SizedBox(height: 32),
                      ],
                      _ModelSection(
                        title: 'Compatible ROMs',
                        entries: roms,
                        emptyMessage:
                            'No catalogued ROM lists $brand $modelLabel '
                            '($codename) as supported.',
                        onTap: (CatalogEntry e) =>
                            context.push(AppRoutes.romDetail(e.id)),
                      ),
                      const SizedBox(height: 32),
                      _ModelSection(
                        title: 'Compatible Recoveries',
                        entries: recoveries,
                        emptyMessage:
                            'No catalogued recovery lists $brand $modelLabel '
                            '($codename) as supported.',
                        onTap: (CatalogEntry e) =>
                            context.push(AppRoutes.recoveryDetail(e.id)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelSection extends StatelessWidget {
  const _ModelSection({
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    FreshnessBadge(
                      info: FreshnessRepository.instance.forId(e.id),
                      compact: true,
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => onTap(e),
              ),
            ),
          ),
      ],
    );
  }
}

/// Fallback shown on model pages without a curated XDA Development forum.
/// Sends users to an XDA-wide search prefilled with brand + model + codename
/// so they still have a one-tap path to community discussion.
class _XdaSearchFallback extends StatelessWidget {
  const _XdaSearchFallback({
    required this.brand,
    required this.model,
    required this.codename,
  });

  final String brand;
  final String model;
  final String codename;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final String query = <String>[brand, model, codename]
        .where((String s) => s.isNotEmpty)
        .join(' ');
    final Uri search = Uri.https(
      'xdaforums.com',
      '/search/',
      <String, String>{'q': query, 'o': 'date'},
    );

    return Card(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerHigh,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            launchUrl(search, mode: LaunchMode.externalApplication),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Icon(Icons.search, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Search XDA for this device', style: text.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      'No dedicated forum is mapped yet. Opens an XDA '
                      'search for "$query".',
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.open_in_new, size: 18, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
