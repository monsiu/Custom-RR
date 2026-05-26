import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/update_checker.dart';
import '../routes.dart';
import '../util/breakpoints.dart';
import '../widgets/app_shell.dart';
import '../widgets/crypto_donate.dart';
import '../widgets/donation_nudge.dart';
import 'easter_egg_page.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  static const int _kTapsToUnlock = 5;
  String _version = '';
  bool _checking = false;
  int _versionTaps = 0;
  DateTime _lastTap = DateTime.fromMillisecondsSinceEpoch(0);

  void _onVersionTap() {
    final DateTime now = DateTime.now();
    if (now.difference(_lastTap) > const Duration(seconds: 2)) {
      _versionTaps = 0;
    }
    _lastTap = now;
    setState(() {
      _versionTaps++;
    });
    if (_versionTaps >= _kTapsToUnlock) {
      _versionTaps = 0;
      debugPrint('[EasterEgg] About page unlock, pushing EasterEggPage');
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => const EasterEggPage(),
          fullscreenDialog: true,
        ),
      );
    }
  }

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
                child: InkWell(
                  onTap: _onVersionTap,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          _version,
                          style: text.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        if (_versionTaps > 0) ...<Widget>[
                          const SizedBox(width: 8),
                          for (int i = 0; i < _kTapsToUnlock; i++)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 1.5),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i < _versionTaps
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const DonationNudge(),
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
                leading: const Icon(Icons.system_update_alt),
                title: const Text('Check for updates'),
                subtitle: Text(
                  _version.isEmpty
                      ? 'Compares your version with the latest GitHub release'
                      : 'Current: $_version',
                ),
                trailing: _checking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: _checking ? null : _checkForUpdates,
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
              ListTile(
                leading: const Icon(Icons.currency_bitcoin),
                title: const Text('Donate with crypto'),
                onTap: () => showCryptoDonateSheet(context),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy policy'),
                subtitle: const Text('What the app does and does not collect'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AppRoutes.privacy),
              ),
              if (kDebugMode) ...<Widget>[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _resetDonationPrompt,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset donation prompt (debug)'),
                ),
              ],
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

  Future<void> _resetDonationPrompt() async {
    await DonationNudge.debugReset();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Donation prompt reset'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _checkForUpdates() async {
    setState(() => _checking = true);
    try {
      final UpdateCheckResult result = await UpdateChecker.instance.check();
      if (!mounted) return;
      await _showUpdateDialog(result);
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not check for updates: $e')),
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _showUpdateDialog(UpdateCheckResult result) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool noReleases = result.latestVersion.isEmpty;
    final bool upToDate = !noReleases && !result.isUpdateAvailable;

    final String title = noReleases
        ? 'No releases yet'
        : upToDate
            ? "You're up to date"
            : 'Update available';

    final String message = noReleases
        ? 'This repository has no published releases yet. You can still '
            'browse the source on GitHub.'
        : upToDate
            ? 'You are running the latest version (v${result.currentVersion}).'
            : 'Custom RR v${result.latestVersion} is available. '
                'You are on v${result.currentVersion}.';

    final String notes = result.releaseNotes.trim();
    final String trimmedNotes =
        notes.length > 600 ? '${notes.substring(0, 600)}\u2026' : notes;

    return showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          icon: Icon(
            upToDate ? Icons.check_circle_outline : Icons.system_update_alt,
            color: scheme.primary,
          ),
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(message),
                if (!noReleases && !upToDate && result.releaseName.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    result.releaseName,
                    style: Theme.of(ctx).textTheme.titleSmall,
                  ),
                ],
                if (!noReleases && !upToDate && trimmedNotes.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    trimmedNotes,
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(upToDate ? 'OK' : 'Later'),
            ),
            if (result.releaseUrl.isNotEmpty)
              FilledButton.tonal(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _open(Uri.parse(result.releaseUrl));
                },
                child: Text(noReleases ? 'Open repository' : 'Open release'),
              ),
          ],
        );
      },
    );
  }
}
