import 'package:flutter/material.dart';

import '../util/build_flags.dart';
import 'crypto_donate.dart';
import 'donation_feedback.dart';

/// Shows a friendly "Buy Me a Coffee" support dialog.
Future<void> showSupportDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogCtx) {
      final ColorScheme scheme = Theme.of(dialogCtx).colorScheme;
      return AlertDialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 24,
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        title: const Center(child: Text('Thanks so much!')),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite_rounded,
                    size: 32,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'If Custom RR has helped you, consider buying us a coffee. '
                'Your support helps keep this app free, open source on '
                'GitHub, and regularly updated!',
                textAlign: TextAlign.center,
                style: Theme.of(dialogCtx).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.coffee_rounded),
                  label: const Text('Buy us a coffee'),
                  onPressed: () async {
                    final NavigatorState rootNav = Navigator.of(
                      dialogCtx,
                      rootNavigator: true,
                    );
                    final BuildContext rootCtx = rootNav.context;
                    rootNav.pop();
                    await openSupportWithFeedback(rootCtx);
                  },
                ),
              ),
              if (kShowCryptoDonate) ...<Widget>[
                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.currency_bitcoin_rounded),
                    label: const Text('Donate with crypto'),
                    onPressed: () {
                      final NavigatorState rootNav = Navigator.of(
                        dialogCtx,
                        rootNavigator: true,
                      );
                      final BuildContext rootCtx = rootNav.context;
                      rootNav.pop();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        showCryptoDonateSheet(rootCtx);
                      });
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Later'),
          ),
        ],
      );
    },
  );
}
