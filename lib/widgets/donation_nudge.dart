import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'crypto_donate.dart';

/// Friendly, low-frequency in-app prompt asking the user to support
/// development. The card only appears after the app has been opened a
/// handful of times, and any tap on "Maybe later" or "Don't show again"
/// suppresses it (the former for a week, the latter forever).
///
/// Drop this widget into any scrollable page; it returns a zero-height
/// box when the nudge should not be visible, so it's safe to embed
/// unconditionally.
class DonationNudge extends StatefulWidget {
  const DonationNudge({super.key});

  /// Reflects whether the user has hidden the donation prompt forever.
  /// Updated by [setHidden] and by the in-card close button so the
  /// appearance sheet toggle stays in sync without polling prefs.
  static final ValueNotifier<bool> hiddenNotifier =
      ValueNotifier<bool>(false);

  /// Reads the persisted hidden flag into [hiddenNotifier]. Safe to call
  /// more than once; later calls are no-ops if the value is unchanged.
  static Future<void> loadHiddenState() async {
    try {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      final bool hidden = sp.getBool(_dismissedForeverKey) ?? false;
      if (hiddenNotifier.value != hidden) {
        hiddenNotifier.value = hidden;
      }
    } on Object {
      // Best effort.
    }
  }

  /// Updates the hidden flag from the appearance sheet toggle. Setting
  /// it back to false also clears any active 7-day snooze so the user
  /// sees the card on the next eligible launch.
  static Future<void> setHidden(bool hidden) async {
    hiddenNotifier.value = hidden;
    try {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      await sp.setBool(_dismissedForeverKey, hidden);
      if (!hidden) {
        await sp.remove(_snoozeUntilMsKey);
      }
    } on Object {
      // Best effort.
    }
  }

  /// Bumped once per cold start from `main.dart`.
  static Future<void> registerLaunch() async {
    try {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      final int n = (sp.getInt(_launchCountKey) ?? 0) + 1;
      await sp.setInt(_launchCountKey, n);
    } on Object {
      // Best effort; the nudge simply won't appear if prefs is broken.
    }
  }

  /// QA helper: wipes the launch counter, snooze timestamp, dismissed
  /// flag and donated flag so the nudge can re-appear on the next page
  /// build. Exposed via a long-press on the version label on the About
  /// page; not part of the user-facing UI.
  static Future<void> debugReset() async {
    try {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      await sp.remove(_launchCountKey);
      await sp.remove(_snoozeUntilMsKey);
      await sp.remove(_dismissedForeverKey);
      await sp.remove(_donatedKey);
      // Pretend the user has already opened the app enough times so the
      // tester doesn't have to cold-start 5 times to verify the card.
      await sp.setInt(_launchCountKey, _minLaunches);
    } on Object {
      // Best effort.
    }
    // Force a re-decide on any mounted cards even if the hidden flag
    // didn't actually change value.
    if (hiddenNotifier.value) {
      hiddenNotifier.value = false;
    } else {
      hiddenNotifier
        ..value = true
        ..value = false;
    }
  }

  @override
  State<DonationNudge> createState() => _DonationNudgeState();
}

const String _launchCountKey = 'donation_nudge_launches_v1';
const String _dismissedForeverKey = 'donation_nudge_dismissed_v1';
const String _snoozeUntilMsKey = 'donation_nudge_snooze_until_ms_v1';
const String _donatedKey = 'donation_nudge_donated_v1';

/// Number of cold starts before the nudge is allowed to appear.
const int _minLaunches = 5;

/// How long "Maybe later" hides the card before it can return.
const Duration _snoozeDuration = Duration(days: 7);

/// Where the "Support" button sends the user.
const String _supportUrl = 'https://www.buymeacoffee.com/monsiuYT';

