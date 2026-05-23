# Custom RR

_By [Monsiu](https://github.com/monsiu) · [github.com/monsiu/Custom-RR](https://github.com/monsiu/Custom-RR)_

[![CI](https://github.com/monsiu/Custom-RR/actions/workflows/ci.yml/badge.svg)](https://github.com/monsiu/Custom-RR/actions/workflows/ci.yml)
[![License](https://img.shields.io/github/license/monsiu/Custom-RR)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.22+-02569B?logo=flutter)](https://flutter.dev)

A single home for popular **custom ROMs** and **custom recoveries**, with direct links to the official builders, screenshots, and step-by-step flashing instructions.

<p align="center">
  <img src="https://user-images.githubusercontent.com/69597591/216198899-3a02066b-c9a8-426f-a6cd-740e5a2fc641.png" alt="Custom RR logo" width="180">
</p>

## Features

- Browse curated Custom ROMs (LineageOS, crDroid, Havoc, Pixel Experience, ParanoidAndroid, Evolution X, ArrowOS, dotOS, Bliss, PotatoAOSP, RisingOS, Voltage OS, Project Elixir…).
- Browse curated Custom Recoveries (TWRP, OrangeFox, PitchBlack, RedWolf, SHRP).
- **Device → Compatible Builds:** pick a manufacturer to see only the ROMs and recoveries that list it as supported, with per-phone-model chips for every supported device.
- **Deep links / shareable URLs** for every ROM, recovery, and device (powered by `go_router`).
- One tap to open the official download page.
- “How to flash” guides for ROMs and recoveries.
- Adaptive Material 3 layout: drawer on phones, NavigationRail on tablets, permanent side panel on desktop.
- Light / dark / system theme picker that persists across launches.

## Roadmap

- Localisation (`flutter_localizations` + ARB)
- Crash & analytics (Sentry or Firebase Crashlytics)
- Remote-fetched catalog with offline cache
- Unofficial / community-maintained build listings
- Dedicated Magisk install section
- Bundled (offline) screenshots

## Deep links

Every page has a stable URL. Examples:

| URL              | Page                                          |
| ---------------- | --------------------------------------------- |
| `/`              | Home                                          |
| `/roms`          | All ROMs                                      |
| `/roms/lineage`  | LineageOS detail page                         |
| `/recoveries`    | All recoveries                                |
| `/recoveries/twrp` | TWRP detail page                            |
| `/devices`       | All devices                                   |
| `/devices/xiaomi`| Xiaomi-compatible ROMs & recoveries           |

To enable Android App Links on your own domain, add an intent-filter to `android/app/src/main/AndroidManifest.xml` inside the main `<activity>`:

```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="https" android:host="customrr.example.com" />
</intent-filter>
```

Then host an `assetlinks.json` file at `https://customrr.example.com/.well-known/assetlinks.json` containing the app's SHA-256 signing fingerprint. See the [Android App Links docs](https://developer.android.com/training/app-links/verify-android-applinks) for full details.

## Updating the catalog

The shipped `assets/catalog.json` is generated from the upstream
[LineageOS wiki](https://github.com/LineageOS/lineage_wiki) device YAMLs by
`tool/sync_catalog.dart`. Each ROM/recovery's `devices` list is filtered
by a per-project policy (vendor whitelist + minimum LineageOS branch /
release year). To refresh:

```bash
dart run tool/sync_catalog.dart            # use cached YAMLs in tool/.cache/
dart run tool/sync_catalog.dart --refresh  # re-download the wiki tarball
```

The cache lives under `tool/.cache/` and is gitignored.

## Build from source

```bash
git clone https://github.com/monsiu/Custom-RR.git
cd Custom-RR
flutter pub get
flutter run
```

**Requirements**: Flutter 3.22+, Dart 3.4+, Java 17, Android SDK 36 (compile/target), minSdk 21.

For reproducible builds, this repo ships a [`.fvmrc`](.fvmrc); use [fvm](https://fvm.app) to pin the Flutter version automatically.

## Releasing

Release builds expect signing config in `android/key.properties` (see [`android/key.properties.template`](android/key.properties.template)). Without it, release builds fall back to debug signing for local testing.

```bash
flutter build apk --release
flutter build appbundle --release
```

## Support the project

[![Buy Me A Coffee](https://cdn.buymeacoffee.com/buttons/v2/arial-red.png)](https://www.buymeacoffee.com/monsiuYT)

## Socials

- [GitHub](https://github.com/monsiu)
- [Discord](https://discord.gg/BrH25zwVAG)
- [Twitter / X](https://twitter.com/monsiuyt)
- [YouTube](https://www.youtube.com/monsiu)

## License

Released under the terms of the [LICENSE](LICENSE) file in this repo.
