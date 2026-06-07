import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/catalog_repository.dart';
import '../data/freshness_repository.dart';
import '../models.dart';
import '../routes.dart';
import '../util/breakpoints.dart';
import '../util/request_project.dart';
import '../widgets/app_shell.dart';
import '../widgets/device_suggestion.dart';
import '../widgets/freshness_badge.dart';
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

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final String q = _query.trim().toLowerCase();
    final List<DeviceRef> all = _allModels();
    final List<DeviceRef> visible = q.isEmpty
        ? const <DeviceRef>[]
        : all
            .where(
              (DeviceRef d) =>
                  d.brand.toLowerCase().contains(q) ||
                  d.model.toLowerCase().contains(q) ||
                  d.codename.toLowerCase().contains(q),
            )
            .take(200)
            .toList();

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
                  onChanged: (String v) => setState(() => _query = v),
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
                          OutlinedButton.icon(
                            icon: const Icon(Icons.add_to_home_screen),
                            label: const Text('Request this device'),
                            onPressed: () =>
                                openDeviceRequest(query: _query.trim()),
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
        subtitle: Text('Codename: ${ref.codename}'),
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
              child: FilledButton.tonalIcon(
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
                      child: Image.asset(
                        entry.headerAsset,
                        fit: BoxFit.contain,
                      ),
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
