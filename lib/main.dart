import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'data/catalog_repository.dart';
import 'data/freshness_repository.dart';
import 'data/wishlist_repository.dart';
import 'theme_controller.dart';
import 'util/platform_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initPlatformShell();
  // Desktop has plenty of RAM and grids scroll through many images;
  // raise the image cache so we don't re-decode on scroll-back.
  if (useDesktopShell) {
    PaintingBinding.instance.imageCache
      ..maximumSize = 2000
      ..maximumSizeBytes = 400 * 1024 * 1024;
  }
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Critical-path: things the first frame actually reads.
  // Freshness + wishlist are wired through ChangeNotifier, so we kick
  // their loads here but do NOT await them; pages rebuild via listeners
  // once the data lands. This shaves cold-start time on Linux/desktop.
  unawaited(FreshnessRepository.instance.load());
  unawaited(WishlistRepository.instance.load());
  await Future.wait<void>(<Future<void>>[
    ThemeController.instance.load(),
    CatalogRepository.instance.load(),
  ]);
  runApp(const CustomRrApp());
}
