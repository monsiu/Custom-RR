import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'data/catalog_repository.dart';
import 'data/freshness_repository.dart';
import 'data/wishlist_repository.dart';
import 'theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await Future.wait<void>(<Future<void>>[
    ThemeController.instance.load(),
    CatalogRepository.instance.load(),
    FreshnessRepository.instance.load(),
    WishlistRepository.instance.load(),
  ]);
  runApp(const CustomRrApp());
}
