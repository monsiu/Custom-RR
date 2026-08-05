import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../util/build_flags.dart';

/// The highlights shown in the once-per-update "What's new" sheet.
///
/// RELEASE MAINTENANCE: rewrite this list on every release cut so it describes
/// the version being shipped, sourced from CHANGELOG.md. Stale entries are
/// worse than none; keep it to the 3-4 items a user would actually notice, in
/// the same plain voice as the changelog.
///
/// These entries deliberately span [Unreleased] and 1.3.6: the sheet itself
/// ships after 1.3.6, so this is the first one anyone sees. Users already on
/// 1.3.6 will find the last two items familiar.
const List<String> kWhatsNewHighlights = <String>[
  'A short highlights sheet like this one after each update',
  'Device detection recognizes many more phones, including vendor-prefixed '
      'and regional codenames',
  'A better-timed rating ask that only appears once the app has helped you',
];

/// Tracks the last app version the user has seen a "What's new" sheet for, so
/// a concise highlights sheet can appear once after each update. The
/// direct-download (GitHub) channel already shows full release notes via its
/// update banner, so this sheet is gated to the store channels (Play, F-Droid)
/// to avoid two "what's new" surfaces.
class WhatsNewController {
  WhatsNewController._();

  static final WhatsNewController instance = WhatsNewController._();

  static const String _prefsKey = 'whats_new_last_version';

  String _currentVersion = '';
  bool _shouldShow = false;
  bool _loaded = false;

  bool get shouldShow => _shouldShow;

  String get currentVersion => _currentVersion;

  /// Pure decision core, split out for tests: show only when a previous
  /// version was recorded and it differs from the current one. A missing
  /// [lastSeen] means a fresh install, which stays quiet.
  static bool shouldShowFor({
    required String? lastSeen,
    required String current,
  }) {
    return lastSeen != null && lastSeen != current;
  }

  /// Loads the current build version and compares it to the last-seen version.
  /// On a fresh install (no stored version) it records the current version and
  /// stays quiet; only a genuine version change arms the sheet.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      _currentVersion = info.version;
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? lastSeen = prefs.getString(_prefsKey);
      if (lastSeen == null) {
        await prefs.setString(_prefsKey, _currentVersion);
        _shouldShow = false;
      } else {
        _shouldShow = shouldShowFor(
          lastSeen: lastSeen,
          current: _currentVersion,
        );
      }
    } on Object {
      _shouldShow = false;
    }
  }

  Future<void> markShown() async {
    _shouldShow = false;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, _currentVersion);
    } on Object {
      // Best effort; worst case the sheet shows once more next launch.
    }
  }
}

/// Shows the once-per-update highlights sheet when armed. No-op on the
/// self-updating GitHub channel (which shows release notes instead) and when
/// there is nothing new to announce.
Future<void> maybeShowWhatsNew(BuildContext context) async {
  if (kSelfUpdateEnabled) return;
  await WhatsNewController.instance.load();
  if (!WhatsNewController.instance.shouldShow) return;
  await WhatsNewController.instance.markShown();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      final ColorScheme scheme = Theme.of(sheetContext).colorScheme;
      final TextTheme text = Theme.of(sheetContext).textTheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.auto_awesome, color: scheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "What's new",
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final String item in kWhatsNewHighlights)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        Icons.check_circle_outline,
                        size: 20,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(item, style: text.bodyMedium)),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
