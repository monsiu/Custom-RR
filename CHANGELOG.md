# Changelog

All notable changes to **Custom RR** are documented here. Format loosely
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the
project uses [Semantic Versioning](https://semver.org/) (currently
pre-1.0, so minor bumps may include breaking changes).

## [0.2.1] - 2026-05-30

### Fixed
- **F-Droid build compliance.** Reproducible-build and scanner fixes for the
  F-Droid pipeline, with no change to app behaviour:
  - Excluded the proprietary Google Play Core library (deferred-components
    `SplitCompat`/`SplitInstall`) that the Flutter embedding pulls in but this
    app never uses, plus a matching `-dontwarn` ProGuard rule.
  - Disabled the AGP dependency-metadata block (`dependenciesInfo`) so the APK
    no longer carries the extra signing block F-Droid's scanner rejects.
  - Hardcoded literal `versionCode`/`versionName` in `android/app/build.gradle`
    (kept in sync with `pubspec.yaml`) so F-Droid's update checker can read the
    version from each git tag.

### Added
- **Official screenshots for UN1CA and ArtisanROM.** UN1CA now ships the 7 official screenshots from its XDA release thread (home, lock screen, app drawer, quick settings, UN1CA Settings, UN1CA Updates, software info). ArtisanROM ships the 11 maintainer-supplied shots (Settings, Updater, Package installer). Both sets are bundled locally under `images/screenshots/` because the upstream hosts block hot-linking, so the catalog references them as asset paths instead of URLs.
- **Link chips on every detail page.** The clickable Website / GitHub / Forum chips previously only on the newest entries now appear on every ROM and recovery: LineageOS, crDroid, Pixel Experience, Evolution X, Paranoid Android, DotOS, Bliss, POSP, Voltage OS, Project Elixir, PixelOS, GrapheneOS, CalyxOS, /e/OS, DivestOS, DerpFest, TWRP, OrangeFox, RedWolf, PitchBlack, and SHRP.
- **Keyboard navigation for screenshots on desktop (Linux/Windows).**
  - Full-screen gallery: Left/Right (and Up/Down) arrow keys page through the shots, Escape closes. Clickable on-screen arrows were also added since desktop has no swipe gesture. Arrow keys are ignored while pinch-zoomed.
  - Detail-page screenshot strip: arrow keys scroll the carousel while the pointer hovers it (the strip grabs focus on hover and releases on exit, so it never captures keys page-wide).
- **F-Droid build variant.** New `--dart-define=FDROID_BUILD=true` compile-time flag (`lib/util/build_flags.dart`) that strips the self-update machinery for F-Droid distribution: no GitHub release polling on launch, no in-app APK download/install path, and no "Check for updates" UI. GitHub-release builds are unchanged (flag defaults off). Adds the F-Droid metadata recipe (`fdroid/io.github.monsiu.custom_rr.yml`) and fastlane listing assets (icon, phone screenshots).
- **Root section.** New top-level catalog category for Android root solutions, mirroring the Custom ROMs and Custom Recoveries sections. Reachable at `/roots`, with its own nav rail entry (shield icon), drawer tile, desktop menu shortcut (Ctrl+4), home page action, and home search hits. Initial entries:
  - **Magisk** (topjohnwu): the classic systemless root via boot-image patching, with modules and Zygisk.
  - **KernelSU** (tiann): kernel-space root for GKI 2.0 devices with per-app profiles.
  - **KernelSU Next** (KernelSU-Next/KernelSU-Next): community KernelSU fork with Magic Mount and broader non-GKI coverage.
  - **APatch** (bmax121): KernelPatch-based root that hooks the running kernel without recompiling it (ARM64 only).
  - **SukiSU Ultra** (SukiSU-Ultra/SukiSU-Ultra): KernelSU fork bundling KernelPatch Module (KPM) support and Magic Mount.
