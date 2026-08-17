import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/catalog_repository.dart';
import '../data/device_index.dart';
import '../data/freshness_repository.dart';
import '../models.dart';
import '../routes.dart';
import '../util/breakpoints.dart';
import '../util/codename_aliases.dart';
import '../util/request_project.dart';
import '../util/xda_search.dart';
import '../widgets/app_shell.dart';
import '../widgets/brand_image.dart';
import '../widgets/catalog_card.dart' show xdaSearchUri;
import '../widgets/device_suggestion.dart';
import '../widgets/freshness_badge.dart';
import '../widgets/select_device_button.dart';
import '../widgets/star_button.dart';

/// "What can I flash on my phone?" reverse lookup.
///
/// User types a brand, model name, or codename → the page shows every
/// (brand, model, codename) match across the catalog, and for each match a
/// pre-computed list of compatible ROMs and recoveries with their
/// freshness badges.
class FindPhonePage extends StatefulWidget {
  const FindPhonePage({super.key});

  @override
  State<FindPhonePage> createState() => _FindPhonePageState();
}

class _FindPhonePageState extends State<FindPhonePage> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  /// Device recognised from the bundled dictionary when the catalog has no
  /// match, so an unsupported phone still gets named instead of a dead end.
  KnownDevice? _recognised;

  @override
  void initState() {
    super.initState();
    DeviceIndex.instance.load().then((_) {
      if (mounted && _query.trim().isNotEmpty) setState(_resolveRecognised);
    });
  }

  void _resolveRecognised() {
    final String q = _query.trim();
    _recognised = q.isEmpty ? null : DeviceIndex.instance.lookup(q);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<DeviceRef> _allModels() {
    final CatalogRepository repo = CatalogRepository.instance;
    final Map<String, DeviceRef> seen = <String, DeviceRef>{};
    for (final CatalogEntry e in <CatalogEntry>[
      ...repo.roms,
      ...repo.recoveries,
    ]) {
      for (final DeviceRef d in e.devices) {
        if (d.codename.isEmpty) continue;
        seen.putIfAbsent('${d.brand}|${d.codename}', () => d);
      }
    }
    final List<DeviceRef> out = seen.values.toList()
      ..sort((DeviceRef a, DeviceRef b) {
        final int b1 = a.brand.toLowerCase().compareTo(b.brand.toLowerCase());
        if (b1 != 0) return b1;
        return a.model.toLowerCase().compareTo(b.model.toLowerCase());
      });
    return out;
  }

  /// Ranked search over brand, marketing name, codename and retail model
  /// number. The query also runs through [codenameCandidates], so a phone that
  /// reports `olive` or `rmx2151l1` finds the unified build it actually ships
  /// under, exactly like on-device detection already does.
  List<DeviceRef> _search(List<DeviceRef> all, String q) {
    final List<String> candidates = codenameCandidates(q);
    final List<(int, DeviceRef)> scored = <(int, DeviceRef)>[];

    for (final DeviceRef d in all) {
      final String codename = d.codename.toLowerCase();
      final Iterable<String> numbers =
          d.models.map((String m) => m.toLowerCase());

      int score = -1;
      if (numbers.any((String m) => m == q)) {
        score = 0; // exact retail model number, the strongest signal
      } else if (candidates
          .any((String c) => catalogCodenameMatches(codename, c))) {
        score = 1; // exact codename, including aliases and combined entries
      } else if (numbers.any((String m) => m.contains(q))) {
        score = 2;
      } else if (codename.contains(q)) {
        score = 3;
      } else if (d.model.toLowerCase().contains(q)) {
        score = 4;
      } else if (d.brand.toLowerCase().contains(q)) {
        score = 5;
      }
      if (score >= 0) scored.add((score, d));
    }

    scored.sort(((int, DeviceRef) a, (int, DeviceRef) b) {
      if (a.$1 != b.$1) return a.$1.compareTo(b.$1);
      final int byBrand =
          a.$2.brand.toLowerCase().compareTo(b.$2.brand.toLowerCase());
      if (byBrand != 0) return byBrand;
      return a.$2.model.toLowerCase().compareTo(b.$2.model.toLowerCase());
    });
    return scored.take(200).map(((int, DeviceRef) e) => e.$2).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final String q = _query.trim().toLowerCase();
    final List<DeviceRef> all = _allModels();
    final List<DeviceRef> visible =
        q.isEmpty ? const <DeviceRef>[] : _search(all, q);

    return AppShell(
      title: 'Find my phone',
      selectedRoute: AppRoutes.findPhone,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: Breakpoints.readingMaxWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: (String v) => setState(() {
                    _query = v;
                    _resolveRecognised();
                  }),
                  decoration: InputDecoration(
                    hintText: 'Brand, model, or codename '
                        '(e.g. "Pixel 6", "alioth")',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: 'Clear',
                            onPressed: () {
                              _controller.clear();
                              setState(() {
                                _query = '';
                                _recognised = null;
                              });
                            },
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                ),
              ),
              if (q.isEmpty)
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: <Widget>[
                      const DeviceSuggestion(),
                      Text(
                        'Start typing to discover every ROM and recovery '
                        'that supports your phone.',
                        style: text.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Catalog covers ${all.length} devices across '
                        '${CatalogRepository.instance.roms.length} ROMs and '
                        '${CatalogRepository.instance.recoveries.length} '
                        'recoveries.',
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              else if (visible.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (_recognised != null) ...<Widget>[
                            Text(
                              '${_recognised!.label} '
                              '(${_recognised!.codename})',
                              textAlign: TextAlign.center,
                              style: text.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'We recognise your device, but no project in the '
                              'catalog publishes a build for it yet. A Treble '
                              'GSI is usually the way in, and XDA is where '
                              'unofficial builds appear first.',
                              textAlign: TextAlign.center,
                              style: text.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ] else
                            Text(
                              'No device matches "$_query".\n\n'
                              'Try the codename (e.g. "oriole" for Pixel 6), or '
                              'a simpler brand + model spelling.',
                              textAlign: TextAlign.center,
                              style: text.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          const SizedBox(height: 20),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              OutlinedButton.icon(
                                icon: const Icon(Icons.forum_outlined),
                                label: const Text('Search XDA'),
                                onPressed: () => launchXdaDeviceSearch(
                                  context,
                                  xdaSearchUri(_query.trim()),
                                ),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.download_outlined),
                                label: const Text('Community builds'),
                                onPressed: () => context.push(
                                  '${AppRoutes.communityBuilds}'
                                  '?q=${Uri.encodeComponent(_query.trim())}',
                                ),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.add_to_home_screen),
                                label: const Text('Request this device'),
                                onPressed: () =>
                                    openDeviceRequest(query: _query.trim()),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: visible.length,
                    itemBuilder: (BuildContext context, int i) =>
                        _DeviceMatchCard(ref: visible[i]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceMatchCard extends StatelessWidget {
  const _DeviceMatchCard({required this.ref});

  final DeviceRef ref;

  @override
  Widget build(BuildContext context) {
    final CatalogRepository repo = CatalogRepository.instance;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final List<CatalogEntry> roms =
        repo.romsForCodename(ref.brand, ref.codename);
    final List<CatalogEntry> recs =
        repo.recoveriesForCodename(ref.brand, ref.codename);
    final DeviceEntry? brandEntry = () {
      for (final DeviceEntry d in repo.devices) {
        if (d.name == ref.brand) return d;
      }
      return null;
    }();

    // Compute a freshness summary so the user can see at a glance if any
    // ROM still ships builds for this phone.
    final FreshnessRepository fr = FreshnessRepository.instance;
    int active = 0;
    int stale = 0;
    for (final CatalogEntry e in roms) {
      switch (fr.forId(e.id).status) {
        case FreshnessStatus.active:
          active++;
        case FreshnessStatus.stale:
          stale++;
        case FreshnessStatus.abandoned:
        case FreshnessStatus.unknown:
          break;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: scheme.surfaceContainerHighest,
          foregroundImage:
              brandEntry == null ? null : AssetImage(brandEntry.imageAsset),
          child:
              brandEntry == null ? const Icon(Icons.smartphone_outlined) : null,
        ),
        title: Text('${ref.brand} ${ref.model}'),
        subtitle: Text(
          ref.models.isEmpty
              ? 'Codename: ${ref.codename}'
              : 'Codename: ${ref.codename}  ·  ${ref.models.take(3).join(', ')}',
        ),
        trailing: Wrap(
          spacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            if (active > 0)
              _MiniCount(label: '$active active', color: Colors.green.shade600)
            else if (stale > 0)
              _MiniCount(label: '$stale stale', color: Colors.amber.shade700)
            else if (roms.isNotEmpty)
              _MiniCount(
                label: '${roms.length} old',
                color: Colors.red.shade700,
              )
            else
              _MiniCount(label: 'none', color: scheme.outline),
            StarButton(
              brand: ref.brand,
              codename: ref.codename,
              tooltipName: '${ref.brand} ${ref.model}',
              iconSize: 22,
            ),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: <Widget>[
          if (roms.isEmpty && recs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'No catalogued ROM or recovery lists this device as supported.',
                style: text.bodyMedium,
              ),
            )
          else ...<Widget>[
            if (roms.isNotEmpty) ...<Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Text('ROMs', style: text.labelLarge),
              ),
              for (final CatalogEntry e in roms)
                _EntryRow(entry: e, isRecovery: false),
            ],
            if (recs.isNotEmpty) ...<Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text('Recoveries', style: text.labelLarge),
              ),
              for (final CatalogEntry e in recs)
                _EntryRow(entry: e, isRecovery: true),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: <Widget>[
                  SelectDeviceButton(
                    brand: ref.brand,
                    codename: ref.codename,
                    model: ref.model,
                  ),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.terminal),
                    label: const Text('Build a flash script'),
                    onPressed: () {
                      final Uri uri = Uri(
                        path: AppRoutes.flashScript,
                        queryParameters: <String, String>{
                          'brand': ref.brand,
                          'codename': ref.codename,
                          if (roms.isNotEmpty) 'rom': roms.first.id,
                          if (recs.isNotEmpty) 'recovery': recs.first.id,
                        },
                      );
                      context.push(uri.toString());
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniCount extends StatelessWidget {
  const _MiniCount({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, required this.isRecovery});
  final CatalogEntry entry;
  final bool isRecovery;
  @override
  Widget build(BuildContext context) {
    final FreshnessInfo info = FreshnessRepository.instance.forId(entry.id);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push(
          isRecovery
              ? AppRoutes.recoveryDetail(entry.id)
              : AppRoutes.romDetail(entry.id),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 36,
                height: 36,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: ColoredBox(
                    color: scheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: BrandImage(asset: entry.headerAsset),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.name,
                  style: Theme.of(context).textTheme.bodyLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              FreshnessBadge(info: info, compact: true),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
