# Changelog

All notable changes to **Custom RR** are documented here. Format loosely
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the
project uses [Semantic Versioning](https://semver.org/) (currently
pre-1.0, so minor bumps may include breaking changes).

## [Unreleased]

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