class _DonationNudgeState extends State<DonationNudge>
    with SingleTickerProviderStateMixin {
  bool _ready = false;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    DonationNudge.hiddenNotifier.addListener(_onHiddenChanged);
    unawaited(_decideVisibility());
  }

  @override
  void dispose() {
    DonationNudge.hiddenNotifier.removeListener(_onHiddenChanged);
    super.dispose();
  }

  void _onHiddenChanged() {
    if (!mounted) return;
    // If the user re-enables the prompt from the appearance sheet,
    // re-check visibility (launch count + snooze) so it can come back
    // immediately instead of waiting for the next page load.
    if (DonationNudge.hiddenNotifier.value) {
      setState(() => _visible = false);
    } else {
      unawaited(_decideVisibility());
    }
  }

  Future<void> _decideVisibility() async {
    bool show = false;
    try {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      final bool dismissed = sp.getBool(_dismissedForeverKey) ?? false;
      final bool donated = sp.getBool(_donatedKey) ?? false;
      final int launches = sp.getInt(_launchCountKey) ?? 0;
      final int snoozeUntilMs = sp.getInt(_snoozeUntilMsKey) ?? 0;
      final int nowMs = DateTime.now().millisecondsSinceEpoch;
      show = !dismissed &&
          !donated &&
          launches >= _minLaunches &&
          nowMs >= snoozeUntilMs;
      // Keep the global notifier in sync in case prefs was changed by
      // another widget (e.g. the appearance sheet) while this card was
      // off-screen.
      if (DonationNudge.hiddenNotifier.value != dismissed) {
        DonationNudge.hiddenNotifier.value = dismissed;
      }
    } on Object {
      show = false;
    }
    if (!mounted) return;
    setState(() {
      _ready = true;
      _visible = show;
    });
  }

  Future<void> _snooze() async {
    setState(() => _visible = false);
    try {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      await sp.setInt(
        _snoozeUntilMsKey,
        DateTime.now().add(_snoozeDuration).millisecondsSinceEpoch,
      );
    } on Object {
      // Best effort.
    }
  }

  Future<void> _dismissForever() async {
    setState(() => _visible = false);
    DonationNudge.hiddenNotifier.value = true;
    try {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      await sp.setBool(_dismissedForeverKey, true);
    } on Object {
      // Best effort.
    }
  }

  Future<void> _support() async {
    await _showSupportChooser();
  }

  Future<void> _showSupportChooser() async {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (BuildContext ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Support Custom RR',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.favorite_rounded, color: scheme.primary),
              title: const Text('Become a supporter'),
              subtitle: const Text(
                'Silver or Gold tier: early builds & roadmap votes',
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                unawaited(_openBuyMeACoffee());
              },
            ),
            ListTile(
              leading: Icon(Icons.currency_bitcoin, color: scheme.primary),
              title: const Text('Donate with crypto'),
              subtitle: const Text('Copy a wallet address'),
              onTap: () {
                Navigator.of(ctx).pop();
                unawaited(_openCrypto());
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _openCrypto() async {
    // Treat opening the crypto sheet as the user supporting us; stop nagging.
    try {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      await sp.setBool(_donatedKey, true);
    } on Object {
      // Best effort.
    }
    if (!mounted) return;
    setState(() => _visible = false);
    await showCryptoDonateSheet(context);
  }

  Future<void> _openBuyMeACoffee() async {
    // Treat tapping Support as "they've helped", so we stop nagging.
    try {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      await sp.setBool(_donatedKey, true);
    } on Object {
      // Best effort.
    }
    if (mounted) setState(() => _visible = false);
    final Uri uri = Uri.parse(_supportUrl);
    bool opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open support page: $e')),
      );
      return;
    }
    if (!mounted || !opened) return;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: scheme.inverseSurface,
          content: Row(
            children: <Widget>[
              Icon(
                Icons.favorite_rounded,
                color: scheme.onInverseSurface,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Thank you, it means a lot!',
                  style: TextStyle(color: scheme.onInverseSurface),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || !_visible) {
      return const SizedBox.shrink();
    }
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: scheme.secondaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.favorite_rounded,
                      color: scheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Enjoying Custom RR?',
                            style: text.titleMedium?.copyWith(
                              color: scheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'This app is free and ad-free. Silver and '
                            'Gold supporters get new builds a few days '
                            'early and a vote in the monthly roadmap.',
                            style: text.bodyMedium?.copyWith(
                              color: scheme.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: "Don't show again",
                      icon: Icon(
                        Icons.close,
                        color: scheme.onSecondaryContainer,
                      ),
                      onPressed: _dismissForever,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TextButton(
                      onPressed: _snooze,
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.onSecondaryContainer,
                      ),
                      child: const Text('Maybe later'),
                    ),
                    const SizedBox(width: 4),
                    FilledButton.icon(
                      onPressed: _support,
                      icon: const Icon(Icons.favorite_rounded, size: 18),
                      label: const Text('Become a supporter'),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
