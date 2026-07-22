import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/update_notifier.dart';
import '../pages/easter_egg_page.dart';
import '../util/build_flags.dart';
import 'crypto_donate.dart';
import 'donation_feedback.dart';
import 'donation_nudge.dart';

/// Public GitHub repository for Custom RR.
const String kCustomRrRepoUrl = 'https://github.com/monsiu/Custom-RR';

/// GitHub Sponsors profile for the developer.
const String kSponsorsUrl = 'https://github.com/sponsors/monsiu';

/// Public Google Play store listing for Custom RR.
const String kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=io.github.monsiu.custom_rr';

/// Twitter / X profile for the developer.
const String kMonsiuTwitterUrl = 'https://twitter.com/MonsiuTech';

/// Telegram profile for the developer.
const String kMonsiuTelegramUrl = 'https://t.me/monsiu';

/// YouTube channel for the developer.
const String kMonsiuYouTubeUrl = 'https://youtube.com/@monsiutech';

/// Shows the standard about dialog (uses package_info_plus for version).
Future<void> showCustomAboutDialog(BuildContext context) async {
  final PackageInfo info = await PackageInfo.fromPlatform();
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (BuildContext dialogCtx) => _CustomAboutDialog(info: info),
  );
}

/// Custom AlertDialog that replicates Material's AboutDialog layout but
/// makes the version line tappable to unlock a hidden easter egg.
class _CustomAboutDialog extends StatefulWidget {
  const _CustomAboutDialog({required this.info});
  final PackageInfo info;

  @override
  State<_CustomAboutDialog> createState() => _CustomAboutDialogState();
}

class _CustomAboutDialogState extends State<_CustomAboutDialog> {
  static const int _kTapsToUnlock = 5;
  int _versionTaps = 0;
  DateTime _lastTap = DateTime.fromMillisecondsSinceEpoch(0);

  void _onVersionTap(BuildContext ctx) {
    final DateTime now = DateTime.now();
    // Reset the counter if the user pauses too long between taps.
    if (now.difference(_lastTap) > const Duration(seconds: 2)) {
      _versionTaps = 0;
    }
    _lastTap = now;
    setState(() {
      _versionTaps++;
    });
    if (_versionTaps >= _kTapsToUnlock) {
      _versionTaps = 0;
      final NavigatorState rootNav = Navigator.of(ctx, rootNavigator: true);
      debugPrint('[EasterEgg] Unlock triggered, popping dialog and pushing page');
      rootNav.pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          rootNav.push(
            MaterialPageRoute<void>(
              builder: (_) => const EasterEggPage(),
              fullscreenDialog: true,
            ),
          );
          debugPrint('[EasterEgg] Pushed EasterEggPage');
        } catch (e, st) {
          debugPrint('[EasterEgg] Failed to push page: $e\n$st');
        }
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final PackageInfo info = widget.info;
    final String versionLine = 'v${info.version}';

    return AlertDialog(
      scrollable: true,
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset('images/launcher.png', width: 48, height: 48),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('Custom RR', style: theme.textTheme.titleLarge),
                const SizedBox(height: 2),
                InkWell(
                  onTap: () => _onVersionTap(context),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          versionLine,
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (_versionTaps > 0) ...<Widget>[
                          const SizedBox(width: 8),
                          _TapPipsIndicator(
                            count: _versionTaps,
                            total: _kTapsToUnlock,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
      const SizedBox(height: 16),
      const Text(
        'Custom RR is a community-built, open-source guide to Android '
        'Custom ROMs and Recoveries. Browse projects, read about features, '
        'and grab official download links, all in one place.',
      ),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          icon: const Icon(Icons.code),
          label: const Text('View Custom RR on GitHub'),
          onPressed: () => launchUrl(
            Uri.parse(kCustomRrRepoUrl),
            mode: LaunchMode.externalApplication,
          ),
        ),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          icon: const Icon(Icons.alternate_email),
          label: const Text('Socials'),
          onPressed: () => _showSocials(context),
        ),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          icon: const Icon(Icons.coffee_outlined),
          label: const Text('Buy us a coffee'),
          onPressed: () async {
            final NavigatorState rootNav = Navigator.of(
              context,
              rootNavigator: true,
            );
            final BuildContext rootCtx = rootNav.context;
            rootNav.pop();
            await openSupportWithFeedback(rootCtx);
          },
        ),
      ),
      if (kShowCryptoDonate)
        Builder(
          builder: (BuildContext innerCtx) => Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.currency_bitcoin),
              label: const Text('Donate with crypto'),
              onPressed: () {
                final NavigatorState rootNav = Navigator.of(
                  innerCtx,
                  rootNavigator: true,
                );
                final BuildContext rootCtx = rootNav.context;
                rootNav.pop();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  showCryptoDonateSheet(rootCtx);
                });
              },
            ),
          ),
        ),
      if (kDebugMode)
        Builder(
          builder: (BuildContext innerCtx) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset donation prompt (debug)'),
                    onPressed: () async {
                      await DonationNudge.debugReset();
                      if (!innerCtx.mounted) return;
                      ScaffoldMessenger.of(innerCtx).showSnackBar(
                        const SnackBar(
                          content: Text('Donation prompt reset'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.system_update_alt),
                    label: const Text('Simulate update banner (debug)'),
                    onPressed: () async {
                      await UpdateNotifier.instance.debugSimulate();
                      if (!innerCtx.mounted) return;
                      Navigator.of(innerCtx, rootNavigator: true).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      const SizedBox(height: 16),
      Text(
        '© ${DateTime.now().year} Monsiu Tech Solutions',
        style: theme.textTheme.bodySmall,
      ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Future<void> _showSocials(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
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
                  launchUrl(
                    Uri.parse(kMonsiuTwitterUrl),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.send),
                title: const Text('Telegram'),
                subtitle: const Text('@monsiu'),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  launchUrl(
                    Uri.parse(kMonsiuTelegramUrl),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: const Text('YouTube'),
                subtitle: const Text('@monsiutech'),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  launchUrl(
                    Uri.parse(kMonsiuYouTubeUrl),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

/// Tiny row of pip dots that fill in as the user taps the version line.
class _TapPipsIndicator extends StatelessWidget {
  const _TapPipsIndicator({
    required this.count,
    required this.total,
    required this.color,
  });
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(total, (int i) {
        final bool filled = i < count;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.5),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? color : color.withValues(alpha: 0.2),
            ),
          ),
        );
      }),
    );
  }
}
