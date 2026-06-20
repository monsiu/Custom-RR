import 'package:flutter/material.dart';
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
                          'quick steps, and you get the app early.',
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
                                    'updates come through the Play Store. The '
                                    'more testers who stay opted in, the sooner '
                                    'Custom RR reaches the public Play Store. '
                                    'Thank you!',
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
        _BenefitChip(icon: Icons.bolt_outlined, label: 'Faster updates'),
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
