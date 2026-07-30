## Custom RR v1.3.6

This release makes device detection smarter and lets happy users rate the app
at the right moment.

### Added

- **Better-timed "rate the app" ask on Google Play.** After the app has
  actually helped you (a couple of ROM or recovery downloads opened), the Play
  version now asks for a quick rating in a small bottom sheet, at most once a
  week, and never again once you rate or decline. A "Rate the app" shortcut
  also joined the app menu.

### Fixed

- **Device detection matches many more phones.** The "your device" card now
  recognizes vendor-prefixed codenames (an Infinix Note 30 reporting
  `Infinix-X6833B`), regional variants (a realme 7 reporting `rmx2151l1`),
  stock OnePlus names (`OnePlus6T` finds fajita), and unified family builds
  (a Redmi 8 reporting `olive` finds the shared `mi439` builds), instead of
  telling you the phone is not in the catalog.

See the full diff and commit log via the **Full Changelog** link below.
