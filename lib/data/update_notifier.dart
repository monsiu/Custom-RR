import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../util/build_flags.dart';
import 'update_checker.dart';

/// Passive background update notifier.
///
/// Polls GitHub Releases at most once every [_minInterval]; surfaces a
/// non-blocking banner via [available] when a newer version ships. Users
/// can dismiss a specific release with [dismissCurrent] which suppresses
/// the banner until an even newer release lands.
class UpdateNotifier {
  UpdateNotifier._();
  static final UpdateNotifier instance = UpdateNotifier._();

  static const Duration _minInterval = Duration(hours: 12);
  static const String _kLastCheckMs = 'updateNotifier.lastCheckMs';
  static const String _kDismissedVersion = 'updateNotifier.dismissedVersion';

  /// When non-null, holds the latest release that the UI should announce.
  /// Null means nothing to show (either no update, lookup failed, or the
  /// user dismissed this version).
  final ValueNotifier<UpdateCheckResult?> available =
      ValueNotifier<UpdateCheckResult?>(null);

  bool _started = false;

  /// Kicks off a throttled background check. Safe to call from main();
  /// returns immediately. Errors are swallowed since this is a passive
  /// nicety, not a critical-path operation.
  void start() {
    // F-Droid and Play builds never poll GitHub for updates; the store does it.
    if (!kSelfUpdateEnabled) return;
    if (_started) return;
    _started = true;
    // Defer by a short delay so we don't race with first-frame work like
    // catalog/freshness loads.
    Timer(const Duration(seconds: 3), () {
      unawaited(_checkIfDue());
    });
  }

  /// Bypass the throttle. Used after the user manually checks from the
  /// About page so the banner state stays in sync with the dialog result.
  Future<void> refresh() => _runCheck(force: true);

  /// Runs a forced check and reports the outcome so callers can show
  /// inline feedback (e.g. a snackbar) for the "already up to date" and
  /// "lookup failed" cases that the passive banner intentionally hides.
  Future<UpdateCheckOutcome> checkNow() async {
    try {
      final UpdateCheckResult result = await UpdateChecker.instance.check();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _kLastCheckMs,
        DateTime.now().millisecondsSinceEpoch,
      );
      if (result.latestVersion.isEmpty) {
        available.value = null;
        return UpdateCheckOutcome(
          status: UpdateCheckStatus.noReleases,
          result: result,
        );
      }
      if (!result.isUpdateAvailable) {
        available.value = null;
        return UpdateCheckOutcome(
          status: UpdateCheckStatus.upToDate,
          result: result,
        );
      }
      // Manual check overrides any prior dismissal so the user can see
      // the banner they explicitly asked for.
      await prefs.remove(_kDismissedVersion);
      available.value = result;
      return UpdateCheckOutcome(
        status: UpdateCheckStatus.updateAvailable,
        result: result,
      );
    } on Object catch (e) {
      return UpdateCheckOutcome(
        status: UpdateCheckStatus.failed,
        error: e.toString(),
      );
    }
  }

  Future<void> _checkIfDue() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final int last = prefs.getInt(_kLastCheckMs) ?? 0;
      final int now = DateTime.now().millisecondsSinceEpoch;
      if (now - last < _minInterval.inMilliseconds) return;
      await _runCheck(force: false);
    } on Object {
      // Silent: never let an update probe crash app launch.
    }
  }

  Future<void> _runCheck({required bool force}) async {
    try {
      final UpdateCheckResult result = await UpdateChecker.instance.check();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _kLastCheckMs,
        DateTime.now().millisecondsSinceEpoch,
      );
      if (!result.isUpdateAvailable) {
        available.value = null;
        return;
      }
      final String dismissed = prefs.getString(_kDismissedVersion) ?? '';
      if (!force && dismissed == result.latestVersion) {
        available.value = null;
        return;
      }
      available.value = result;
    } on Object {
      // Network / parse failures: leave the previous state intact.
    }
  }

  /// Hide the banner for the currently announced version. The notifier
  /// will surface a new banner only if a strictly newer release is
  /// published later.
  Future<void> dismissCurrent() async {
    final UpdateCheckResult? current = available.value;
    if (current == null) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDismissedVersion, current.latestVersion);
    available.value = null;
  }

  /// Debug-only: inject a fake "update available" result so the banner
  /// can be exercised without waiting for a real GitHub release. Also
  /// clears any prior dismissal so the banner is guaranteed to render.
  Future<void> debugSimulate() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDismissedVersion);
    available.value = const UpdateCheckResult(
      currentVersion: '0.0.0',
      latestVersion: '99.99.99',
      isUpdateAvailable: true,
      releaseUrl: 'https://github.com/monsiu/Custom-RR/releases',
      releaseName: 'Simulated release (debug)',
      releaseNotes: '',
      publishedAt: null,
    );
  }
}

/// Coarse status returned by [UpdateNotifier.checkNow] so UI can show
/// inline feedback (snackbars) for manual checks.
enum UpdateCheckStatus { updateAvailable, upToDate, noReleases, failed }

class UpdateCheckOutcome {
  const UpdateCheckOutcome({
    required this.status,
    this.result,
    this.error,
  });

  final UpdateCheckStatus status;
  final UpdateCheckResult? result;
  final String? error;
}
