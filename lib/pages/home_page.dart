import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/catalog_repository.dart';
import '../models.dart';
import '../routes.dart';
import '../util/breakpoints.dart';
import '../widgets/app_shell.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const List<_Action> _actions = <_Action>[
    _Action(
      icon: Icons.android_outlined,
      label: 'Custom ROMs',
      description: 'Browse popular custom ROMs',
      route: AppRoutes.roms,
    ),
    _Action(
      icon: Icons.restore,
      label: 'Custom Recoveries',
      description: 'TWRP, OrangeFox, PBRP and more',
      route: AppRoutes.recoveries,
    ),
    _Action(
      icon: Icons.smartphone_outlined,
      label: 'Supported Devices',
      description: 'See manufacturers covered',
      route: AppRoutes.devices,
    ),
    _Action(
      icon: Icons.travel_explore_outlined,
      label: 'Find my phone',
      description: 'Reverse lookup by brand, model or codename',
      route: AppRoutes.findPhone,
    ),
    _Action(
      icon: Icons.star_outline_rounded,
      label: 'My Devices',
      description: 'Phones you have starred for quick access',
      route: AppRoutes.wishlist,
    ),
    _Action(
      icon: Icons.terminal_outlined,
      label: 'Flash script',
      description: 'Generate a copy-paste fastboot script',
      route: AppRoutes.flashScript,
    ),
    _Action(
      icon: Icons.menu_book_outlined,
      label: 'Flashing Instructions',
      description: 'Step-by-step guide',
      route: AppRoutes.instructions,
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_SearchHit> _runSearch(String q) {
    final CatalogRepository repo = CatalogRepository.instance;
    final List<_SearchHit> hits = <_SearchHit>[];
    bool match(String s) => s.toLowerCase().contains(q);
    for (final CatalogEntry e in repo.roms) {
      if (match(e.name) || match(e.shortTagline) || match(e.id)) {
        hits.add(
          _SearchHit(
            title: e.name,
            subtitle: e.shortTagline,
            asset: e.headerAsset,
            icon: Icons.android_outlined,
            route: AppRoutes.romDetail(e.id),
            kind: 'ROM',
          ),
        );
      }
    }
    for (final CatalogEntry e in repo.recoveries) {
      if (match(e.name) || match(e.shortTagline) || match(e.id)) {
        hits.add(
          _SearchHit(
            title: e.name,
            subtitle: e.shortTagline,
            asset: e.headerAsset,
            icon: Icons.restore,
            route: AppRoutes.recoveryDetail(e.id),
            kind: 'Recovery',
          ),
        );
      }
    }
    for (final DeviceEntry d in repo.devices) {
      if (match(d.name)) {
        hits.add(
          _SearchHit(
            title: d.name,
            subtitle: 'Manufacturer',
            asset: d.imageAsset,
            icon: Icons.smartphone_outlined,
            route: AppRoutes.deviceDetail(d.slug),
            kind: 'Device',
          ),
        );
      }
    }
    return hits;
  }

  @override
  Widget build(BuildContext context) {
    final String q = _query.trim().toLowerCase();
    final List<_SearchHit> hits =
        q.isEmpty ? const <_SearchHit>[] : _runSearch(q);

    return AppShell(
      title: 'Custom RR',
      selectedRoute: AppRoutes.home,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth >= 720;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Breakpoints.readingMaxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onChanged: (String v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'Search ROMs, recoveries, devices…',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close),
                                tooltip: 'Clear',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (q.isNotEmpty)
                      _SearchResults(hits: hits, query: q)
                    else ...<Widget>[
                      Center(
                        child: Hero(
                          tag: 'splash',
                          child: Image.asset(
                            'images/splash_image.png',
                            height: 200,
                            filterQuality: FilterQuality.medium,
                            semanticLabel: 'Custom RR logo',
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Welcome to Custom RR',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your one-stop guide to Android Custom ROMs and Recoveries: '
                        'browse projects, learn about their features and grab the '
                        'official download links.',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      if (wide)
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 2.1,
                          children: <Widget>[
                            for (final _Action a in _actions)
                              _ActionCard(action: a),
                          ],
                        )
                      else
                        Column(
                          children: <Widget>[
                            for (final _Action a in _actions)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ActionCard(action: a),
                              ),
                          ],
                        ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.hits, required this.query});

  final List<_SearchHit> hits;
  final String query;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    if (hits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Text(
          'No results for "$query".',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            '${hits.length} result${hits.length == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
        for (final _SearchHit h in hits)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: SizedBox(
                width: 44,
                height: 44,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ColoredBox(
                    color: scheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Image.asset(
                        h.asset,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        errorBuilder:
                            (BuildContext _, Object __, StackTrace? ___) =>
                                Icon(h.icon),
                      ),
                    ),
                  ),
                ),
              ),
              title: Text(h.title),
              subtitle: Text(h.subtitle),
              trailing: Chip(
                label: Text(h.kind),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onTap: () => context.push(h.route),
            ),
          ),
      ],
    );
  }
}

class _SearchHit {
  const _SearchHit({
    required this.title,
    required this.subtitle,
    required this.asset,
    required this.icon,
    required this.route,
    required this.kind,
  });
  final String title;
  final String subtitle;
  final String asset;
  final IconData icon;
  final String route;
  final String kind;
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action});

  final _Action action;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.push(action.route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      action.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _Action {
  const _Action({
    required this.icon,
    required this.label,
    required this.description,
    required this.route,
  });
  final IconData icon;
  final String label;
  final String description;
  final String route;
}
