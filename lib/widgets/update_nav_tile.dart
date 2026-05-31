import 'package:flutter/material.dart';

import '../data/update_notifier.dart';
import '../util/build_flags.dart';

/// Drawer / side-panel tile that runs a forced update check and reports
/// the outcome inline. Update-available results route through the shared
/// [UpdateNotifier] banner; the snackbar covers the cases the banner
/// intentionally hides ("you are up to date" and "lookup failed").
class UpdateNavTile extends StatefulWidget {
  const UpdateNavTile({super.key, this.onNavigate});

  /// Called before the check fires so the modal drawer can dismiss
  /// itself before any snackbar is shown.
  final VoidCallback? onNavigate;

  @override
  State<UpdateNavTile> createState() => _UpdateNavTileState();
}

class _UpdateNavTileState extends State<UpdateNavTile> {
  bool _checking = false;

  Future<void> _run() async {
    if (_checking) return;
    // Capture the messenger before any async gap so we can still reach
    // it after the drawer pops and the tile's BuildContext goes away.
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    widget.onNavigate?.call();
    setState(() => _checking = true);
    final UpdateCheckOutcome outcome =
        await UpdateNotifier.instance.checkNow();
    if (mounted) setState(() => _checking = false);

    switch (outcome.status) {
      case UpdateCheckStatus.updateAvailable:
        // Banner handles surfacing; no snackbar to avoid double-notifying.
        break;
      case UpdateCheckStatus.upToDate:
        final String v = outcome.result?.currentVersion ?? '';
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              v.isEmpty
                  ? "You're on the latest version."
                  : "You're on the latest version (v$v).",
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case UpdateCheckStatus.noReleases:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('No published releases yet.'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
      case UpdateCheckStatus.failed:
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Could not check for updates: ${outcome.error ?? 'network error'}',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // F-Droid and Play builds omit the in-app update check entirely.
    if (!kSelfUpdateEnabled) return const SizedBox.shrink();
    return ListTile(
      leading: const Icon(Icons.system_update_alt),
      title: const Text('Check for updates'),
      trailing: _checking
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: _checking ? null : _run,
    );
  }
}
