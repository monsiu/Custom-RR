import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../routes.dart';

/// The Transsion family of budget brands (Infinix, itel, TECNO) almost never
/// gets a dedicated custom ROM. For these, the HOVATEK forum is the go-to
/// community source for stock firmware and bootloader-unlock help, and a
/// Treble GSI is usually the only realistic way to run a custom Android build.
const Set<String> kTranssionBrands = <String>{'Infinix', 'Itel', 'Tecno'};

/// Whether [brand] (a catalog vendor name) is one of the Transsion brands the
/// [TranssionHintBanner] applies to.
bool isTranssionBrand(String brand) => kTranssionBrands.contains(brand);

/// Info card shown on Infinix / itel / TECNO brand and device pages. Points
/// users at the HOVATEK forum for firmware and unlock help, and at the
/// Treble & GSI tab for actually running a custom build.
class TranssionHintBanner extends StatelessWidget {
  const TranssionHintBanner({
    super.key,
    required this.brand,
    this.padding = EdgeInsets.zero,
  });

  /// The catalog vendor name, e.g. "Infinix", "Itel", "Tecno". Used in the
  /// headline so the note names the brand the user is looking at.
  final String brand;

  final EdgeInsetsGeometry padding;

  static const String _hovatek = 'https://www.hovatek.com/forum/';
  static const String _twrpBuilder = 'https://www.hovatek.com/twrpbuilder/';
  static const String _firmwareMap =
      'https://www.hovatek.com/forum/thread-9678.html';
  static const String _flashTools =
      'https://www.hovatek.com/forum/thread-30280.html';

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: padding,
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: scheme.secondaryContainer.withValues(alpha: 0.55),
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
                      color: scheme.secondary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.memory_rounded,
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Custom ROMs are rare on $brand',
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Infinix, Itel and Tecno phones almost never get a '
                          'dedicated custom ROM. For stock firmware, flashing '
                          'tools and bootloader-unlock help, the HOVATEK forum '
                          'is the best community resource, and its online TWRP '
                          'builder can generate a custom recovery for many of '
                          'these MediaTek devices. To run a custom Android '
                          'build, a Treble GSI is almost always the way to go.',
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSecondaryContainer,
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
                    onPressed: () => _open(context, _hovatek),
                    icon: const Icon(Icons.forum_outlined, size: 18),
                    label: const Text('HOVATEK forum'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _open(context, _firmwareMap),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Firmware map'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _open(context, _flashTools),
                    icon: const Icon(Icons.handyman_rounded, size: 18),
                    label: const Text('Flash tools'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _open(context, _twrpBuilder),
                    icon: const Icon(Icons.build_rounded, size: 18),
                    label: const Text('TWRP builder'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.treble),
                    icon: const Icon(Icons.layers_rounded, size: 18),
                    label: const Text('Open Treble & GSI'),
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
