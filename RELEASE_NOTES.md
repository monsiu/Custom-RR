## Custom RR v0.2.1

A content-and-platform release. The headline is a brand-new **Root** section sitting alongside Custom ROMs and Recoveries, two new Samsung-focused ROMs, and a dedicated **F-Droid** build of the app.

### Root section (new)

A new top-level category for Android root solutions, with the same live-freshness, brand-art and detail-page treatment as ROMs and recoveries. Reachable at `/roots`, with its own nav rail entry (shield icon), drawer tile, desktop menu shortcut (Ctrl+4), home-page action and home search hits. Launch entries:

- **Magisk** (topjohnwu): the classic systemless root via boot-image patching, with modules and Zygisk.
- **KernelSU** (tiann): kernel-space root for GKI 2.0 devices with per-app profiles.
- **KernelSU Next** (KernelSU-Next): community KernelSU fork with Magic Mount and broader non-GKI coverage.
- **APatch** (bmax121): KernelPatch-based root that hooks the running kernel without recompiling it (ARM64 only).
- **SukiSU Ultra** (SukiSU-Ultra): KernelSU fork bundling KernelPatch Module (KPM) support and Magic Mount.

Each entry pulls its latest release date live from GitHub, with curated fallbacks shipped in `assets/freshness.json`.

### Catalog and content

- **UN1CA** added: salvogiangri's debloated, customisable One UI custom firmware for Samsung Galaxy devices, with full Galaxy AI, integrated OTA, EROFS, TrickyStore / PIF / HMA, and links to the Telegram channel, GitHub repo and discussions.
- **ArtisanROM Quant** added: One UI 8 (Galaxy S25 FE) based custom firmware for Samsung Exynos 990 (S20 / Note20 series) and Exynos 9820 (S10 series) devices, built on top of the ExtremeROM and UN1CA build system.
- Live build dates for both new ROMs sourced from their GitHub Releases.

### F-Droid build variant (new)

This release introduces an F-Droid-ready build of the app, selected with a `FDROID_BUILD` compile-time flag (`flutter build apk --release --dart-define=FDROID_BUILD=true`):

- No GitHub release polling on launch.
- No in-app APK download / install path.
- No "Check for updates" UI.

Updates for the F-Droid build come from F-Droid itself. The regular GitHub-release build is unchanged and keeps the in-app updater. Ships the F-Droid metadata recipe (`fdroid/io.github.monsiu.custom_rr.yml`) and fastlane listing assets (512x512 icon plus phone screenshots).

### Android

- `custom_rr-v0.2.1-armeabi-v7a.apk` (32-bit ARM phones)
- `custom_rr-v0.2.1-arm64-v8a.apk` (modern 64-bit ARM phones, what most people want)
- `custom_rr-v0.2.1-x86_64.apk` (emulators, Chromebooks, x86 tablets)

### Desktop

Built from the same Flutter source as the Android app, with the same catalog, freshness data, brand pages and pinch-zoom viewer.

- `custom_rr-v0.2.1-windows-x64.zip` for standard Intel / AMD PCs.
- `custom_rr-v0.2.1-windows-arm64.zip` for Surface Pro X, Copilot+ PCs and other Windows-on-ARM devices.
- `custom_rr-v0.2.1-linux-x64.tar.gz` for standard Intel / AMD desktops and laptops.
- `custom_rr-v0.2.1-linux-arm64.tar.gz` for Raspberry Pi 4/5 (64-bit OS), Ampere servers, Asahi-Linux M-series Macs and other arm64 Linux boxes.

> 32-bit x86 desktop is intentionally not shipped; Flutter dropped support for it.

### Donation links

- Buy Me a Coffee: https://buymeacoffee.com/monsiutech
- Crypto + Trocador swap available in-app under the donation sheet.

### Install

- **Android**: download the APK matching your phone's ABI (most people: `arm64-v8a`) and install.
- **Linux**: extract the tarball and run `./custom_rr`. Optional: `install.sh` in the repo registers a desktop entry.
- **Windows**: extract the zip and run `Custom_RR.exe`. Everything is self-contained.

See the full diff and commit log via the **Full Changelog** link below.
