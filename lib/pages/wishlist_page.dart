import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/catalog_repository.dart';
import '../data/freshness_repository.dart';
import '../data/wishlist_repository.dart';
import '../models.dart';
import '../routes.dart';
import '../util/breakpoints.dart';
import '../widgets/app_shell.dart';
import '../widgets/freshness_badge.dart';

/// Shows the user's starred devices. Each row surfaces compatible ROMs +
/// recoveries with their freshness, plus a "build flash script" shortcut.
class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'My Devices',
      selectedRoute: AppRoutes.wishlist,
      body: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[
          WishlistRepository.instance,
          FreshnessRepository.instance,
        ]),
        builder: (BuildContext context, _) {
          final WishlistRepository wishlist = WishlistRepository.instance;
          final List<String> keys = wishlist.keys.toList()..sort();
          if (keys.isEmpty) {
            return _EmptyState();
          }
          final List<_RecentBuild> recent = wishlist.buildAlertsEnabled
              ? _recentBuilds(keys)
              : const <_RecentBuild>[];
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Breakpoints.readingMaxWidth,
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: keys.length + 1,
                itemBuilder: (BuildContext context, int i) {
                  if (i == 0) {
                    return _BuildAlertsCard(
                      enabled: wishlist.buildAlertsEnabled,
                      recent: recent,
                    );
                  }
                  final int keyIndex = i - 1;
                  final ({String brand, String codename})? split = wishlist
                      .splitKey(keys[keyIndex]);
                  if (split == null) return const SizedBox.shrink();
                  return _StarredDeviceCard(
                    brand: split.brand,
                    codename: split.codename,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.star_outline_rounded,
              size: 64,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No starred devices yet',
              style: text.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the star on any device or ROM-detail row to add it here. '
              'Starred devices stay on your phone. Nothing is synced.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Find my phone'),
              onPressed: () => context.push(AppRoutes.findPhone),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentBuild {
  const _RecentBuild({
    required this.brand,
    required this.codename,
    required this.entry,
    required this.isRecovery,
    required this.info,
  });

  final String brand;
  final String codename;
  final CatalogEntry entry;
  final bool isRecovery;
  final FreshnessInfo info;
}

List<_RecentBuild> _recentBuilds(List<String> keys) {
  final CatalogRepository catalog = CatalogRepository.instance;
  final FreshnessRepository freshness = FreshnessRepository.instance;
  final List<_RecentBuild> out = <_RecentBuild>[];
  for (final String key in keys) {
    final ({String brand, String codename})? device = WishlistRepository
        .instance
        .splitKey(key);
    if (device == null) continue;
    for (final CatalogEntry entry in catalog.romsForCodename(
      device.brand,
      device.codename,
    )) {
      final FreshnessInfo info = freshness.forId(entry.id);
      if (info.daysAgo >= 0 && info.daysAgo <= 7 && info.lastBuild.isNotEmpty) {
        out.add(
          _RecentBuild(
            brand: device.brand,
            codename: device.codename,
            entry: entry,
            isRecovery: false,
            info: info,
          ),
        );
      }
    }
    for (final CatalogEntry entry in catalog.recoveriesForCodename(
      device.brand,
      device.codename,
    )) {
      final FreshnessInfo info = freshness.forId(entry.id);
      if (info.daysAgo >= 0 && info.daysAgo <= 7 && info.lastBuild.isNotEmpty) {
        out.add(
          _RecentBuild(
            brand: device.brand,
            codename: device.codename,
            entry: entry,
            isRecovery: true,
            info: info,
          ),
        );
      }
    }
  }
  out.sort((a, b) => a.info.daysAgo.compareTo(b.info.daysAgo));
  return out;
}

class _BuildAlertsCard extends StatelessWidget {
  const _BuildAlertsCard({required this.enabled, required this.recent});

  final bool enabled;
  final List<_RecentBuild> recent;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: <Widget>[
          SwitchListTile(
            secondary: Icon(
              Icons.notifications_active_outlined,
              color: scheme.primary,
            ),
            title: const Text('Show recent build alerts'),
            subtitle: const Text(
              'Highlight ROMs and recoveries updated in the past 7 days. '
              'This stays on your device; it does not send push notifications.',
            ),
            value: enabled,
            onChanged: WishlistRepository.instance.setBuildAlertsEnabled,
          ),
          if (enabled) ...<Widget>[
            const Divider(height: 1),
            if (recent.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.check_circle_outline, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No recent builds for your saved devices.',
                        style: text.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )
            else ...<Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${recent.length} recent build${recent.length == 1 ? '' : 's'}',
                    style: text.titleSmall,
                  ),
                ),
              ),
              for (final _RecentBuild item in recent.take(5))
                ListTile(
                  dense: true,
                  leading: Icon(
                    item.isRecovery ? Icons.settings_outlined : Icons.android,
                    color: scheme.primary,
                  ),
                  title: Text(item.entry.name),
                  subtitle: Text(
                    '${item.brand} $item.codename · ${item.info.lastBuild}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                    item.isRecovery
                        ? AppRoutes.recoveryDetail(item.entry.id)
                        : AppRoutes.romDetail(item.entry.id),
                  ),
                ),
              if (recent.length > 5)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    '+ ${recent.length - 5} more recent builds',
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _StarredDeviceCard extends StatelessWidget {
  const _StarredDeviceCard({required this.brand, required this.codename});
  final String brand;
  final String codename;

  @override
  Widget build(BuildContext context) {
    final CatalogRepository repo = CatalogRepository.instance;
    final DeviceRef? ref = repo.deviceRefByCodename(brand, codename);
    final List<CatalogEntry> roms = repo.romsForCodename(brand, codename);
    final List<CatalogEntry> recs = repo.recoveriesForCodename(brand, codename);
    final String displayName = ref?.model ?? codename;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    // Sort ROMs: active > stale > abandoned > unknown.
    final List<CatalogEntry> sortedRoms = List<CatalogEntry>.from(roms)
      ..sort((CatalogEntry a, CatalogEntry b) {
        final FreshnessRepository fr = FreshnessRepository.instance;
        return fr
            .forId(a.id)
            .status
            .index
            .compareTo(fr.forId(b.id).status.index);
      });

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('$brand $displayName', style: text.titleMedium),
                      Text(
                        'Codename: $codename',
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remove from My Devices',
                  icon: const Icon(Icons.star_rounded),
                  color: Colors.amber.shade600,
                  onPressed: () =>
                      WishlistRepository.instance.toggle(brand, codename),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (sortedRoms.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'No ROM in our catalog supports this device.',
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (final CatalogEntry e in sortedRoms.take(6))
                _RomLine(entry: e, isRecovery: false),
            if (sortedRoms.length > 6)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+ ${sortedRoms.length - 6} more',
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (recs.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Text(
                    'Recoveries:',
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  for (final CatalogEntry e in recs)
                    ActionChip(
                      visualDensity: VisualDensity.compact,
                      label: Text(e.name),
                      onPressed: () =>
                          context.push(AppRoutes.recoveryDetail(e.id)),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.list_alt),
              label: const Text('All compatibility'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              onPressed: () => context.push(
                AppRoutes.deviceModelDetail(_slugFor(brand), codename),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.terminal),
              label: const Text('Flash script'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              onPressed: () {
                final Uri uri = Uri(
                  path: AppRoutes.flashScript,
                  queryParameters: <String, String>{
                    'brand': brand,
                    'codename': codename,
                    if (sortedRoms.isNotEmpty) 'rom': sortedRoms.first.id,
                    if (recs.isNotEmpty) 'recovery': recs.first.id,
                  },
                );
                context.push(uri.toString());
              },
            ),
          ],
        ),
      ),
    );
  }

  String _slugFor(String brand) {
    for (final DeviceEntry d in CatalogRepository.instance.devices) {
      if (d.name == brand) return d.slug;
    }
    return brand.toLowerCase();
  }
}

class _RomLine extends StatelessWidget {
  const _RomLine({required this.entry, required this.isRecovery});
  final CatalogEntry entry;
  final bool isRecovery;
  @override
  Widget build(BuildContext context) {
    final FreshnessInfo info = FreshnessRepository.instance.forId(entry.id);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.push(
        isRecovery
            ? AppRoutes.recoveryDetail(entry.id)
            : AppRoutes.romDetail(entry.id),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: <Widget>[
            Expanded(child: Text(entry.name)),
            FreshnessBadge(info: info, compact: true),
          ],
        ),
      ),
    );
  }
}
