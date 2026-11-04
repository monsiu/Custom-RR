import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../routes.dart';
import '../util/breakpoints.dart';
import '../widgets/app_shell.dart';

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  static final Uri _services = Uri.parse('https://monsiu.github.io/services/');

  static Future<void> _openServices() async {
    await launchUrl(_services, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return AppShell(
      title: 'Services',
      selectedRoute: AppRoutes.services,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: Breakpoints.readingMaxWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              Icon(Icons.work_outline, size: 48, color: colors.primary),
              const SizedBox(height: 12),
              Text('Work with Monsiu', style: text.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'I build mobile apps, websites, and practical AI tools. '
                'Custom ROM builds are not offered. For catalog suggestions '
                'or issue reports, use Community → Issues so they can be '
                'triaged with the project.',
                style: text.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _openServices,
                icon: const Icon(Icons.open_in_new),
                label: const Text('View app and web services'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.community),
                icon: const Icon(Icons.forum_outlined),
                label: const Text('Open Community and Issues'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
