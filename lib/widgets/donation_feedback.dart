import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const String kSupportUrl = 'https://www.buymeacoffee.com/monsiutech';

/// GitHub Sponsors profile for the developer.
const String kSponsorsUrl = 'https://github.com/sponsors/monsiu';

/// Opens the Buy Me a Coffee support URL and shows a thank-you snackbar when
/// the external browser/app launch succeeds.
Future<void> openSupportWithFeedback(BuildContext context) async {
  await _openWithThanks(context, Uri.parse(kSupportUrl));
}

/// Opens the GitHub Sponsors profile and shows a thank-you snackbar when the
/// external browser/app launch succeeds.
Future<void> openSponsorsWithFeedback(BuildContext context) async {
  await _openWithThanks(context, Uri.parse(kSponsorsUrl));
}

Future<void> _openWithThanks(BuildContext context, Uri uri) async {
  bool opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Object catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open support page: $e')),
    );
    return;
  }
  if (!context.mounted || !opened) return;
  showDonationThanksSnackBar(context);
}

/// Reusable thank-you snackbar shown after a successful donation action.
void showDonationThanksSnackBar(BuildContext context) {
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