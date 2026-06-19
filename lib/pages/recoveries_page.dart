import 'package:flutter/material.dart';

import '../data/catalog_repository.dart';
import '../routes.dart';
import 'roms_page.dart';

class RecoveriesPage extends StatelessWidget {
  const RecoveriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CatalogPage(
      title: 'Custom Recoveries',
      entries: CatalogRepository.instance.recoveries,
      heroPrefix: 'rec',
      selectedRoute: AppRoutes.recoveries,
      detailPathBuilder: AppRoutes.recoveryDetail,
      entryKind: 'recovery',
      requestKind: 'recovery',
      filterByDevice: true,
    );
  }
}
