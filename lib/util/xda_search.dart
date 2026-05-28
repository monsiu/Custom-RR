import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/catalog_card.dart' show kXdaQueryPlaceholder;

/// SharedPreferences key for suppressing the mobile XDA search warning.
const String _kSuppressXdaWarningKey = 'xda.search.suppressMobileWarning';

bool _isMobile() {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}

/// Opens an XDA search [uri] in the user's external browser.
///
/// On Android / iOS the XDA Forums search bar visually truncates the
/// query, hiding the trailing "input your model here" placeholder we
/// append. To stop mobile users from running a search that's missing
/// their device model, this shows a one-time warning modal explaining
/// what to do before opening the page. Desktop and web platforms
/// (where the placeholder is visible in the search bar) normally launch
/// the URL directly without any prompt, unless [alwaysWarn] is set;
/// defunct-ROM cards use that to remind every user (regardless of
/// platform) to replace the placeholder with their actual device model.
Future<void> launchXdaSearch(
  BuildContext context,
  Uri uri, {
  bool alwaysWarn = false,
}) async {
  if (!alwaysWarn && !_isMobile()) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return;
  }

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_kSuppressXdaWarningKey) ?? false) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return;
  }

  if (!context.mounted) return;

  final bool? proceed = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) => const _XdaSearchWarningDialog(),
  );

  if (proceed != true) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class _XdaSearchWarningDialog extends StatefulWidget {
  const _XdaSearchWarningDialog();

  @override
  State<_XdaSearchWarningDialog> createState() =>
      _XdaSearchWarningDialogState();
}

class _XdaSearchWarningDialogState extends State<_XdaSearchWarningDialog> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return AlertDialog(
      icon: Icon(Icons.open_in_new, color: scheme.primary),
      title: const Text('Opening XDA Forums search'),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'This will leave the app and open a new page in your browser.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'On phones, XDA\'s search bar hides part of the query, so '
            'you won\'t see the "$kXdaQueryPlaceholder" placeholder we '
            'add at the end. Tap the search bar and replace that '
            'placeholder with your phone\'s model (for example '
            '"Pixel 7" or "OnePlus 12"), then run the search again to '
            'get results that actually match your device.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _dontShowAgain,
            onChanged: (bool? v) =>
                setState(() => _dontShowAgain = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text("Don't show this again"),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            if (_dontShowAgain) {
              final SharedPreferences prefs =
                  await SharedPreferences.getInstance();
              await prefs.setBool(_kSuppressXdaWarningKey, true);
            }
            if (!context.mounted) return;
            Navigator.of(context).pop(true);
          },
          child: const Text('Open XDA'),
        ),
      ],
    );
  }
}
