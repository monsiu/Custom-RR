import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/catalog_repository.dart';
import '../models.dart';
import '../routes.dart';
import '../widgets/app_shell.dart';
import '../widgets/brand_image.dart';
import '../widgets/treble_hint.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _matches(DeviceEntry d, String q, CatalogRepository repo) {
    if (q.isEmpty) return true;
    if (d.name.toLowerCase().contains(q)) return true;
    // Also match if any of the brand's supported phone models or codenames
    // contain the query. Lets users find their phone by model name.
    for (final DeviceRef ref in repo.modelsForDevice(d.name)) {
      if (ref.model.toLowerCase().contains(q) ||
          ref.codename.toLowerCase().contains(q)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final CatalogRepository repo = CatalogRepository.instance;
    final String q = _query.trim().toLowerCase();
    final List<DeviceEntry> devices = q.isEmpty
        ? repo.devices
        : repo.devices
            .where((DeviceEntry d) => _matches(d, q, repo))
            .toList(growable: false);
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return AppShell(
      title: 'Devices',
      selectedRoute: AppRoutes.devices,
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onChanged: (String v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search brand, model, or codename',
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
          Expanded(
            child: devices.isEmpty
                ? Center(
                    child: Text(
                      'No devices match "$_query".',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  )
                : CustomScrollView(
                    slivers: <Widget>[
                      SliverPadding(
                        padding: const EdgeInsets.all(12),
                        sliver: SliverGrid.builder(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.9,
                          ),
                          itemCount: devices.length,
                          itemBuilder: (BuildContext context, int index) {
                            return _DeviceTile(device: devices[index]);
                          },
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: TrebleHintBanner(kind: 'device'),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.device});

  final DeviceEntry device;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final CatalogRepository repo = CatalogRepository.instance;
    final int romCount = repo.romsForDevice(device.name).length;
    final int recCount = repo.recoveriesForDevice(device.name).length;
    final String romLabel = '$romCount ROM${romCount == 1 ? '' : 's'}';
    final String recLabel =
        '$recCount recover${recCount == 1 ? 'y' : 'ies'}';
    // Recovery-only brands (no ROM targets them) show their recovery count
    // instead of a dispiriting "0 ROMs".
    final String cardLabel = romCount == 0 ? recLabel : romLabel;

    return Tooltip(
      message: '${device.name}: $romLabel, $recLabel',
      child: Semantics(
        label:
            '${device.name}. $romLabel and $recLabel available.',
        button: true,
        child: Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            onTap: () => context.push(AppRoutes.deviceDetail(device.slug)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Hero(
                      tag: 'device-${device.slug}',
                      child: BrandImage(
                        asset: device.imageAsset,
                        semanticLabel: device.name,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                  child: Text(
                    device.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: scheme.onSurface,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Text(
                    cardLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
