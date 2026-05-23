import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/catalog_repository.dart';
import '../data/freshness_repository.dart';
import '../models.dart';
import '../routes.dart';
import '../util/breakpoints.dart';
import '../widgets/freshness_badge.dart';
import '../widgets/zoomable_image_viewer.dart';

/// Generic detail page used for both ROMs and recoveries.
///
/// Uses a collapsing [SliverAppBar] with the entry's header image, and
/// constrains body width on wider screens for readability.
class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.entry, required this.heroTag});

  final CatalogEntry entry;
  final Object heroTag;

  Future<void> _openDownloads() async {
    final Uri uri = Uri.parse(entry.downloadUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            pinned: true,
            stretch: true,
            expandedHeight: 260,
            title: Text(entry.name),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const <StretchMode>[StretchMode.fadeTitle],
              background: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  ColoredBox(color: scheme.surfaceContainerHighest),
                  Hero(
                    tag: heroTag,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Image.asset(
                        entry.headerAsset,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                  // Scrim so the AppBar title and back arrow remain legible
                  // regardless of underlying image content.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.black.withValues(alpha: 0.55),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.35),
                        ],
                        stops: const <double>[0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ],
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
                      Text(entry.shortTagline, style: text.titleMedium),
                      const SizedBox(height: 12),
                      FreshnessBadge(
                        info: FreshnessRepository.instance.forId(entry.id),
                      ),
                      const SizedBox(height: 20),
                      for (final String paragraph
                          in entry.description) ...<Widget>[
                        Text(paragraph, style: text.bodyLarge),
                        const SizedBox(height: 12),
                      ],
                      if (entry.features.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 12),
                        Text('Key Features', style: text.titleLarge),
                        const SizedBox(height: 8),
                        for (final String feature in entry.features)
                          _FeatureRow(
                            text: feature,
                            color: scheme.primary,
                          ),
                      ],
                      if (entry.supportedManufacturers.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 24),
                        _DeviceShowcase(entry: entry),
                      ],
                      if (entry.screenshots.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 24),
                        Text('Screenshots', style: text.titleLarge),
                        const SizedBox(height: 12),
                        _Screenshots(
                          urls: entry.screenshots,
                          fallbackAsset: entry.headerAsset,
                        ),
                      ],
                      const SizedBox(height: 32),
                      Center(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.download_outlined),
                          label: Text(entry.downloadLabel),
                          onPressed: _openDownloads,
                        ),
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

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.check_circle, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class _Screenshots extends StatelessWidget {
  const _Screenshots({required this.urls, required this.fallbackAsset});

  final List<String> urls;
  final String fallbackAsset;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return CarouselSlider.builder(
      itemCount: urls.length,
      itemBuilder: (BuildContext context, int index, int _) {
        final String url = urls[index];
        final String tag = 'shot-$index-$url';
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () =>
                  showZoomableImage(context, imageUrl: url, heroTag: tag),
              child: Hero(
                tag: tag,
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  placeholder: (BuildContext _, String __) => ColoredBox(
                    color: scheme.surfaceContainerHighest,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  // Fall back to the entry's bundled hero (e.g. recovery logo)
                  // instead of a broken-image placeholder when a screenshot URL
                  // 404s or the host removes the image.
                  errorWidget: (BuildContext _, String __, Object ___) =>
                      ColoredBox(
                    color: scheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Image.asset(
                        fallbackAsset,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      options: CarouselOptions(
        height: 480,
        enableInfiniteScroll: urls.length > 1,
        viewportFraction: 0.72,
        enlargeCenterPage: true,
        autoPlay: false,
      ),
    );
  }
}

/// Compact, searchable, brand-grouped showcase of every phone supported by
/// a ROM or recovery. Replaces the old "Compatible Devices" + "Phone models"
/// flat chip walls (which could top 500 chips for TWRP).
class _DeviceShowcase extends StatefulWidget {
  const _DeviceShowcase({required this.entry});

  final CatalogEntry entry;

  @override
  State<_DeviceShowcase> createState() => _DeviceShowcaseState();
}

class _DeviceShowcaseState extends State<_DeviceShowcase> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Brand -> models, alphabetised both ways. Computed once per build; the
  /// underlying list is immutable so this is cheap.
  Map<String, List<DeviceRef>> get _groups {
    final Map<String, List<DeviceRef>> out = <String, List<DeviceRef>>{};
    for (final DeviceRef d in widget.entry.devices) {
      out.putIfAbsent(d.brand, () => <DeviceRef>[]).add(d);
    }
    for (final List<DeviceRef> list in out.values) {
      list.sort(
        (DeviceRef a, DeviceRef b) =>
            a.model.toLowerCase().compareTo(b.model.toLowerCase()),
      );
    }
    final List<String> brands = out.keys.toList()
      ..sort(
        (String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()),
      );
    return <String, List<DeviceRef>>{
      for (final String b in brands) b: out[b]!,
    };
  }

  bool _matches(DeviceRef d, String q) {
    if (q.isEmpty) return true;
    return d.model.toLowerCase().contains(q) ||
        d.codename.toLowerCase().contains(q) ||
        d.brand.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final Map<String, List<DeviceRef>> groups = _groups;
    final String q = _query.trim().toLowerCase();
    final bool filtering = q.isNotEmpty;

    int totalMatches = 0;
    final List<MapEntry<String, List<DeviceRef>>> visible =
        <MapEntry<String, List<DeviceRef>>>[];
    for (final MapEntry<String, List<DeviceRef>> e in groups.entries) {
      final List<DeviceRef> matches = filtering
          ? e.value.where((DeviceRef d) => _matches(d, q)).toList()
          : e.value;
      if (matches.isEmpty) continue;
      visible.add(MapEntry<String, List<DeviceRef>>(e.key, matches));
      totalMatches += matches.length;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text('Supported devices', style: text.titleLarge),
            ),
            Text(
              filtering
                  ? '$totalMatches / ${widget.entry.devices.length}'
                  : '${widget.entry.devices.length} devices, '
                      '${groups.length} brands',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          onChanged: (String v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Search model, brand, or codename',
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
        if (visible.isEmpty)
          Card(
            color: scheme.surfaceContainerHigh,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No devices match "$_query".',
                style: text.bodyMedium,
              ),
            ),
          )
        else
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Theme(
              // Drop the default divider between ExpansionTiles for a
              // cleaner Material 3 look.
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
              ),
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < visible.length; i++) ...<Widget>[
                    if (i > 0) const Divider(height: 1),
                    _BrandGroup(
                      brand: visible[i].key,
                      models: visible[i].value,
                      // Auto-expand when filtering, otherwise only the first
                      // brand starts open so the section stays compact.
                      initiallyExpanded: filtering || i == 0,
                      // Force a rebuild of the ExpansionTile when the filter
                      // toggles so `initiallyExpanded` is re-honoured.
                      key: ValueKey<String>(
                        '${visible[i].key}|${filtering ? 'f' : 'n'}',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _BrandGroup extends StatelessWidget {
  const _BrandGroup({
    super.key,
    required this.brand,
    required this.models,
    required this.initiallyExpanded,
  });

  final String brand;
  final List<DeviceRef> models;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    DeviceEntry? entry;
    for (final DeviceEntry d in CatalogRepository.instance.devices) {
      if (d.name == brand) {
        entry = d;
        break;
      }
    }
    final DeviceEntry? brandEntry = entry;

    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      leading: brandEntry == null
          ? CircleAvatar(
              backgroundColor: scheme.surfaceContainerHighest,
              child: const Icon(Icons.smartphone_outlined, size: 18),
            )
          : CircleAvatar(
              backgroundColor: scheme.surfaceContainerHighest,
              foregroundImage: AssetImage(brandEntry.imageAsset),
            ),
      title: Text(brand),
      subtitle: Text(
        '${models.length} model${models.length == 1 ? '' : 's'}',
      ),
      trailing: brandEntry == null
          ? null
          : IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Open $brand page',
              onPressed: () =>
                  context.push(AppRoutes.deviceDetail(brandEntry.slug)),
            ),
      children: <Widget>[
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (final DeviceRef d in models)
              Tooltip(
                message: d.codename.isEmpty
                    ? d.model
                    : 'Codename: ${d.codename} (long-press to copy)',
                child: GestureDetector(
                  onLongPress: d.codename.isEmpty
                      ? null
                      : () => _copyCodename(context, d.codename),
                  child: ActionChip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.smartphone_outlined, size: 16),
                    label: Text(d.model),
                    onPressed: brandEntry == null || d.codename.isEmpty
                        ? null
                        : () => context.push(
                              AppRoutes.deviceModelDetail(
                                brandEntry.slug,
                                d.codename,
                              ),
                            ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

Future<void> _copyCodename(BuildContext context, String codename) async {
  await Clipboard.setData(ClipboardData(text: codename));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Copied "$codename" to clipboard'),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
