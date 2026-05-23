import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Shows the standard about dialog (uses package_info_plus for version).
Future<void> showCustomAboutDialog(BuildContext context) async {
  final PackageInfo info = await PackageInfo.fromPlatform();
  if (!context.mounted) return;
  showAboutDialog(
    context: context,
    applicationName: 'Custom RR',
    applicationVersion: 'v${info.version}+${info.buildNumber}',
    applicationIcon: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset('images/launcher.png', width: 48, height: 48),
    ),
    applicationLegalese: '© ${DateTime.now().year} MonsiuTech Solutions',
    children: const <Widget>[
      SizedBox(height: 16),
      Text(
        'Custom RR is a community guide to Android Custom ROMs and '
        'Recoveries. Browse projects, read about features, and grab official '
        'download links, all in one place.',
      ),
    ],
  );
}
