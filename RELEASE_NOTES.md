## Custom RR v0.1.0, first public preview

Custom RR is a single home for popular Android custom ROMs and recoveries.
It collects what you actually need before flashing: official downloads,
maintainer links, recent screenshots, and step-by-step install notes,
all in one place and ready offline once cached.

This is the first preview build. The catalog is curated, the
infrastructure is in place, and the app is usable end-to-end on Android
and Linux, but expect rough edges and breaking changes before v1.0.

### Highlights

- **Catalog of custom ROMs and recoveries**, kept in `assets/catalog.json`
  and synced from upstream sources by a Dart tooling script.
- **Screenshot gallery** per project with pinch-to-zoom and a thumbnail
  carousel, sourced from the upstream maintainer's media.
- **Freshness checking**: the app tracks when each project last published
  a build so you can see at a glance what is actively maintained.
- **Flashing notes** for each entry, written for someone who has bootloader
  unlocking and a working recovery already.
- **In-app updater (Android)**: checks GitHub releases, downloads the APK
  that matches your device's ABI, and hands off to the system installer.
  Errors are surfaced in the modal with a readable message.
- **Material 3 theming** with light, dark, and true-black AMOLED modes
  plus a custom brand palette.
- **Donations**: optional crypto donate sheet and a polite nudge that
  never blocks usage.
- **Cross-platform**: ships as split-per-ABI APKs for Android and a
  `.tar.gz` bundle for Linux x64.

### Install

- **Android**: download the APK that matches your device's ABI
  (arm64-v8a for most modern phones), then open it. You may need to
  allow "Install unknown apps" for your browser or file manager.
- **Linux x64**: extract `custom_rr-linux-x64.tar.gz` and run
  `./install.sh` inside the extracted folder, or just launch
  `./custom_rr`.

### Known limitations

- Catalog coverage is intentionally small for this preview; entries will
  be added incrementally.
- No iOS, macOS, Windows, or web builds in this release.
- The updater is Android-only.

### Feedback

Please open issues at
https://github.com/monsiu/Custom-RR/issues with the model, Android
version, and what you were trying to do.
