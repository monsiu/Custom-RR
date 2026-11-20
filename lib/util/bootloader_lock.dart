/// Infers whether a phone's bootloader can be unlocked from its retail model
/// number.
///
/// Samsung sells US (model suffix `U` / `U1`), Canada (`W`) and US prepaid /
/// Tracfone (`SM-S…DL`) units with a Snapdragon SoC whose bootloader is
/// permanently locked: the "OEM unlocking" toggle is absent or inert, so no
/// custom ROM or recovery can be flashed. International variants of the same
/// phone (suffix `F`, `B`, `G`, `M`, …) unlock normally, so the lock is a
/// property of the exact model number, never of the codename, and one codename
/// routinely covers both a locked and an unlockable model.
///
/// The suffix is a strong signal, not a guarantee: it really tracks the
/// chipset, and a few pre-2017 models behaved differently. Copy built on this
/// should say a unit "cannot normally be unlocked" and invite exceptions rather
/// than state it as fact.
library;

/// A model number that ships with a bootloader that cannot normally be
/// unlocked, with a human-readable region for the explanation.
class BootloaderLock {
  const BootloaderLock({required this.model, required this.region});

  /// The exact model number that is locked, e.g. `SM-A015U`.
  final String model;

  /// Where that model is sold, e.g. `US` or `Canada`, used in user-facing copy.
  final String region;
}

final RegExp _samsungUs = RegExp(r'^SM-[A-Z]?\d+U1?$');
final RegExp _samsungCanada = RegExp(r'^SM-[A-Z]?\d+W$');
final RegExp _samsungPrepaid = RegExp(r'^SM-S\d+DL$');

/// Lock info when [model] matches a known permanently-locked pattern, else
/// null (the model unlocks normally, or is not one we have a rule for).
BootloaderLock? bootloaderLockForModel(String model) {
  final String m = model.trim().toUpperCase().replaceFirst('SAMSUNG-', '');
  if (m.isEmpty) return null;
  if (_samsungUs.hasMatch(m)) return BootloaderLock(model: m, region: 'US');
  if (_samsungCanada.hasMatch(m)) {
    return BootloaderLock(model: m, region: 'Canada');
  }
  if (_samsungPrepaid.hasMatch(m)) {
    return BootloaderLock(model: m, region: 'US prepaid');
  }
  return null;
}

/// The first locked model among [models], or null if none are known-locked.
/// Used where only a codename's full set of variants is known; the result
/// names which specific variant is the problem.
BootloaderLock? bootloaderLockForModels(Iterable<String> models) {
  for (final String model in models) {
    final BootloaderLock? lock = bootloaderLockForModel(model);
    if (lock != null) return lock;
  }
  return null;
}

/// True when [models] contains at least one model that is not known-locked, so
/// the device has a variant that unlocks normally. Blank entries are ignored.
bool hasUnlockableVariant(Iterable<String> models) {
  for (final String model in models) {
    if (model.trim().isEmpty) continue;
    if (bootloaderLockForModel(model) == null) return true;
  }
  return false;
}
