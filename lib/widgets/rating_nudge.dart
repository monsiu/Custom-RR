import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../util/build_flags.dart';
import 'about_dialog.dart';

/// Play Store rating page opened directly in the Play app, with an https
/// fallback for when the Play app is not installed.
const String _kMarketUri = 'market://details?id=io.github.monsiu.custom_rr';

/// Whether the "rate the app" prompt applies to this build.
///
/// Only the Google Play variant sets [kPlayBuild], and that flag is only ever
/// defined by the Play release workflow, so this is effectively "the Google
/// Play Android build". The prompt deliberately opens the Play listing with
/// `url_launcher` rather than the native Play In-App Review API, because that
/// API pulls in Google's proprietary Play Core library and would be compiled
/// into the F-Droid build too, which F-Droid does not allow.
bool get kRatingApplicable => kPlayBuild;

/// Opens the Play Store listing so the user can leave a rating. Tries the Play
/// app first (market://) and falls back to the browser listing.
Future<void> openPlayRating() async {
  try {
    final Uri market = Uri.parse(_kMarketUri);
    if (await canLaunchUrl(market)) {
      await launchUrl(market, mode: LaunchMode.externalApplication);
      return;
    }
  } on Object {
    // Fall through to the https listing.
  }
  try {
    await launchUrl(
      Uri.parse(kPlayStoreUrl),
      mode: LaunchMode.externalApplication,
    );
  } on Object {
    // Best effort; nothing else to do if the platform cannot open a URL.
  }
}

/// Low-frequency in-app prompt asking a happy Google Play user to leave a
/// rating. Mirrors [DonationNudge]: it only appears after the app has been
/// opened several times, "Not now" snoozes it, and it never returns once the
/// user rates or dismisses it. Returns a zero-height box when it should not be
/// visible, so it is safe to embed unconditionally in a scrollable page.
class RatingNudge extends StatefulWidget {
  const RatingNudge({super.key});

  /// Bumped once per cold start from `main.dart` (only on the Play build).
  static Future<void> registerLaunch() async {
    if (!kRatingApplicable) return;
    try {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      final int n = (sp.getInt(_launchCountKey) ?? 0) + 1;
      await sp.setInt(_launchCountKey, n);
    } on Object {
      // Best effort; the nudge simply won't appear if prefs is broken.
    }
  }

  /// QA helper: pretends the app has been opened enough times and clears the
  /// snooze / dismissed / rated flags so the card can re-appear. Exposed via a
  /// debug-only button on the About page.
  static Future<void> debugReset() async {
    try {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      await sp.remove(_snoozeUntilMsKey);
      await sp.remove(_dismissedKey);
      await sp.remove(_ratedKey);
      await sp.setInt(_launchCountKey, _minLaunches);
    } on Object {
      // Best effort.
    }
  }

  @override
  State<RatingNudge> createState() => _RatingNudgeState();
}

const String _launchCountKey = 'rating_nudge_launches_v1';
const String _dismissedKey = 'rating_nudge_dismissed_v1';
const String _snoozeUntilMsKey = 'rating_nudge_snooze_until_ms_v1';
const String _ratedKey = 'rating_nudge_rated_v1';

/// Cold starts before the rating prompt may appear (a few opens in).
const int _minLaunches = 4;

/// How long "Not now" hides the card before it can return.
const Duration _snoozeDuration = Duration(days: 14);

class _RatingNudgeState extends State<RatingNudge> {
  bool _ready = false;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    unawaited(_decideVisibility());
  }

  Future<void> _decideVisibility() async {
    bool show = false;
    if (kRatingApplicable) {
      try {
        final SharedPreferences sp = await SharedPreferences.getInstance();
        final bool dismissed = sp.getBool(_dismissedKey) ?? false;
        final bool rated = sp.getBool(_ratedKey) ?? false;
        final int launches = sp.getInt(_launchCountKey) ?? 0;
        final int snoozeUntilMs = sp.getInt(_snoozeUntilMsKey) ?? 0;
        final int nowMs = DateTime.now().millisecondsSinceEpoch;
        show = !dismissed &&
            !rated &&
            launches >= _minLaunches &&
            nowMs >= snoozeUntilMs;
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

  Future<void> _rate() async {
    setState(() => _visible = false);
    // Once they have gone to rate, do not ask again.
    try {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      await sp.setBool(_ratedKey, true);
    } on Object {
      // Best effort.
    }
    await openPlayRating();
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
    try {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      await sp.setBool(_dismissedKey, true);
    } on Object {
      // Best effort.
    }
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
          color: scheme.surfaceContainerHighest,
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
                      Icons.star_rounded,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Rate Custom RR',
                            style: text.titleMedium?.copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'If it has been useful, a quick rating on Google '
                            'Play helps more people find it.',
                            style: text.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: "Don't show again",
                      icon: Icon(
                        Icons.close,
                        color: scheme.onSurfaceVariant,
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
                        foregroundColor: scheme.onSurfaceVariant,
                      ),
                      child: const Text('Not now'),
                    ),
                    const SizedBox(width: 4),
                    FilledButton.icon(
                      onPressed: _rate,
                      icon: const Icon(Icons.star_rounded, size: 18),
                      label: const Text('Rate'),
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
