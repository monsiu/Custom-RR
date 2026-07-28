## Custom RR v1.3.4

This release adds a firmware and GSI hint for Infinix, Itel and Tecno phones,
ships an unsigned iOS build for sideloaders, and flattens the card styling.

### Added

- **Firmware source hint for Infinix, Itel and Tecno.** Brand and device pages
  for these budget brands now point to the HOVATEK forum, its firmware and
  flashing-tool indexes, and its online TWRP builder for firmware, recovery and
  unlock help, plus the Treble & GSI tab for running a custom build, since they
  rarely have a dedicated custom ROM.
- **iOS build for sideloading.** Each GitHub release now includes an unsigned
  iOS `.ipa` for AltStore and TrollStore users. It is not signed for a normal
  install; sideloading tools re-sign it with your own certificate.

### Changed

- **Cleaner card styling.** The highlighted callouts (Treble & GSIs and Flash a
  Custom ROM) and the "your device" suggestion card now use a solid color
  instead of a gradient, for a flatter, cleaner look.

See the full diff and commit log via the **Full Changelog** link below.
