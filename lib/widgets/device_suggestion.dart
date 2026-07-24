import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/catalog_repository.dart';
import '../models.dart';
import '../routes.dart';
import '../theme.dart';
import '../util/device_detector.dart';
import '../util/request_project.dart';

/// On-device suggestion shown at the top of the Home and Find My Phone pages.
///
/// On Android it detects the phone's codename and, when the catalog lists it,
/// offers a one-tap jump to that device's page. When the phone is not in the
/// catalog it nudges toward Treble/GSI and the device-request flow instead.
/// Renders nothing on iOS, desktop, web, or while detection is in flight, so
/// callers can drop it in unconditionally.
class DeviceSuggestion extends StatefulWidget {
  const DeviceSuggestion({super.key});

  @override
  State<DeviceSuggestion> createState() => _DeviceSuggestionState();
}

class _DeviceSuggestionState extends State<DeviceSuggestion> {
  DetectedDevice? _device;
  DeviceRef? _match;
  DeviceEntry? _brandEntry;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _detect();
  }

  Future<void> _detect() async {
    if (!DeviceDetector.isSupported) return;
    final DetectedDevice device = await DeviceDetector.instance.detect();
    if (!mounted || !device.hasCodename) return;
    final CatalogRepository repo = CatalogRepository.instance;
    final DeviceRef? ref = repo.deviceRefByCodenameOnly(device.codename);
    DeviceEntry? brandEntry;
    if (ref != null) {
      for (final DeviceEntry d in repo.devices) {
        if (d.name == ref.brand) {
          brandEntry = d;
          break;
        }
      }
    }
    setState(() {
      _device = device;
      _match = ref;
      _brandEntry = brandEntry;
    });
  }

  void _openDevicePage() {
    final DeviceRef? ref = _match;
    final DeviceEntry? brand = _brandEntry;
    if (ref == null || brand == null) return;
    context.push(AppRoutes.deviceModelDetail(brand.slug, ref.codename));
  }

  @override
  Widget build(BuildContext context) {
    final DetectedDevice? device = _device;
    if (_dismissed || device == null || !device.hasCodename) {
      return const SizedBox.shrink();
    }
    final Widget card = _match != null && _brandEntry != null
        ? _MatchedCard(
            device: device,
            match: _match!,
            onView: _openDevicePage,
            onDismiss: () => setState(() => _dismissed = true),
          )
        : _UnmatchedCard(
            device: device,
            onDismiss: () => setState(() => _dismissed = true),
          );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: card,
    );
  }
}

/// Shown when the detected codename is in the catalog: a brand-tinted card
/// inviting the user straight to their device page.
class _MatchedCard extends StatelessWidget {
  const _MatchedCard({
    required this.device,
    required this.match,
    required this.onView,
    required this.onDismiss,
  });

  final DetectedDevice device;
  final DeviceRef match;
  final VoidCallback onView;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final BrandColors brand = context.brand;
    final TextTheme text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: brand.seed,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onView,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: brand.onSeed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.smartphone_rounded, color: brand.onSeed),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Your device',
                        style: text.labelSmall?.copyWith(
                          color: brand.onSeed.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${match.brand} ${match.model}',
                        style: text.titleMedium?.copyWith(
                          color: brand.onSeed,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Codename ${match.codename} - tap to see ROMs '
                        '& recoveries',
                        style: text.bodySmall?.copyWith(
                          color: brand.onSeed.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Dismiss',
                  icon: Icon(
                    Icons.close_rounded,
                    color: brand.onSeed.withValues(alpha: 0.8),
                  ),
                  onPressed: onDismiss,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown when the detected phone is not in the catalog: a softer card that
/// points to Treble/GSI and the device-request flow.
class _UnmatchedCard extends StatelessWidget {
  const _UnmatchedCard({required this.device, required this.onDismiss});

  final DetectedDevice device;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.smartphone_outlined, color: scheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Your phone (${device.codename}) isn't in the catalog yet",
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Dismiss',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onDismiss,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 36, right: 8),
              child: Text(
                'It may still boot a Treble GSI. You can also ask us to add it.',
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Wrap(
                spacing: 8,
                children: <Widget>[
                  TextButton.icon(
                    icon: const Icon(Icons.layers_outlined, size: 18),
                    label: const Text('Treble & GSI'),
                    onPressed: () => context.push(AppRoutes.treble),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add_to_home_screen, size: 18),
                    label: const Text('Request it'),
                    onPressed: () => openDeviceRequest(
                      query: '${device.manufacturer} ${device.model} '
                          '(${device.codename})',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
