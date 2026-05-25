import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../routes.dart';

/// First-launch liability notice. Shows a single dialog the first time
/// the app starts, then never again. The dialog is acknowledged with one
/// tap (`OK, I understand`); tap-outside-to-dismiss is disabled so the
/// user has to actually hit the button, but it is not a multi-stage
/// gate, this app is an information catalog, not a flasher.
///
/// Bump [_prefsKey] if the wording ever changes materially and you want
/// everyone to see it once more.
class DisclaimerGate extends StatefulWidget {
  const DisclaimerGate({super.key, required this.child});

  final Widget child;

  static const String _prefsKey = 'disclaimer_acknowledged_v1';

  @override
  State<DisclaimerGate> createState() => _DisclaimerGateState();
}

class _DisclaimerGateState extends State<DisclaimerGate> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  Future<void> _maybeShow() async {
    if (_checked) return;
    _checked = true;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(DisclaimerGate._prefsKey) ?? false) {
      return;
    }
    // The gate lives in `MaterialApp.router`'s `builder`, ABOVE the
    // router's Navigator. Use the router's own root navigator key so
    // `showDialog` finds a Navigator to attach to.
    final BuildContext? navContext = rootNavigatorKey.currentContext;
    if (navContext == null || !mounted) return;
    await showDialog<void>(
      context: navContext,
      barrierDismissible: false,
      builder: (BuildContext ctx) => const _DisclaimerDialog(),
    );
    await prefs.setBool(DisclaimerGate._prefsKey, true);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _DisclaimerDialog extends StatelessWidget {
  const _DisclaimerDialog();

  static const List<_Link> _links = <_Link>[
    _Link(
      label: 'XDA Forums',
      url: 'https://xdaforums.com/',
      icon: Icons.forum_rounded,
    ),
    _Link(
      label: 'r/AndroidRoot',
      url: 'https://www.reddit.com/r/AndroidRoot/',
      icon: Icons.reddit_rounded,
    ),
  ];

  Future<void> _open(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    final bool ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return AlertDialog(
      icon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.warning_amber_rounded,
          color: scheme.onErrorContainer,
        ),
      ),
      title: const Text('Heads up before you start'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Custom RR is an information catalog. Anything you actually '
                'flash, unlock, root or modify happens on YOUR device, with '
                'YOUR hands, using third-party tools.',
                style: text.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'The developer of this app accepts no responsibility for '
                'bricked devices, lost data, tripped warranty, voided '
                'eFuses or anything else that may go wrong. Back up your '
                'data before you flash anything.',
                style: text.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'If something goes wrong, the right place to ask is your '
                'device community, not this app:',
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: <Widget>[
                  for (final _Link l in _links)
                    ActionChip(
                      avatar: Icon(l.icon, size: 16),
                      label: Text(l.label),
                      onPressed: () => _open(context, l.url),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK, I understand'),
        ),
      ],
    );
  }
}

class _Link {
  const _Link({required this.label, required this.url, required this.icon});

  final String label;
  final String url;
  final IconData icon;
}
