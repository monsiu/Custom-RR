import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows a friendly "Buy Me a Coffee" support dialog.
Future<void> showSupportDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Center(child: Text('Thanks so much!')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset('images/bmc.png', height: 120),
            ),
            const SizedBox(height: 16),
            const Text(
              'If Custom RR has helped you, consider buying us a coffee. '
              'Your support helps keep this app free and updated!',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.coffee),
            label: const Text('Buy us a coffee'),
            onPressed: () async {
              Navigator.of(context).pop();
              final Uri uri =
                  Uri.parse('https://www.buymeacoffee.com/monsiuYT');
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
          ),
        ],
      );
    },
  );
}
