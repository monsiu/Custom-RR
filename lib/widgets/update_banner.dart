import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/update_checker.dart';
import '../data/update_notifier.dart';

/// Non-blocking strip shown above page content when a newer release is
/// available on GitHub. Dismissable per-version: clearing it only hides
/// the current release; a strictly newer release will surface a new
/// banner on the next background check.
class UpdateBanner extends StatelessWidget {
  const UpdateBanner({super.key, required this.child});

  final Widget child;

  Future<void> _open(BuildContext context, String url) async {
    if (url.isEmpty) return;
    final Uri uri = Uri.tryParse(url) ?? Uri();
    final bool ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UpdateCheckResult?>(
      valueListenable: UpdateNotifier.instance.available,
      builder: (BuildContext context, UpdateCheckResult? result, Widget? _) {
        return Column(
          children: <Widget>[
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (Widget c, Animation<double> a) =>
                  SizeTransition(
                sizeFactor: a,
                alignment: Alignment.topCenter,
                child: FadeTransition(opacity: a, child: c),
              ),
              child: result == null
                  ? const SizedBox.shrink()
                  : _Banner(
                      key: ValueKey<String>(result.latestVersion),
                      result: result,
                      onOpen: () => _open(context, result.releaseUrl),
                      onDismiss: () =>
                          UpdateNotifier.instance.dismissCurrent(),
                    ),
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    super.key,
    required this.result,
    required this.onOpen,
    required this.onDismiss,
  });

  final UpdateCheckResult result;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Material(
      color: scheme.primaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.system_update_alt,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Custom RR v${result.latestVersion} is available '
                  '(you are on v${result.currentVersion}).',
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onOpen,
                style: TextButton.styleFrom(
                  foregroundColor: scheme.onPrimaryContainer,
                ),
                child: const Text('View'),
              ),
              IconButton(
                tooltip: 'Dismiss',
                icon: const Icon(Icons.close),
                color: scheme.onPrimaryContainer,
                onPressed: onDismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
