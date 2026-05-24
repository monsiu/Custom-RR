import 'package:flutter/material.dart';

import '../data/freshness_repository.dart';

/// Watches [FreshnessRepository.fetchStatus]; the first time the background
/// fetch fails this session it pops a one-shot dialog asking the user to
/// reconnect to Wi-Fi, with a refresh button that retries the fetch.
///
/// The dialog is shown at most once per app session even if the user
/// dismisses it; we don't want to be naggy. The user can still manually
/// retry from the dialog while it's open.
///
/// Wrap your page body (or the whole app shell body) in this widget. It
/// renders [child] verbatim. The dialog is shown via [showDialog] on top.
class OfflineNotice extends StatefulWidget {
  const OfflineNotice({super.key, required this.child});

  final Widget child;

  @override
  State<OfflineNotice> createState() => _OfflineNoticeState();
}

class _OfflineNoticeState extends State<OfflineNotice> {
  /// Tracks whether we've already shown the dialog this session, so a
  /// subsequent failed retry doesn't pop another dialog on top.
  static bool _shownThisSession = false;

  @override
  void initState() {
    super.initState();
    FreshnessRepository.instance.addListener(_onFreshnessChanged);
    // The initial fetch may have already failed before this widget mounted
    // (the app shell is built after main()'s `await load()` returns and the
    // background fetch fires immediately). Check once on mount.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  @override
  void dispose() {
    FreshnessRepository.instance.removeListener(_onFreshnessChanged);
    super.dispose();
  }

  void _onFreshnessChanged() {
    if (!mounted) return;
    _maybeShow();
  }

  void _maybeShow() {
    if (_shownThisSession) return;
    if (FreshnessRepository.instance.fetchStatus !=
        FreshnessFetchStatus.failed) {
      return;
    }
    _shownThisSession = true;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => const _OfflineDialog(),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _OfflineDialog extends StatefulWidget {
  const _OfflineDialog();

  @override
  State<_OfflineDialog> createState() => _OfflineDialogState();
}

class _OfflineDialogState extends State<_OfflineDialog> {
  bool _retrying = false;

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    await FreshnessRepository.instance.refresh();
    if (!mounted) return;
    final FreshnessFetchStatus status =
        FreshnessRepository.instance.fetchStatus;
    if (status == FreshnessFetchStatus.ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Freshness data updated.')),
      );
      return;
    }
    setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: Icon(Icons.wifi_off, size: 40, color: cs.error),
      title: const Text("You're offline"),
      content: const Text(
        'Custom RR (by Monsiu) could not reach the freshness feed on '
        'GitHub (github.com/monsiu/Custom-RR). The ROM and recovery dates '
        'shown may be out of date.\n\n'
        'Please reconnect to Wi-Fi or mobile data, then tap Refresh.',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _retrying ? null : () => Navigator.of(context).pop(),
          child: const Text('Dismiss'),
        ),
        FilledButton.icon(
          onPressed: _retrying ? null : _retry,
          icon: _retrying
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          label: Text(_retrying ? 'Refreshing…' : 'Refresh'),
        ),
      ],
    );
  }
}
