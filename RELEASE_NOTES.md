## Custom RR v0.2.3

A small polish release: header artwork on detail pages now stays clear of the status bar, and the hidden easter egg loses its always-on badge strip.

### Changes

- **Detail header images sit below the status bar.** On ROM, recovery, device, and device model pages the header artwork no longer creeps up under the status bar; it always starts just beneath it.
- **Easter egg tidy-up.** Removed the persistent badge row on the hidden easter egg screen. Unlocking still shows its brief pop-up; only the always-on strip is gone.

### Android

- `custom_rr-v0.2.3-armeabi-v7a.apk` (32-bit ARM phones)
- `custom_rr-v0.2.3-arm64-v8a.apk` (modern 64-bit ARM phones, what most people want)
- `custom_rr-v0.2.3-x86_64.apk` (emulators, Chromebooks, x86 tablets)

### Desktop

Built from the same Flutter source as the Android app, with the same catalog, freshness data, brand pages and pinch-zoom viewer.

- `custom_rr-v0.2.3-windows-x64.zip` for standard Intel / AMD PCs.
- `custom_rr-v0.2.3-windows-arm64.zip` for Surface Pro X, Copilot+ PCs and other Windows-on-ARM devices.
- `custom_rr-v0.2.3-linux-x64.tar.gz` for standard Intel / AMD desktops and laptops.
- `custom_rr-v0.2.3-linux-arm64.tar.gz` for Raspberry Pi 4/5 (64-bit OS), Ampere servers, Asahi-Linux M-series Macs and other arm64 Linux boxes.

> 32-bit x86 desktop is intentionally not shipped; Flutter dropped support for it.

### Donation links

- Buy Me a Coffee: https://buymeacoffee.com/monsiutech
- Crypto + Trocador swap available in-app under the donation sheet.

### Install

- **Android**: download the APK matching your phone's ABI (most people: `arm64-v8a`) and install.
- **Linux**: extract the tarball and run `./custom_rr`. Optional: `install.sh` in the repo registers a desktop entry.
- **Windows**: extract the zip and run `Custom_RR.exe`. Everything is self-contained.

See the full diff and commit log via the **Full Changelog** link below.
