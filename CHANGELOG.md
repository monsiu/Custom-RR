# Changelog

All notable changes to **Custom RR** are documented here. Format loosely
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the
project uses [Semantic Versioning](https://semver.org/) (currently
pre-1.0, so minor bumps may include breaking changes).

## [Unreleased]

## [0.2.0] - 2026-05-29

### Added
- **PixelOS** catalog entry with its full official device list, sourced live from `PixelOS-AOSP/official_devices`.
- **LineageOS coverage expanded** to every form factor on branch 20+ (phones, tablets, Android TV, set-top boxes).
- `tool/check_defunct_activity.dart` and `.github/workflows/defunct-watch.yml`: scheduled job that watches ROM repos for inactivity and flags ones going quiet.
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
- **Havoc-OS** moved to the defunct list.
- About page: Discord tile + compact-screen donation collapse, comma-style tweaks per project writing style.
- Donate copy: warmer tone, restated value, mention of one-off tips alongside the Silver / Gold tiers.
- Recoveries page: removed the now-redundant Treble hint banner.
- Sitewide Discord invite migrated to `DqsAR42ATR`.
- Release artifacts (APK + Linux tarball) now include the version in the filename.
- README: license is now explicitly named (GPL-3.0-only).

### Fixed
- Donate nudge buttons no longer clip on narrow screens.
- `sync_catalog.dart` now includes PixelOS-only vendors (10or, etc.) in the manufacturer list, so the data-integrity test passes for brands not present in the LineageOS wiki.
- `sync_catalog.dart` trailing-comma lints.

### Removed
- **phh-Treble** entry (project archived; TrebleDroid wiki is now the canonical GSI index).
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
