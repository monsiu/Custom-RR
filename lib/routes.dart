import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/catalog_repository.dart';
import 'models.dart';
import 'pages/about_page.dart';
import 'pages/community_builds_page.dart';
import 'pages/community_page.dart';
import 'pages/detail_page.dart';
import 'pages/device_model_page.dart';
import 'pages/device_page.dart';
import 'pages/devices_page.dart';
import 'pages/find_phone_page.dart';
import 'pages/flash_script_page.dart';
import 'pages/home_page.dart';
import 'pages/instructions_page.dart';
import 'pages/not_found_page.dart';
import 'pages/privacy_policy_page.dart';
import 'pages/recoveries_page.dart';
import 'pages/roms_page.dart';
import 'pages/roots_page.dart';
import 'pages/treble_page.dart';
import 'pages/wishlist_page.dart';
import 'util/platform_shell.dart';

/// Application route paths. These double as deep-link URLs
/// (Android App Links / iOS Universal Links) once intent-filters
/// and assetlinks.json are configured on a hosting domain.
class AppRoutes {
  const AppRoutes._();

  static const String home = '/';
  static const String roms = '/roms';
  static const String recoveries = '/recoveries';
  static const String roots = '/roots';
  static const String devices = '/devices';
  static const String findPhone = '/find-my-phone';
  static const String wishlist = '/my-devices';
  static const String flashScript = '/flash-script';
  static const String instructions = '/instructions';
  static const String treble = '/treble';
  static const String community = '/community';
  static const String communityBuilds = '/community-builds';
  static const String about = '/about';
  static const String privacy = '/privacy';

  static String romDetail(String id) => '/roms/$id';
  static String recoveryDetail(String id) => '/recoveries/$id';
  static String rootDetail(String id) => '/roots/$id';
  static String deviceDetail(String slug) => '/devices/$slug';
  static String deviceModelDetail(String slug, String codename) =>
      '/devices/$slug/models/${Uri.encodeComponent(codename)}';
}

/// Global key for the root [Navigator] managed by [GoRouter]. Exposed so
/// widgets that live ABOVE the router (for example, things mounted via
/// `MaterialApp.router`'s `builder`) can still call `showDialog` /
/// `Navigator.of(...)` through this key once the first frame is up.
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'rootNavigator');

