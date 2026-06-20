import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/beta_invite.dart';
import '../widgets/home_on_back.dart';

/// Friendly, visual walkthrough for joining the Google Play closed test.
///
/// Mirrors the "become a tester" notice from the project README, but as an
/// interactive page: a branded hero, the three reasons it is worth doing, and
/// numbered steps where each one links straight to the page the user needs.
/// Reached from the home-screen invite strip and from the About page.
class JoinBetaPage extends StatelessWidget {
  const JoinBetaPage({super.key});

  Future<void> _open(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    try {
      final bool ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        _snack(context, 'Could not open the link. Copy: $url');
      }
    } on Object {
      if (context.mounted) {
        _snack(context, 'Could not open the link. Copy: $url');
      }
    }
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copyOptInLink(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: kBetaOptInUrl));
    if (context.mounted) {
      _snack(context, 'Opt-in link copied to clipboard');
    }
  }

  Future<void> _shareInvite() async {
    await SharePlus.instance.share(
      ShareParams(
        text: 'Help bring Custom RR to the Google Play Store, become a free '
            'tester (same app, and you get new builds about 5 days '
            'before everyone else): $kBetaOptInUrl',
        subject: 'Test Custom RR on Google Play',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return HomeOnBack(
      child: Scaffold(
        body: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar.large(
              pinned: true,
              expandedHeight: 220,
              title: const Text('Join the Play beta'),
              flexibleSpace: FlexibleSpaceBar(
                background: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        scheme.primary,
                        Color.alphaBlend(
                          Colors.black.withValues(alpha: 0.28),
                          scheme.primary,
                        ),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 56),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(
                            Icons.rocket_launch,
                            size: 44,
                            color: scheme.onPrimary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Get early builds and help\nCustom RR reach everyone',
                            style: text.titleLarge?.copyWith(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          'Custom RR is in closed testing on Google Play, and '
                          'Google needs a group of testers before it can go '
                          'live to everyone. You can help it launch in a few '
                          'quick steps, and as a tester you get new features '
                          'first, about 5 days before the other channels '
                          '(important fixes still go to everyone at once).',
                          style: text.bodyLarge,
                        ),
                        const SizedBox(height: 20),
                        const _Benefits(),
                        const SizedBox(height: 28),
                        Text('How to join', style: text.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          'Use the same Google account for every step, the one '
                          'you use on your phone, or Play will not recognise you '
                          'as a tester.',
                          style: text.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _StepCard(
                          number: 1,
                          icon: Icons.account_circle_outlined,
                          title: 'Sign in to Google',
                          body: 'On this device, make sure you are signed in '
                              'with the Google account you use on your phone.',
                        ),
                        _StepCard(
                          number: 2,
                          icon: Icons.group_add_outlined,
                          title: 'Join the testers group',
                          body: 'Open the testers group and tap Join group. '
                              'Just viewing it does not make you a tester, you '
                              'have to actually join.',
                          actionLabel: 'Open testers group',
                          onAction: () => _open(context, kBetaTestersGroupUrl),
                        ),
                        _StepCard(
                          number: 3,
                          icon: Icons.verified_user_outlined,
                          title: 'Opt in to the test',
                          body: 'Open the testing page and accept the invite to '
                              'become a tester for Custom RR.',
                          actionLabel: 'Become a tester',
                          onAction: () => _open(context, kBetaOptInUrl),
                        ),
                        _StepCard(
                          number: 4,
                          icon: Icons.shop_outlined,
                          title: 'Install from Google Play',
                          body: 'Once you are opted in, install Custom RR from '
                              'the Play Store. Access can take a little while to '
                              'propagate after you join.',
                          actionLabel: 'Open on Google Play',
                          onAction: () => _open(context, kPlayStoreUrl),
                          isLast: true,
                        ),
                        const SizedBox(height: 24),
                        const _KeepInstalledCard(),
                        const SizedBox(height: 16),
                        _InviteCard(
                          onCopy: () => _copyOptInLink(context),
                          onShare: _shareInvite,
                        ),
                        const SizedBox(height: 20),
                        Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          color: scheme.surfaceContainerHighest,
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
                                  color: scheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'The Play version is the same release as '
                                    'every other channel, with the same catalog '
                                    'and features. The only difference is that '
                                    'updates come through the Play Store.',
                                    style: text.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Prominent reminder that staying installed for ~2 weeks is what unlocks the
/// public launch, the most common reason closed tests stall.
class _KeepInstalledCard extends StatelessWidget {
  const _KeepInstalledCard();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: scheme.secondaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.event_available_outlined,
              color: scheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Please keep it installed for about two weeks',
                    style: text.titleMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Google only lets the app go public once enough testers '
                    'stay opted in for 14 days in a row. Uninstalling early '
                    'resets that countdown, so simply keeping Custom RR '
                    'installed is the single most helpful thing you can do.',
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A QR code (and copy / share buttons) for the opt-in page, so an existing
/// tester can recruit others: show the code for someone to scan, or share the
/// link directly.
class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.onCopy, required this.onShare});

  final VoidCallback onCopy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Invite others to test',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Every extra tester gets Custom RR to the public Play Store '
              'sooner. Let someone scan this code to open the opt-in page, or '
              'share the link.',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: kBetaOptInUrl,
                  version: QrVersions.auto,
                  size: 180,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.link, size: 18),
                  label: const Text('Copy link'),
                ),
                FilledButton.tonalIcon(
                  onPressed: onShare,
                  icon: const Icon(Icons.ios_share, size: 18),
                  label: const Text('Share invite'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The three reasons to join, as compact icon chips.
class _Benefits extends StatelessWidget {
  const _Benefits();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        _BenefitChip(icon: Icons.check_circle_outline, label: 'Same app & releases'),
        _BenefitChip(icon: Icons.bolt_outlined, label: 'New builds ~5 days first'),
        _BenefitChip(icon: Icons.favorite_outline, label: 'Helps it launch'),
      ],
    );
  }
}

class _BenefitChip extends StatelessWidget {
  const _BenefitChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18, color: scheme.onTertiaryContainer),
          const SizedBox(width: 8),
          Text(
            label,
            style: text.labelLarge?.copyWith(
              color: scheme.onTertiaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// One numbered step, with an optional action button that opens a link. A
/// vertical connector is drawn down to the next step unless [isLast].
class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.isLast = false,
  });

  final int number;
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: text.titleMedium?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: scheme.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(icon, size: 20, color: scheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(body, style: text.bodyMedium),
                  if (actionLabel != null && onAction != null) ...<Widget>[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.tonalIcon(
                        onPressed: onAction,
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: Text(actionLabel!),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
