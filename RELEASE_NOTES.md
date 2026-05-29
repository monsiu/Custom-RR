## Custom RR v0.2.0

The first release of the v0.2 line. Bigger catalog, friendlier UX, and Custom RR is no longer Android-only: this build ships native **Linux** and **Windows** desktop binaries alongside the usual APK split.

### Desktop is here

- **Windows desktop build (new).** Portable `.zip` you can unpack anywhere; `Custom_RR.exe` plus the bundled MSVC runtime DLLs (`msvcp140.dll`, `vcruntime140.dll`, `vcruntime140_1.dll`) means you do not have to install the Visual C++ Redistributable.
  - `custom_rr-v0.2.0-windows-x64.zip` for standard Intel / AMD PCs.
  - `custom_rr-v0.2.0-windows-arm64.zip` for Surface Pro X, Copilot+ PCs, and other Windows-on-ARM devices.
- **Linux desktop build.**
  - `custom_rr-v0.2.0-linux-x64.tar.gz` for standard Intel / AMD desktops and laptops.
  - `custom_rr-v0.2.0-linux-arm64.tar.gz` for Raspberry Pi 4/5 (64-bit OS), Ampere servers, Asahi-Linux M-series Macs, and other arm64 Linux boxes.
- Both desktop platforms are built from the same Flutter source as the Android app and ship the same catalog, freshness data, brand pages, and pinch-zoom viewer.

> 32-bit x86 desktop is intentionally not shipped; Flutter dropped support for it.

### Android

- `custom_rr-v0.2.0-armeabi-v7a.apk` (32-bit ARM phones)
- `custom_rr-v0.2.0-arm64-v8a.apk` (modern 64-bit ARM phones, what most people want)
- `custom_rr-v0.2.0-x86_64.apk` (emulators, Chromebooks, x86 tablets)

### Catalog and content

- **PixelOS** added, with its full official device list pulled live from `PixelOS-AOSP/official_devices`.
- **LineageOS** coverage expanded to every form factor on branch 20+ (phones, tablets, Android TV, set-top boxes).
- **RisingOS Revived** added as the community continuation of RisingOS, with SourceForge wired up as both the download target and the live freshness source.
- **Project Elixir** now ships with a detailed multi-paragraph warning covering the 2024 killswitch incident, closed-source payload, paid Telegram / Patreon tiers, and the eventual shutdown - including which ROMs to migrate to (crDroid, Evolution X, DerpFest).
- **Defunct ROM section** on the ROMs page: ArrowOS, POSP and the original RisingOS join AOSP Extended, MoKee, RR, Dirty Unicorns, Octavi OS and Havoc-OS, each with archived status, last-build date and successor suggestions.

### App UX

- **Clickable link chips** on every detail page (Telegram, GitHub, Discord, Matrix, forum, web, custom).
- **Per-entry warning banners** for ROMs with known issues, rendered inline on the detail page.
- **XDA search reminder** popup on every defunct-card click (first time only, suppression shared with the existing mobile reminder).
- Crypto donation sheet improvements: long-press to copy, QR code dialog per coin, "Verify on explorer" button (mempool.space, etherscan, bscscan, solscan), BTC Lightning footnote (`monsiutech@cake.cash`), BNB Smart Chain address (accepts ETH / USDT / USDC on BSC).
- Trocador AnonPay swap description so the checkout page shows context.
- In-app privacy policy page rendered from the bundled `PRIVACY.md`.

### Infrastructure

- `discord-notify` workflow posts to a webhook on every published release.
- `sync-catalog` weekly job runs the catalog sync and opens a PR if anything changed.
- `defunct-watch` scheduled job watches archived ROM repos for new activity.
- SPDX license tag `GPL-3.0-only` in `pubspec.yaml`.
- Fastlane metadata stub under `fastlane/metadata/android/en-US/` for F-Droid / IzzyOnDroid ingestion.

### Donation links

- Buy Me a Coffee: https://buymeacoffee.com/monsiutech
- Crypto + Trocador swap available in-app under the donation sheet.

### Install

- **Android**: download the APK matching your phone's ABI (most people: `arm64-v8a`) and install.
- **Linux**: extract the tarball and run `./custom_rr`. Optional: `install.sh` in the repo registers a desktop entry.
- **Windows**: extract the zip and run `Custom_RR.exe`. Everything is self-contained.

See the full diff and commit log via the **Full Changelog** link below.
