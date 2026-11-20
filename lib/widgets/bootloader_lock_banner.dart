import 'package:material_ui/material_ui.dart';

import '../util/bootloader_lock.dart';

/// Warns that a bootloader cannot normally be unlocked, so no ROM or recovery
/// can be flashed.
///
/// The model-number rule is only decisive when the exact model is known (see
/// [bootloaderLockForModel]), and one codename can span a locked variant and an
/// unlockable one, so three cases are distinguished:
///   * [exact] true  - we know the user's precise model (e.g. on-device
///     detection). Hard red: this unit cannot be unlocked.
///   * [exact] false, [hasUnlockableVariant] true - only a codename is known
///     and it also has an unlockable variant. Amber: *some* variants are
///     locked, naming the locked model as an example.
///   * [exact] false, [hasUnlockableVariant] false - only a codename is known
///     and every known variant is locked. Hard red: no variant can be flashed.
class BootloaderLockBanner extends StatelessWidget {
  const BootloaderLockBanner({
    super.key,
    required this.lock,
    this.exact = true,
    this.hasUnlockableVariant = false,
    this.compact = false,
  });

  final BootloaderLock lock;
  final bool exact;
  final bool hasUnlockableVariant;
  final bool compact;

  /// True when the message should be a hard "this cannot be unlocked" claim:
  /// either we know the exact model, or every variant of the codename is locked.
  bool get _definitive => exact || !hasUnlockableVariant;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Color bg = _definitive ? Colors.red.shade700 : Colors.amber.shade700;
    final Color fg = _definitive ? Colors.white : Colors.black;
    // "US" / "Canada" / "US prepaid (carrier)" without defaulting an unknown
    // region to US, so a future rule that adds a region can't mislabel it.
    final String regionWord =
        lock.region == 'US prepaid' ? 'US prepaid (carrier)' : lock.region;

    final String title;
    final String body;
    if (exact) {
      title = 'Bootloader locked';
      body = 'This $regionWord model (${lock.model}) ships with a Snapdragon '
          'bootloader that cannot normally be unlocked, so ROMs and custom '
          'recoveries cannot be flashed on it. If your exact unit does have a '
          'working OEM-unlocking toggle, it is a rare exception.';
    } else if (hasUnlockableVariant) {
      title = 'Some variants are locked';
      body = 'The $regionWord variant of this device (e.g. ${lock.model}) ships '
          'with a locked Snapdragon bootloader and cannot normally be flashed. '
          'International variants unlock normally. Check the model number on '
          'your box or in Settings > About phone.';
    } else {
      title = 'Bootloader locked';
      body = 'Every known variant of this device (e.g. ${lock.model}) ships '
          'with a locked Snapdragon bootloader, so ROMs and custom recoveries '
          'cannot normally be flashed on it.';
    }

    return Container(
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(_definitive ? Icons.lock_outline : Icons.warning_amber_rounded,
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
