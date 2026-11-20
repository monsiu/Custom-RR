import 'package:material_ui/material_ui.dart';

import '../util/bootloader_lock.dart';

/// Warns that a bootloader cannot normally be unlocked, so no ROM or recovery
/// can be flashed.
///
/// Two modes, because the model-number rule is only decisive when the exact
/// model is known (see [bootloaderLockForModel]):
///   * [exact] true  - we know the user's precise model (e.g. from on-device
///     detection). Hard red: this unit cannot be unlocked.
///   * [exact] false - we only know a codename, and one codename spans both a
///     locked variant and an unlockable one. Amber note: *some* variants are
///     locked, naming the locked model as an example.
class BootloaderLockBanner extends StatelessWidget {
  const BootloaderLockBanner({
    super.key,
    required this.lock,
    this.exact = true,
    this.compact = false,
  });

  final BootloaderLock lock;
  final bool exact;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Color bg = exact ? Colors.red.shade700 : Colors.amber.shade700;
    final Color fg = exact ? Colors.white : Colors.black;
    final String regionWord = switch (lock.region) {
      'Canada' => 'Canada',
      'US prepaid' => 'US prepaid (carrier)',
      _ => 'US',
    };
    final String title = exact ? 'Bootloader locked' : 'Some variants are locked';
    final String body = exact
        ? 'This $regionWord model (${lock.model}) ships with a Snapdragon '
              'bootloader that cannot normally be unlocked, so ROMs and custom '
              'recoveries cannot be flashed on it. If your exact unit does have '
              'a working OEM-unlocking toggle, it is a rare exception.'
        : 'The $regionWord variant of this device (e.g. ${lock.model}) ships '
              'with a locked Snapdragon bootloader and cannot normally be '
              'flashed. International variants unlock normally. Check the model '
              'number on your box or in Settings > About phone.';

    return Container(
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(exact ? Icons.lock_outline : Icons.warning_amber_rounded,
              color: fg, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: text.titleSmall?.copyWith(color: fg, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: text.bodySmall?.copyWith(color: fg.withValues(alpha: 0.95)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