- Banner art for all five root projects (`images/magisk.png`, `images/kernelsu.png`, `images/kernelsu_next.png`, `images/apatch.png`, `images/sukisu.png`).
- Freshness wired up for each root entry: `tool/sync_freshness.dart` pulls the latest GitHub Release per project, with curated fallbacks shipped in `assets/freshness.json`.
- **UN1CA** catalog entry: salvogiangri's debloated, customisable One UI custom firmware for Samsung Galaxy devices, with full Galaxy AI, integrated OTA, EROFS, TrickyStore / PIF / HMA, and links to the Telegram channel, GitHub repo, and discussions.
- **ArtisanROM Quant** catalog entry: One UI 8 (Galaxy S25 FE) based custom firmware for Samsung Exynos 990 (S20 / Note20 series) and Exynos 9820 (S10 / Note10 series) devices, built on top of the ExtremeROM and UN1CA build system.
- Banner art for both ROMs (`images/un1ca.png`, `images/artisanrom.png`).
- Live freshness for UN1CA and ArtisanROM: `tool/sync_freshness.dart` pulls the latest build date from each project's GitHub Releases, with curated fallbacks in `assets/freshness.json`.

### Changed
- Screenshot rendering now handles both remote URLs (`CachedNetworkImage`) and bundled asset paths (`Image.asset`) in the detail-page tiles and the full-screen viewer, with neighbour precaching via `AssetImage` for local shots.
- Optimized every bundled image to shrink the app: oversized logos are downscaled to 720px and palette-quantized (pngquant), and the screenshots are recompressed (max width 1080, quality 82). The `images/` payload drops from ~20 MB to ~5 MB, cutting the per-architecture APK from ~42 MB to ~28 MB with no visible quality loss.

## [0.2.0] - 2026-05-29

### Added
- **Windows desktop build.** New `build-windows` matrix job in `release.yml` ships portable zips (`custom_rr-vX.Y.Z-windows-<arch>.zip`) with `Custom_RR.exe` plus the bundled MSVC runtime DLLs (`msvcp140.dll`, `vcruntime140.dll`, `vcruntime140_1.dll`) so users do not need to install the VC++ Redistributable.
- **arm64 desktop builds for Linux and Windows.** Both `build-linux` and `build-windows` now run as a `{arch: x64, arm64}` matrix on GitHub's native arm64 runners (`ubuntu-24.04-arm`, `windows-11-arm`), so the release page carries native binaries for Raspberry Pi-class boxes, Ampere servers, Asahi M-series Linux, Surface Pro X / Copilot+ PCs, and similar. (32-bit x86 desktop remains out of scope; Flutter does not build it.)
- **PixelOS** catalog entry with its full official device list, sourced live from `PixelOS-AOSP/official_devices`.
- **LineageOS coverage expanded** to every form factor on branch 20+ (phones, tablets, Android TV, set-top boxes).
- **RisingOS Revived**: new catalog entry for the community continuation of RisingOS, with SourceForge as both the download target and the live freshness source (RSS-based fetcher in `tool/sync_freshness.dart`).
- **Project Elixir warning**: detailed multi-paragraph warning covering the 2024 killswitch incident (wipes internal storage / SD / eSIMs on paywall-bypass detection) plus the closed-source obfuscated payload, paid Telegram / Patreon tiers, banning of critics, retaliatory OTAs, legal threats, and the eventual shutdown / migration recommendation (crDroid, Evolution X, DerpFest).
- **Defunct ROM section** on the ROMs page: ArrowOS, POSP, and RisingOS (original) join the existing list (AOSP Extended, MoKee, RR, Dirty Unicorns, Octavi OS, Havoc-OS) with archived status, last build date, and successor suggestions.
- **Clickable link chips** on every detail page (Telegram, GitHub, Discord, Matrix, forum, web, custom) sourced from a new `links` schema field in `assets/catalog.json`.
- **Per-entry `warning` field** in the catalog schema, rendered as an inline banner on the detail page.
- **XDA search reminder** popup on every defunct card click (first time only, suppression shared with the existing mobile reminder).
- `tool/check_defunct_activity.dart` and `.github/workflows/defunct-watch.yml`: scheduled job that watches ROM repos for inactivity and flags ones going quiet (ArrowOS, PotatoProject, RisingOSS added to the watchlist).
- `discord-notify` workflow: posts to a webhook on every published release (Python-based, safer payload handling, `@everyone` allowed mentions).
- `.github/workflows/sync-catalog.yml`: weekly job that runs the catalog sync and opens a PR if anything changed.
- SPDX license tag `SPDX-License-Identifier: GPL-3.0-only` in `pubspec.yaml`.
- README "Catalog sources" section crediting upstream data providers.
- Fastlane metadata stub under `fastlane/metadata/android/en-US/` for F-Droid / IzzyOnDroid ingestion.
- In-app privacy policy page rendered from the bundled `PRIVACY.md`.
- Crypto donation sheet improvements:
  - Long-press to copy.
  - QR code dialog per coin.
  - "Verify on explorer" button (mempool.space, etherscan, bscscan, solscan).
  - BTC Lightning footnote (`monsiutech@cake.cash`).
  - BNB Smart Chain address (also accepts ETH/USDT/USDC on BSC).
