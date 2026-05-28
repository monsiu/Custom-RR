import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../routes.dart';

/// Reusable "don't see your device?" hint shown beneath catalog lists
/// (Devices, ROMs, Recoveries) and on the brand detail page. Points
/// users at the Treble & GSI tab as a universal fallback and links out
/// to the phhusson GSI list and the XDA Project Treble forum.
class TrebleHintBanner extends StatelessWidget {
  const TrebleHintBanner({
    super.key,
    this.kind = 'device',
    this.padding = const EdgeInsets.fromLTRB(16, 24, 16, 16),
  });

  /// Short noun describing what the user was looking for, used to
  /// tailor the headline. Examples: "device", "ROM", "recovery".
  final String kind;

  final EdgeInsetsGeometry padding;

  static const String _phhussonList =
      'https://github.com/phhusson/treble_experimentations/wiki/Generic-System-Image-%28GSI%29-list';
  static const String _xdaForum = 'https://xdaforums.com/c/project-treble.7259/';

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final String headline = switch (kind) {
      'ROM' => "Don't see a ROM for your phone?",
      _ => "Don't see your device officially supported?",
    };
    return Padding(
      padding: padding,
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: scheme.tertiaryContainer.withValues(alpha: 0.55),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: scheme.tertiary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.layers_rounded,
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          headline,
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.onTertiaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'If it shipped with Android 9 or later, it is '
                          'almost certainly Project Treble compatible, '
                          'which means a Generic System Image (GSI) can '
                          'boot on it as a "universal ROM". The Treble & '
                          'GSI tab walks through the whole flow.',
                          style: text.bodySmall?.copyWith(
                            color: scheme.onTertiaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton.tonalIcon(
                    onPressed: () => context.push(AppRoutes.treble),
                    icon: const Icon(Icons.layers_rounded, size: 18),
                    label: const Text('Open Treble & GSI'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _open(context, _phhussonList),
                    icon: const Icon(Icons.list_alt_rounded, size: 18),
                    label: const Text('phhusson GSI list'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _open(context, _xdaForum),
                    icon: const Icon(Icons.forum_outlined, size: 18),
                    label: const Text('XDA Project Treble'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    final bool ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }
}
