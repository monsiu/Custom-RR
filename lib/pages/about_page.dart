import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/update_checker.dart';
import '../routes.dart';
import '../util/breakpoints.dart';
import '../util/build_flags.dart';
import '../widgets/about_dialog.dart';
import '../widgets/app_shell.dart';
import '../widgets/crypto_donate.dart';
import '../widgets/donation_feedback.dart';
import '../widgets/donation_nudge.dart';
import '../widgets/update_dialog.dart';
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
        _version = 'v${info.version}';
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
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('Monsiu Tech Solutions'),
                subtitle: const Text('Built with Flutter - by Monsiu'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(Uri.parse('https://monsiu.github.io/')),
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
                leading: const Icon(Icons.discord),
                title: const Text('Join the Discord'),
                subtitle: const Text('Hang out, ask questions, report bugs'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(
                  Uri.parse('https://discord.gg/uWZR8vR855'),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.alternate_email),
                title: const Text('Socials'),
                subtitle: const Text('Twitter / X, Telegram, YouTube'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showSocials,
              ),
              ListTile(
                leading: const Icon(Icons.shop_outlined),
                title: const Text('Google Play listing'),
                subtitle: const Text(
                  'Public install appears after the first production rollout',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(
                  Uri.parse(
                    'https://play.google.com/store/apps/details?id=io.github.monsiu.custom_rr',
                  ),
                ),
              ),
              if (kSelfUpdateEnabled)
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
              if (Breakpoints.isCompact(context))
                ListTile(
                  leading: const Icon(Icons.favorite_outline),
                  title: const Text('Support the project'),
                  subtitle: Text(
                    kShowCryptoDonate
                        ? 'Buy a coffee or donate crypto'
                        : 'Buy us a coffee',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showSupportChooser,
                )
              else ...<Widget>[
                ListTile(
                  leading: const Icon(Icons.coffee_outlined),
                  title: const Text('Buy us a coffee'),
                  onTap: _openSupport,
                ),
                if (kShowCryptoDonate)
                  ListTile(
                    leading: const Icon(Icons.currency_bitcoin),
                    title: const Text('Donate with crypto'),
                    onTap: () => showCryptoDonateSheet(context),
                  ),
              ],
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy policy'),
                subtitle: const Text('What the app does and does not collect'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AppRoutes.privacy),
              ),
              const SizedBox(height: 24),
              Text('Google Play status', style: text.titleLarge),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Custom RR has Google Play production access. '
                          'Public install and updates through Google Play '
                          'will appear after the first production rollout is '
                          'published.',
                          style: text.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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

  Future<void> _showSocials() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (BuildContext sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.alternate_email),
                title: const Text('Twitter / X'),
                subtitle: const Text('@MonsiuTech'),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _open(Uri.parse(kMonsiuTwitterUrl));
                },
              ),
              ListTile(
                leading: const Icon(Icons.send),
                title: const Text('Telegram'),
                subtitle: const Text('@monsiu'),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _open(Uri.parse(kMonsiuTelegramUrl));
                },
              ),
              ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: const Text('YouTube'),
                subtitle: const Text('@monsiutech'),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _open(Uri.parse(kMonsiuYouTubeUrl));
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openSupport() async {
    await openSupportWithFeedback(context);
  }

  Future<void> _showSupportChooser() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.coffee_outlined),
                title: const Text('Buy us a coffee'),
                subtitle: const Text('One-off tip via Buy Me a Coffee'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await openSupportWithFeedback(context);
                },
              ),
              if (kShowCryptoDonate)
                ListTile(
                  leading: const Icon(Icons.currency_bitcoin),
                  title: const Text('Donate with crypto'),
                  subtitle: const Text('BTC, ETH, and more'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    showCryptoDonateSheet(context);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
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
      await showUpdateDialog(context, result);
    } on Object catch (e) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (BuildContext ctx) {
          final ColorScheme scheme = Theme.of(ctx).colorScheme;
          return AlertDialog(
            icon: Icon(Icons.error_outline, color: scheme.error),
            title: const Text('Could not check for updates'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                child: Text(humanizeUpdateError(e)),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }
}
