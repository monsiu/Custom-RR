import 'package:flutter/material.dart';

import '../data/catalog_repository.dart';
import '../routes.dart';
import 'roms_page.dart';

class RootsPage extends StatelessWidget {
  const RootsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CatalogPage(
      title: 'Root Solutions',
      entries: CatalogRepository.instance.roots,
      heroPrefix: 'root',
      selectedRoute: AppRoutes.roots,
      detailPathBuilder: AppRoutes.rootDetail,
      entryKind: 'root',
    );
  }
}
