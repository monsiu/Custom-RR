import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../data/catalog_repository.dart';
import '../models.dart';
import '../routes.dart';
import '../util/breakpoints.dart';
import '../widgets/app_shell.dart';
import '../widgets/device_suggestion.dart';
import '../widgets/donation_nudge.dart';

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
      icon: Icons.shield_outlined,
      label: 'Root',
      description: 'Magisk, KernelSU, APatch and more',
      route: AppRoutes.roots,
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
  final FocusNode _searchFocus = FocusNode(debugLabel: 'HomeSearch');
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _focusSearch() {
    _searchFocus.requestFocus();
    _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );
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
    for (final CatalogEntry e in repo.roots) {
      if (match(e.name) || match(e.shortTagline) || match(e.id)) {
        hits.add(
          _SearchHit(
            title: e.name,
            subtitle: e.shortTagline,
            asset: e.headerAsset,
            icon: Icons.shield_outlined,
            route: AppRoutes.rootDetail(e.id),
            kind: 'Root',
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
      body: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.keyK, control: true):
              _focusSearch,
          const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
              _focusSearch,
          const SingleActivator(LogicalKeyboardKey.keyF, control: true):
              _focusSearch,
          const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
              _focusSearch,
        },
        child: Focus(
          autofocus: true,
          child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // Search + welcome copy stay inside the reading column so they
          // remain comfortable to scan; the action grid below opts into a
          // wider container so it can flow into 2 or 3 even columns on
          // desktop instead of stretching two oversized cards across the
          // whole screen with an orphan on the last row.
          const double readingWidth = Breakpoints.readingMaxWidth;
          const double gridMaxWidth = 1100;
          final double available = constraints.maxWidth;
          final double gridWidth =
              available < gridMaxWidth ? available : gridMaxWidth;
          final bool wide = available >= 600;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: readingWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SizedBox(height: 8),
                        TextField(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          textInputAction: TextInputAction.search,
                          onChanged: (String v) => setState(() => _query = v),
                          decoration: InputDecoration(
                            hintText: 'Search ROMs, recoveries, root, devices…',
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
                      const DeviceSuggestion(),
                      const DonationNudge(),
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
                    ],
                      ],
                    ),
                  ),
                  if (q.isEmpty) ...<Widget>[
                    const SizedBox(height: 24),
                    // Action grid breaks out of the reading column so it
                    // can flow into multiple even columns on wide windows
                    // instead of leaving an orphan tile on the last row.
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: gridWidth),
                        child: wide
                            ? GridView(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 360,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  // Fixed height keeps every tile the same
                                  // visual weight regardless of how many
                                  // columns the viewport produces, so a
                                  // 3-column row never shrinks cards into
                                  // an awkward sliver.
                                  mainAxisExtent: 104,
                                ),
                                children: <Widget>[
                                  for (final _Action a in _actions)
                                    _ActionCard(action: a),
                                ],
                              )
                            : Column(
                                children: <Widget>[
                                  for (final _Action a in _actions)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: _ActionCard(action: a),
                                    ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
          ),
        ),
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
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'No results for "$query".',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            Card(
              color: scheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.bolt_rounded,
                          color: scheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Not listed? Try Project Treble',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: scheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'If your device is not in the catalog, it may still '
                      'be able to boot a Generic System Image (GSI). Most '
                      'Android 9+ phones are Treble-compatible and can run '
                      'community ROMs as a GSI even when nobody built a '
                      'device-specific port.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.tonalIcon(
                        onPressed: () => context.push(AppRoutes.treble),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Open Treble & GSI guide'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      action.label,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
