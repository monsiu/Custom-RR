import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/catalog_repository.dart';
import 'models.dart';
import 'pages/about_page.dart';
import 'pages/detail_page.dart';
import 'pages/device_model_page.dart';
import 'pages/device_page.dart';
import 'pages/devices_page.dart';
import 'pages/find_phone_page.dart';
import 'pages/flash_script_page.dart';
import 'pages/home_page.dart';
import 'pages/instructions_page.dart';
import 'pages/not_found_page.dart';
import 'pages/recoveries_page.dart';
import 'pages/roms_page.dart';
import 'pages/wishlist_page.dart';

/// Application route paths. These double as deep-link URLs
/// (Android App Links / iOS Universal Links) once intent-filters
/// and assetlinks.json are configured on a hosting domain.
class AppRoutes {
  const AppRoutes._();

  static const String home = '/';
  static const String roms = '/roms';
  static const String recoveries = '/recoveries';
  static const String devices = '/devices';
  static const String findPhone = '/find-my-phone';
  static const String wishlist = '/my-devices';
  static const String flashScript = '/flash-script';
  static const String instructions = '/instructions';
  static const String about = '/about';

  static String romDetail(String id) => '/roms/$id';
  static String recoveryDetail(String id) => '/recoveries/$id';
  static String deviceDetail(String slug) => '/devices/$slug';
  static String deviceModelDetail(String slug, String codename) =>
      '/devices/$slug/models/${Uri.encodeComponent(codename)}';
}

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: false,
    errorBuilder: (BuildContext context, GoRouterState state) =>
        NotFoundPage(uri: state.uri),
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.home,
        builder: (BuildContext _, GoRouterState __) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.roms,
        builder: (BuildContext _, GoRouterState __) => const RomsPage(),
        routes: <RouteBase>[
          GoRoute(
            path: ':id',
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
        path: AppRoutes.recoveries,
        builder: (BuildContext _, GoRouterState __) => const RecoveriesPage(),
        routes: <RouteBase>[
          GoRoute(
            path: ':id',
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
        path: AppRoutes.devices,
        builder: (BuildContext _, GoRouterState __) => const DevicesPage(),
        routes: <RouteBase>[
          GoRoute(
            path: ':slug',
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
                builder: (BuildContext context, GoRouterState state) {
                  final String slug = state.pathParameters['slug']!;
                  final String codename =
                      Uri.decodeComponent(state.pathParameters['codename']!);
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
        path: AppRoutes.instructions,
        builder: (BuildContext _, GoRouterState __) => const InstructionsPage(),
      ),
      GoRoute(
        path: AppRoutes.findPhone,
        builder: (BuildContext _, GoRouterState __) => const FindPhonePage(),
      ),
      GoRoute(
        path: AppRoutes.wishlist,
        builder: (BuildContext _, GoRouterState __) => const WishlistPage(),
      ),
      GoRoute(
        path: AppRoutes.flashScript,
        builder: (BuildContext context, GoRouterState state) {
          final String? brand = state.uri.queryParameters['brand'];
          final String? codename = state.uri.queryParameters['codename'];
          final String? romId = state.uri.queryParameters['rom'];
          final String? recoveryId = state.uri.queryParameters['recovery'];
          return FlashScriptPage(
            initialBrand: brand,
            initialCodename: codename,
            initialRomId: romId,
            initialRecoveryId: recoveryId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (BuildContext _, GoRouterState __) => const AboutPage(),
      ),
    ],
  );
}
