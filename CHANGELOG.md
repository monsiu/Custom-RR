# Changelog

All notable changes to **Custom RR** are documented here. Format loosely
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the
project uses [Semantic Versioning](https://semver.org/) (currently
pre-1.0, so minor bumps may include breaking changes).

## [Unreleased]

### Added
- In-app privacy policy page rendered from the bundled `PRIVACY.md`.
- Crypto donation sheet improvements:
  - Long-press to copy.
  - QR code dialog per coin.
  - "Verify on explorer" button (mempool.space, etherscan, bscscan, solscan).
  - BTC Lightning footnote (`monsiutech@cake.cash`).
  - BNB Smart Chain address (also accepts ETH/USDT/USDC on BSC).
- Trocador AnonPay swap description so the checkout page shows context.
- "Monsiu Tech Solutions" link in About page opens https://monsiu.github.io/.
- README "Crypto donations" section listing all addresses out-of-band for
  donor verification.

### Changed
- About page polish, comma-style tweaks per project writing style.

## [0.1.0] - Initial in-development release

- Catalog of custom ROMs and recoveries from upstream LineageOS wiki.
- Device → compatible builds picker.
- Deep links for every ROM / recovery / device.
- Material 3 adaptive layout, dynamic color, light/dark/system theme.
- Update checker against GitHub releases.
- Donation flow (BTC, ETH, BNB, SOL, XMR + Trocador swap).
- Bundled freshness data for the catalog.