- Trocador AnonPay swap description so the checkout page shows context.
- "Monsiu Tech Solutions" link in About page opens https://monsiu.github.io/.
- README "Crypto donations" section listing all addresses out-of-band for donor verification.

### Changed
- **All GSI list links** now point to the maintained `TrebleDroid/treble_experimentations` wiki instead of the archived `phhusson` one.
- **TrebleDroid pitch** rewritten to credit it directly (no longer framed as "successor to phh-Treble").
- **Bulk ROM download URL refresh** across the catalog (crDroid, Evolution X, DotOS, BlissROMs, VoltageOS, DerpFest, and others) so every "Get builds" button lands on a live page.
- **Havoc-OS, ArrowOS, POSP, RisingOS (original)** moved to the defunct list.
- **PotatoAOSP** removed from the catalog entirely (project gone, no successor).
- **Buy Me a Coffee handle** updated to `monsiutech` everywhere (app, README, FUNDING.yml).
- **Defunct ROM cards** stretch to full width on phones (1 column under ~332 px, 2-4 columns above) so they match the live ROM list above.
- About page: Discord tile + compact-screen donation collapse, comma-style tweaks per project writing style.
- Donate copy: warmer tone, restated value, mention of one-off tips alongside the Silver / Gold tiers.
- Recoveries page: removed the now-redundant Treble hint banner.
- Device page: stronger GSI hint when no ROMs cover the brand; explicit GPL-3.0 license badge.
- Sitewide Discord invite migrated to `DqsAR42ATR`.
- Release artifacts (APK + Linux tarball) now include the version in the filename.
- README: license is now explicitly named (GPL-3.0-only).

### Fixed
- **RisingOS Revived 0.387 px catalog card overflow**: subtitle capped at 3 lines with ellipsis and tagline shortened.
- Donate nudge buttons no longer clip on narrow screens.
- `sync_catalog.dart` now includes PixelOS-only vendors (10or, etc.) in the manufacturer list, so the data-integrity test passes for brands not present in the LineageOS wiki.
- `sync_catalog.dart` trailing-comma lints.

### Removed
- **phh-Treble** entry (project archived; TrebleDroid wiki is now the canonical GSI index).
- **PotatoAOSP** catalog entry.
- Stale `arrowos` / `potatoaosp` / `risingos` curated freshness seeds.
- Unused `_GsiStatus.archivedIndexed` enum value.
- Stray `flutter_01.png` screenshot artifact (and added the pattern to `.gitignore`).

## [0.1.0] - Initial in-development release

- Catalog of custom ROMs and recoveries from upstream LineageOS wiki.
- Device → compatible builds picker.
- Deep links for every ROM / recovery / device.
- Material 3 adaptive layout, dynamic color, light/dark/system theme.
- Update checker against GitHub releases.
- Donation flow (BTC, ETH, BNB, SOL, XMR + Trocador swap).
- Bundled freshness data for the catalog.
