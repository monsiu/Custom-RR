## Custom RR v0.2.2

A catalog-and-pipeline release: a big new ROM with a live device list, two Samsung device-list corrections, and a Google Play build of the app produced straight from CI.

### Catalog and content

- **Project Infinity X** added, with its device list fetched live from the project's `official_devices` repo. The list merges both the `16` and `master` branches (`16` wins on conflicts) so it matches the official downloads page exactly at 94 devices.
- **ArtisanROM device list fixed.** Dropped the Galaxy Note10 series (not supported) and surfaced the Galaxy Note20 series (`c1s`, `c2s`), so the list now matches the maintainer's S10 / S20 / Note20 coverage.
- **UN1CA device list fixed.** Pinned to the 7 official devices from the project's downloads page (Galaxy A52s / A73 / M52 5G and the Exynos S21 series) instead of a broad "any modern Samsung phone" heuristic.

### Google Play build (new)

Custom RR now has a Play-ready build, available on the Google Play Store. To meet Google Play policy it leaves out the in-app updater and the crypto donation UI; updates come from Play itself. The build offered here on GitHub is unchanged and keeps the in-app updater.

### Android

- `custom_rr-v0.2.2-armeabi-v7a.apk` (32-bit ARM phones)
- `custom_rr-v0.2.2-arm64-v8a.apk` (modern 64-bit ARM phones, what most people want)
- `custom_rr-v0.2.2-x86_64.apk` (emulators, Chromebooks, x86 tablets)

### Desktop

Built from the same Flutter source as the Android app, with the same catalog, freshness data, brand pages and pinch-zoom viewer.

- `custom_rr-v0.2.2-windows-x64.zip` for standard Intel / AMD PCs.
- `custom_rr-v0.2.2-windows-arm64.zip` for Surface Pro X, Copilot+ PCs and other Windows-on-ARM devices.
- `custom_rr-v0.2.2-linux-x64.tar.gz` for standard Intel / AMD desktops and laptops.
- `custom_rr-v0.2.2-linux-arm64.tar.gz` for Raspberry Pi 4/5 (64-bit OS), Ampere servers, Asahi-Linux M-series Macs and other arm64 Linux boxes.

> 32-bit x86 desktop is intentionally not shipped; Flutter dropped support for it.

### Donation links

- Buy Me a Coffee: https://buymeacoffee.com/monsiutech
- Crypto + Trocador swap available in-app under the donation sheet.

### Install

- **Android**: download the APK matching your phone's ABI (most people: `arm64-v8a`) and install.
- **Linux**: extract the tarball and run `./custom_rr`. Optional: `install.sh` in the repo registers a desktop entry.
- **Windows**: extract the zip and run `Custom_RR.exe`. Everything is self-contained.

See the full diff and commit log via the **Full Changelog** link below.
