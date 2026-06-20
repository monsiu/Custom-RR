import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../routes.dart';
import '../util/build_flags.dart';

/// Google Play closed-testing opt-in links, shared by the home nudge, the
/// Join the beta page, and the About page entry so they never drift apart.
const String kBetaTestersGroupUrl =
    'https://groups.google.com/g/custom-rr-play-testers';
const String kBetaOptInUrl =
    'https://play.google.com/apps/testing/io.github.monsiu.custom_rr';
const String kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=io.github.monsiu.custom_rr';

/// SharedPreferences key for the "dismissed forever" flag.
const String _betaDismissedKey = 'beta_invite_dismissed_v1';

/// True only where joining the Google Play beta makes sense: an Android build
/// that is NOT already the Play build (a Play user is, by definition, already
/// on Play). Desktop, web, and the Play variant never see the invite.
bool get kBetaInviteApplicable =>
    !kIsWeb && !kPlayBuild && defaultTargetPlatform == TargetPlatform.android;

/// Dismissible home-screen strip inviting the user to join the Google Play
/// closed test. Styled like the update banner but in a distinct colour so the
/// two never read as the same thing. Returns a zero-height box when it should
/// not show (wrong platform, Play build, or dismissed), so it is safe to embed
/// unconditionally.
///
/// Dismissal is permanent (there is no snooze): the close button hides it for
/// good, and the same option remains reachable from the About page.
class BetaInviteNudge extends StatefulWidget {
  const BetaInviteNudge({super.key});

  /// Tracks the persisted "dismissed forever" flag so other surfaces (e.g. a
  /// future About toggle) can stay in sync without polling prefs.
  static final ValueNotifier<bool> dismissedNotifier =
      ValueNotifier<bool>(false);

  /// Reads the persisted dismissed flag into [dismissedNotifier]. Safe to call
  /// more than once.
  static Future<void> loadDismissedState() async {
    try {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      final bool dismissed = sp.getBool(_betaDismissedKey) ?? false;
      if (dismissedNotifier.value != dismissed) {
        dismissedNotifier.value = dismissed;
      }
    } on Object {
      // Best effort.
    }
  }

  /// Persists the dismissed flag. Pass `false` to bring the strip back (used if
  /// an About toggle ever offers to re-enable it).
  static Future<void> setDismissed(bool dismissed) async {
    dismissedNotifier.value = dismissed;
    try {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      await sp.setBool(_betaDismissedKey, dismissed);
    } on Object {
      // Best effort.
    }
  }

  @override
  State<BetaInviteNudge> createState() => _BetaInviteNudgeState();
}

class _BetaInviteNudgeState extends State<BetaInviteNudge> {
  bool _ready = false;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    BetaInviteNudge.dismissedNotifier.addListener(_onDismissedChanged);
    unawaited(_decideVisibility());
  }

  @override
  void dispose() {
    BetaInviteNudge.dismissedNotifier.removeListener(_onDismissedChanged);
    super.dispose();
  }

  void _onDismissedChanged() {
    if (!mounted) return;
    if (BetaInviteNudge.dismissedNotifier.value) {
      setState(() => _visible = false);
    } else {
      unawaited(_decideVisibility());
    }
  }

  Future<void> _decideVisibility() async {
    bool show = false;
    if (kBetaInviteApplicable) {
      try {
        final SharedPreferences sp = await SharedPreferences.getInstance();
        final bool dismissed = sp.getBool(_betaDismissedKey) ?? false;
        show = !dismissed;
        if (BetaInviteNudge.dismissedNotifier.value != dismissed) {
          BetaInviteNudge.dismissedNotifier.value = dismissed;
        }
      } on Object {
        show = false;
      }
    }
    if (!mounted) return;
    setState(() {
      _ready = true;
      _visible = show;
    });
  }

  Future<void> _dismissForever() async {
    setState(() => _visible = false);
    await BetaInviteNudge.setDismissed(true);
  }

  void _join() {
    context.push(AppRoutes.joinBeta);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || !_visible) return const SizedBox.shrink();
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
          // Distinct from the update banner (primaryContainer) and the
          // donation nudge (secondaryContainer) so they never blur together.
          color: scheme.tertiaryContainer,
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
                      Icons.rocket_launch_outlined,
                      color: scheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Help bring Custom RR to the Play Store',
                            style: text.titleMedium?.copyWith(
                              color: scheme.onTertiaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Join the Google Play beta. It is the exact same '
                            'app and releases, you just get them faster, and '
                            'every tester helps Custom RR reach the public '
                            'Play Store and more users.',
                            style: text.bodyMedium?.copyWith(
                              color: scheme.onTertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: "Don't show again",
                      icon: Icon(
                        Icons.close,
                        color: scheme.onTertiaryContainer,
                      ),
                      onPressed: _dismissForever,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: _join,
                      icon: const Icon(Icons.rocket_launch, size: 18),
                      label: const Text('Join the beta'),
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
