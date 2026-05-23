import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../routes.dart';
import '../util/breakpoints.dart';
import '../widgets/app_shell.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((PackageInfo info) {
      if (!mounted) return;
      setState(() {
        _version = 'v${info.version}+${info.buildNumber}';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return AppShell(
      title: 'About',
      selectedRoute: AppRoutes.about,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: Breakpoints.readingMaxWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'images/launcher.png',
                    height: 120,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(child: Text('Custom RR', style: text.headlineSmall)),
              Center(
                child: Text(
                  _version,
                  style: text.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('About the app', style: text.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Custom RR is a community-built, open-source guide for '
                'Android Custom ROMs and Recoveries, developed openly on '
                'GitHub at github.com/monsiu/Custom-RR. Discover popular '
                'projects, read about their features, view screenshots, '
                'and jump directly to official download pages.',
                style: text.bodyLarge,
              ),
              const SizedBox(height: 24),
              Text('Links', style: text.titleLarge),
              const SizedBox(height: 8),
              const ListTile(
                leading: Icon(Icons.code),
                title: Text('MonsiuTech Solutions'),
                subtitle: Text('Built with Flutter · by Monsiu'),
              ),
              ListTile(
                leading: const Icon(Icons.public),
                title: const Text('GitHub repository'),
                subtitle: const Text('github.com/monsiu/Custom-RR'),
                onTap: () => _open(
                  Uri.parse('https://github.com/monsiu/Custom-RR'),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: const Text('contactmonsiu@gmail.com'),
                onTap: () => _open(
                  Uri(
                    scheme: 'mailto',
                    path: 'contactmonsiu@gmail.com',
                    query: 'subject=Custom RR Feedback',
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.coffee_outlined),
                title: const Text('Buy us a coffee'),
                onTap: () => _open(
                  Uri.parse('https://www.buymeacoffee.com/monsiuYT'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
