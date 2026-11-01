import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../routes.dart';
import '../util/breakpoints.dart';
import '../widgets/app_shell.dart';

class ServicesPage extends StatelessWidget {
  const ServicesPage({
    super.key,
    this.manufacturer = '',
    this.model = '',
    this.codename = '',
  });

  final String manufacturer;
  final String model;
  final String codename;

  Uri get _romEnquiry {
    final String deviceName = <String>[
      manufacturer,
      model,
    ].where((String value) => value.trim().isNotEmpty).join(' ');
    final String body = <String>[
      'Device model: ${deviceName.isEmpty ? '(please add)' : deviceName}',
      'Device codename: ${codename.isEmpty ? '(please add if known)' : codename}',
      'ROM and Android version:',
      'Source links:',
      'Goal or build issue:',
    ].join('\n');
    return Uri.parse(
      'mailto:contactmonsiu@gmail.com'
      '?subject=Custom%20ROM%20Project'
      '&body=${Uri.encodeComponent(body)}',
    );
  }

  static final Uri _appWebServices = Uri.parse(
    'https://monsiu.github.io/services/',
  );

  Future<void> _open(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String deviceLabel = <String>[
      manufacturer,
      model,
    ].where((String value) => value.isNotEmpty).join(' ');

    return AppShell(
      title: 'Services',
      selectedRoute: AppRoutes.services,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: Breakpoints.readingMaxWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              Icon(Icons.android_rounded, size: 48, color: colors.primary),
              const SizedBox(height: 12),
              Text('Custom ROM builds', style: text.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Build support for eligible devices. I’ll first check the '
                'device, ROM target, and available source before confirming '
                'what is feasible, the scope, and a quote.',
                style: text.bodyLarge,
              ),
              if (model.isNotEmpty || codename.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                Card(
                  color: colors.secondaryContainer,
                  child: ListTile(
                    leading: Icon(
                      Icons.phone_android_outlined,
                      color: colors.onSecondaryContainer,
                    ),
                    title: Text(
                      deviceLabel.isEmpty ? 'Detected device' : deviceLabel,
                      style: TextStyle(color: colors.onSecondaryContainer),
                    ),
                    subtitle: Text(
                      codename.isEmpty
                          ? 'Detected device'
                          : 'Codename: $codename',
                      style: TextStyle(color: colors.onSecondaryContainer),
                    ),
                    trailing: Icon(
                      Icons.check_circle_outline,
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                ),
                Text(
                  'This device information will be included in your email.',
                  style: text.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ] else ...<Widget>[
                const SizedBox(height: 16),
                Text(
                  'Include your device model and codename in the enquiry '
                  'when you know them.',
                  style: text.bodyMedium,
                ),
              ],
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('How it starts', style: text.titleLarge),
                      const SizedBox(height: 12),
                      const _Step(
                        number: '1',
                        text:
                            'Check the device, ROM target, and source availability.',
                      ),
                      const _Step(
                        number: '2',
                        text: 'Agree on a realistic build scope and timeline.',
                      ),
                      const _Step(
                        number: '3',
                        text: 'Get a quote before any work begins.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Include in your enquiry', style: text.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        'Device model and codename, the ROM and Android '
                        'version you want, links to any source trees, and '
                        'your goal or current build error.',
                        style: text.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Availability depends on the device sources and ROM target. '
                'The feasibility check comes before a commitment or quote.',
                style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _open(_romEnquiry),
                icon: const Icon(Icons.mail_outline),
                label: const Text('Ask about a ROM build'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _open(_appWebServices),
                icon: const Icon(Icons.web_outlined),
                label: const Text('Android apps & websites'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 12,
            child: Text(number, style: Theme.of(context).textTheme.labelSmall),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
