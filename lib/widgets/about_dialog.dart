import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Public GitHub repository for Custom RR.
const String kCustomRrRepoUrl = 'https://github.com/monsiu/Custom-RR';

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
    applicationLegalese: '© ${DateTime.now().year} MonsiuTech Solutions · by Monsiu',
    children: <Widget>[
      const SizedBox(height: 16),
      const Text(
        'Custom RR is a community-built, open-source guide to Android '
        'Custom ROMs and Recoveries. Browse projects, read about features, '
        'and grab official download links, all in one place.',
      ),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          icon: const Icon(Icons.code),
          label: const Text('View Custom RR on GitHub'),
          onPressed: () => launchUrl(
            Uri.parse(kCustomRrRepoUrl),
            mode: LaunchMode.externalApplication,
          ),
        ),
      ),
    ],
  );
}