GoRouter buildRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: false,
    errorBuilder: (BuildContext context, GoRouterState state) =>
        NotFoundPage(uri: state.uri),
    routes: <RouteBase>[
      // On desktop, wrap every route in a SelectionArea so users can
      // highlight and copy any text (ROM names, codenames, links). The
      // ShellRoute sits inside the root Navigator, satisfying
      // SelectionArea's Overlay-ancestor requirement.
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return useDesktopShell ? SelectionArea(child: child) : child;
        },
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.home,
            caseSensitive: false,
            builder: (BuildContext _, GoRouterState _) => const HomePage(),
            // Every other destination is nested under Home so that Home is
            // always at the bottom of the navigation stack. The system back
            // button and swipe-back gesture then pop natively toward Home
            // (showing the Android predictive-back peek of the page behind)
            // instead of leaving the app; any section opened from the drawer
            // is a single back away from Home.
            routes: <RouteBase>[
              GoRoute(
                path: 'roms',
                caseSensitive: false,
                builder:
                    (BuildContext _, GoRouterState _) => const RomsPage(),
                routes: <RouteBase>[
                  GoRoute(
                    path: ':id',
                    caseSensitive: false,
                    builder: (BuildContext context, GoRouterState state) {
                      final String id = state.pathParameters['id']!;
                      final CatalogEntry? entry =
                          CatalogRepository.instance.romById(id);
                      if (entry == null) {
                        return NotFoundPage(uri: state.uri);
                      }
                      return DetailPage(entry: entry, heroTag: 'rom-$id');
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'recoveries',
                caseSensitive: false,
                builder:
                    (BuildContext _, GoRouterState _) =>
                        const RecoveriesPage(),
                routes: <RouteBase>[
                  GoRoute(
                    path: ':id',
                    caseSensitive: false,
                    builder: (BuildContext context, GoRouterState state) {
                      final String id = state.pathParameters['id']!;
                      final CatalogEntry? entry =
                          CatalogRepository.instance.recoveryById(id);
                      if (entry == null) {
                        return NotFoundPage(uri: state.uri);
                      }
                      return DetailPage(entry: entry, heroTag: 'rec-$id');
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'roots',
                caseSensitive: false,
                builder:
                    (BuildContext _, GoRouterState _) => const RootsPage(),
                routes: <RouteBase>[
                  GoRoute(
                    path: ':id',
                    caseSensitive: false,
                    builder: (BuildContext context, GoRouterState state) {
                      final String id = state.pathParameters['id']!;
                      final CatalogEntry? entry =
                          CatalogRepository.instance.rootById(id);
                      if (entry == null) {
                        return NotFoundPage(uri: state.uri);
                      }
                      return DetailPage(entry: entry, heroTag: 'root-$id');
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'devices',
                caseSensitive: false,
                builder:
                    (BuildContext _, GoRouterState _) => const DevicesPage(),
                routes: <RouteBase>[
                  GoRoute(
                    path: ':slug',
                    caseSensitive: false,
                    builder: (BuildContext context, GoRouterState state) {
                      final String slug = state.pathParameters['slug']!;
                      final DeviceEntry? device =
                          CatalogRepository.instance.deviceBySlug(slug);
                      if (device == null) {
                        return NotFoundPage(uri: state.uri);
                      }
                      return DevicePage(device: device);
                    },
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'models/:codename',
                        caseSensitive: false,
                        builder: (BuildContext context, GoRouterState state) {
                          final String slug = state.pathParameters['slug']!;
                          final String codename = Uri.decodeComponent(
                            state.pathParameters['codename']!,
                          );
                          final DeviceEntry? device =
                              CatalogRepository.instance.deviceBySlug(slug);
                          if (device == null) {
                            return NotFoundPage(uri: state.uri);
                          }
                          return DeviceModelPage(
                            brand: device.name,
                            codename: codename,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: 'instructions',
                caseSensitive: false,
                builder:
                    (BuildContext _, GoRouterState _) =>
                        const InstructionsPage(),
              ),
              GoRoute(
                path: 'treble',
                caseSensitive: false,
                builder:
                    (BuildContext _, GoRouterState _) => const TreblePage(),
              ),
              GoRoute(
                path: 'community',
                caseSensitive: false,
                builder:
                    (BuildContext _, GoRouterState _) => const CommunityPage(),
              ),
              GoRoute(
                path: 'community-builds',
                caseSensitive: false,
                builder: (BuildContext _, GoRouterState state) =>
                    CommunityBuildsPage(
                  initialSearch: state.uri.queryParameters['q'] ?? '',
                ),
              ),
              GoRoute(
                path: 'find-my-phone',
                caseSensitive: false,
                builder:
                    (BuildContext _, GoRouterState _) => const FindPhonePage(),
              ),
              GoRoute(
                path: 'my-devices',
                caseSensitive: false,
                builder:
                    (BuildContext _, GoRouterState _) => const WishlistPage(),
              ),
              GoRoute(
                path: 'flash-script',
                caseSensitive: false,
                builder: (BuildContext context, GoRouterState state) {
                  final String? brand = state.uri.queryParameters['brand'];
                  final String? codename =
                      state.uri.queryParameters['codename'];
                  final String? romId = state.uri.queryParameters['rom'];
                  final String? recoveryId =
                      state.uri.queryParameters['recovery'];
                  return FlashScriptPage(
                    initialBrand: brand,
                    initialCodename: codename,
                    initialRomId: romId,
                    initialRecoveryId: recoveryId,
                  );
                },
              ),
              GoRoute(
                path: 'about',
                caseSensitive: false,
                builder:
                    (BuildContext _, GoRouterState _) => const AboutPage(),
              ),
              GoRoute(
                path: 'privacy',
                caseSensitive: false,
                builder:
                    (BuildContext _, GoRouterState _) =>
                        const PrivacyPolicyPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
