# Contributing to Custom RR

Thanks for your interest in helping out. This document covers everything you need
to build, run, and release Custom RR, plus how the catalog is generated and kept
honest. For what the app is and how to install it, see the [README](README.md).

Bug reports and feature requests are welcome on the
[issue tracker](https://github.com/monsiu/Custom-RR/issues). For anything code-
or catalog-related, an issue is preferred over email.

## Table of contents

- [Build from source](#build-from-source)
- [Releasing](#releasing)
- [Updating the catalog](#updating-the-catalog)
- [Automation](#automation)
- [Android App Links](#android-app-links)
- [Linux desktop](#linux-desktop)
- [Windows desktop](#windows-desktop)
- [macOS desktop](#macos-desktop)

## Build from source

```bash
git clone https://github.com/monsiu/Custom-RR.git
cd Custom-RR
flutter pub get
flutter run
```

**Requirements**: Flutter 3.22+, Dart 3.4+, Java 17, Android SDK 36
(compile/target), minSdk 24.

For reproducible builds, this repo ships a [`.fvmrc`](.fvmrc); use
[fvm](https://fvm.app) to pin the Flutter version automatically.

## Releasing

Bumping `version:` in `pubspec.yaml` on `main` is the entire release flow:
[`auto-tag.yml`](.github/workflows/auto-tag.yml) pushes a matching `vX.Y.Z` tag,
which triggers [`release.yml`](.github/workflows/release.yml) to build the
Android per-ABI APKs, the Linux tarball, the Windows zip, and the macOS universal
zip, then publish a draft release with auto-generated notes.

Release builds expect signing config in `android/key.properties` (see
[`android/key.properties.template`](android/key.properties.template)). Without
it, release builds fall back to debug signing for local testing.

```bash
flutter build apk --release
flutter build appbundle --release
```

GitHub release artifacts opt into the bundled updater explicitly:

```bash
flutter build apk --release --dart-define=GITHUB_RELEASE_BUILD=true
```

Default source builds, F-Droid builds, and Google Play builds leave that flag
off, so the GitHub release updater and "Check for updates" UI stay disabled.

Google Play store listing metadata is mirrored under
[`fastlane/metadata/android`](fastlane/metadata/android). For Play listing
changes, validate and upload the metadata with the Fastlane lanes documented in
[`fastlane/README.md`](fastlane/README.md), then review the pending changes in
Play Console and send them for review manually. The metadata lanes do not upload
APK/AAB files or changelogs.

## Updating the catalog

The shipped `assets/catalog.json` is generated from the upstream
[LineageOS wiki](https://github.com/LineageOS/lineage_wiki) device YAMLs +
the [PixelOS-AOSP/official_devices](https://github.com/PixelOS-AOSP/official_devices)
repo by [`tool/sync_catalog.dart`](tool/sync_catalog.dart). Each
ROM/recovery's `devices` list is filtered by a per-project policy
(vendor whitelist + minimum LineageOS branch / release year). To refresh:

```bash
dart run tool/sync_catalog.dart            # use cached YAMLs in tool/.cache/
dart run tool/sync_catalog.dart --refresh  # re-download the wiki tarball
```

Freshness signals on every entry (active / monthly / discontinued, last
build date) are produced separately by
[`tool/sync_freshness.dart`](tool/sync_freshness.dart), which falls back
to a curated seed when an upstream source is unreachable and ships the
result in `assets/freshness.json`.

The cache lives under `tool/.cache/` and is gitignored.

### Automation

The repo runs the following GitHub Actions so the catalog stays honest
without maintainer babysitting:

- **[`ci.yml`](.github/workflows/ci.yml) + [`check_catalog_drift.dart`](tool/check_catalog_drift.dart)** - every PR re-runs `sync_catalog.dart` and fails if the committed `assets/catalog.json` no longer matches what the script would produce. If it drifts, regenerate and commit.
- **[`sync-catalog.yml`](.github/workflows/sync-catalog.yml)** - weekly job that re-runs the catalog sync against fresh upstream YAMLs and opens a PR if anything changed (new devices, new branches, etc.).
- **[`sync-freshness.yml`](.github/workflows/sync-freshness.yml)** - nightly job that re-runs `sync_freshness.dart` so the in-app freshness chips stay current.
- **[`defunct-watch.yml`](.github/workflows/defunct-watch.yml) + [`check_defunct_activity.dart`](tool/check_defunct_activity.dart)** - scheduled job that watches the upstream orgs of every shipped ROM and opens an issue if a project goes quiet, so it can be moved to the defunct list before users notice.
- **[`check-screenshots.yml`](.github/workflows/check-screenshots.yml) + [`check_screenshot_urls.dart`](tool/check_screenshot_urls.dart)** - weekly HEAD-checks every screenshot URL so 404s and non-image responses are caught before users see broken tiles. Run it locally with `dart run tool/check_screenshot_urls.dart`.
- **[`auto-tag.yml`](.github/workflows/auto-tag.yml) + [`release.yml`](.github/workflows/release.yml)** - bumping `version:` in `pubspec.yaml` on `main` is the entire release flow (see [Releasing](#releasing)).
- **[`discord-notify.yml`](.github/workflows/discord-notify.yml)** - posts to a webhook on every published release.

## Android App Links

Every page has a stable URL (see the [deep links table](README.md#deep-links) in
the README). To enable Android App Links on your own domain, add an
intent-filter to `android/app/src/main/AndroidManifest.xml` inside the main
`<activity>`:

```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="https" android:host="customrr.example.com" />
</intent-filter>
```

Then host an `assetlinks.json` file at
`https://customrr.example.com/.well-known/assetlinks.json` containing the app's
SHA-256 signing fingerprint. See the
[Android App Links docs](https://developer.android.com/training/app-links/verify-android-applinks)
for full details.

## Linux desktop

Custom RR also builds and runs as a native Linux app. Prereqs (Debian/Ubuntu):

```bash
sudo apt-get install -y clang cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev libstdc++-12-dev
flutter config --enable-linux-desktop
flutter build linux --release
```

The release bundle ends up in `build/linux/x64/release/bundle/`. To
register the app with your desktop environment (menu entry + icon) use
the helper:

```bash
cd linux
./install.sh
```

It copies `io.github.monsiu.custom_rr.desktop` to
`~/.local/share/applications/` and points it at the built binary.
Prebuilt Linux tarballs (`custom_rr-vX.Y.Z-linux-x64.tar.gz`) are
attached to every GitHub release by the `build-linux` job.

## Windows desktop

Custom RR builds and runs as a native Windows app. Prereqs: a recent
Visual Studio with the "Desktop development with C++" workload (the same
toolchain Flutter docs require). Then:

```powershell
flutter config --enable-windows-desktop
flutter build windows --release
```

The release folder ends up in `build\windows\x64\runner\Release\` and is
fully portable: zip the folder, drop it anywhere, and double-click
`Custom_RR.exe`. No installer, no admin rights. Prebuilt Windows zips
(`custom_rr-vX.Y.Z-windows-x64.zip`) are attached to every GitHub release
by the `build-windows` job.

## macOS desktop

> **Help wanted: macOS testers.** The macOS build compiles from the same
> Flutter source as the Linux and Windows apps, but it has **not yet been
> verified on real Apple hardware**, and it ships **unsigned** (no code
> signing or notarization, which need a paid Apple Developer account). If
> you run it on an Apple Silicon or Intel Mac, please report back on the
> [tracker](https://github.com/monsiu/Custom-RR/issues) or the Discord:
> does it launch, does the catalog load, do screenshots and the update
> check work, and which macOS version you're on. Signing/notarization help
> is very welcome.

Custom RR builds and runs as a native macOS app (universal: Apple Silicon
and Intel in one binary). It needs **macOS 10.15 (Catalina) or newer**.
Prereqs: Xcode and its command-line tools. Then:

```bash
flutter config --enable-macos-desktop
flutter build macos --release
```

The `.app` bundle ends up in `build/macos/Build/Products/Release/`. Drag it
to your Applications folder to install. Prebuilt universal zips
(`custom_rr-vX.Y.Z-macos-universal.zip`) are attached to every GitHub
release by the `build-macos` job.

The published build is **unsigned** for now (code signing + notarization
need a paid Apple Developer account), so Gatekeeper blocks it on first
launch. To open it:

- **macOS 14 and earlier:** right-click (or Control-click) the app and
  choose **Open**, then confirm once.
- **macOS 15 (Sequoia) and newer:** double-click it, then go to **System
  Settings -> Privacy & Security**, scroll down, and click **Open Anyway**.

You only have to do this once per download.
