import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../routes.dart';

/// Compact home-page link to app and web development services.
class WorkWithMonsiuCard extends StatelessWidget {
  const WorkWithMonsiuCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.work_outline),
        title: const Text('Android apps & websites', maxLines: 1),
        subtitle: const Text('Work with Monsiu', maxLines: 1),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () => context.push(AppRoutes.services),
      ),
    );
  }
}
