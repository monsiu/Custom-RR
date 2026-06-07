## Custom RR v1.0.0

The first stable release. Custom RR is now a settled, dependable home for the Android modding scene: browse custom ROMs, recoveries, root solutions and Treble GSIs, see which ones officially support your device, and grab the official downloads, all in one place.

### Highlights

- **It knows your phone.** On Android, Custom RR now detects your device and offers a one-tap jump to its page, with every ROM and recovery that supports it. Not in the catalog? It points you to Treble & GSI or lets you request it. All on-device, no network or tracking.
- **Suggest what to add.** Can't find a ROM, recovery, GSI, or root solution? Request it straight from the app: from the menu (and the desktop side bar), or the quick prompt at the bottom of each list.
- **Request a missing device.** If "Find my phone" turns up nothing, tap "Request this device" to ask for it, with your search prefilled.
- **Device codenames on tap.** Every supported-device chip on ROM and recovery pages now shows the codename next to the model, so you can match a build to your exact phone at a glance.
- **More trustworthy freshness badges.** crDroid, Evolution X, OrangeFox and Project Infinity X now update their "last build" status automatically from their official sources, and a few entries that looked newer than they really were now read correctly.
- **Treble & GSI safety notice up top.** The flashing-risk disclaimer now greets you before the walkthrough instead of hiding at the bottom.

### Android

- `custom_rr-v1.0.0-armeabi-v7a.apk` (32-bit ARM phones)
- `custom_rr-v1.0.0-arm64-v8a.apk` (modern 64-bit ARM phones, what most people want)
- `custom_rr-v1.0.0-x86_64.apk` (emulators, Chromebooks, x86 tablets)

### Desktop

Built from the same Flutter source as the Android app, with the same catalog, freshness data, brand pages and pinch-zoom viewer.

- `custom_rr-v1.0.0-windows-x64.zip` for standard Intel / AMD PCs.
- `custom_rr-v1.0.0-windows-arm64.zip` for Surface Pro X, Copilot+ PCs and other Windows-on-ARM devices.
- `custom_rr-v1.0.0-linux-x64.tar.gz` for standard Intel / AMD desktops and laptops.
- `custom_rr-v1.0.0-linux-arm64.tar.gz` for Raspberry Pi 4/5 (64-bit OS), Ampere servers, Asahi-Linux M-series Macs and other arm64 Linux boxes.
- `custom_rr-v1.0.0-macos-universal.zip` for macOS (Apple Silicon and Intel in one build).

> The macOS build is unsigned for now: on first launch, right-click the app and choose **Open** to get past Gatekeeper.

> 32-bit x86 desktop is intentionally not shipped; Flutter dropped support for it.

### Donation links

- Buy Me a Coffee: https://buymeacoffee.com/monsiutech
- Crypto + Trocador swap available in-app under the donation sheet.

### Install

- **Android**: download the APK matching your phone's ABI (most people: `arm64-v8a`) and install.
- **Linux**: extract the tarball and run `./custom_rr`. Optional: `install.sh` in the repo registers a desktop entry.
- **Windows**: extract the zip and run `Custom_RR.exe`. Everything is self-contained.

See the full diff and commit log via the **Full Changelog** link below.
