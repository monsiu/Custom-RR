# Custom RR

_By [Monsiu](https://github.com/monsiu) · [github.com/monsiu/Custom-RR](https://github.com/monsiu/Custom-RR)_

<p align="left">
  <a href="https://github.com/monsiu/Custom-RR/releases/tag/v1.1.0"><img alt="Release" src="https://img.shields.io/github/v/release/monsiu/Custom-RR?style=flat-square&amp;label=Release&amp;color=7ed957"></a>
  <a href="https://github.com/monsiu/Custom-RR/releases"><img alt="Downloads" src="https://img.shields.io/github/downloads/monsiu/Custom-RR/total?style=flat-square&amp;label=Downloads&amp;color=7ed957"></a>
  <a href="https://github.com/monsiu/Custom-RR/stargazers"><img alt="Stars" src="https://img.shields.io/github/stars/monsiu/Custom-RR?style=flat-square&amp;label=Stars&amp;color=ffd43b"></a>
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/License-GPL--3.0--only-blue?style=flat-square"></a>
  <a href="https://discord.gg/uWZR8vR855"><img alt="Discord" src="https://img.shields.io/badge/Discord-Join-5865F2?style=flat-square&amp;logo=discord&amp;logoColor=white"></a>
</p>

<p align="left">
  <a href="https://github.com/monsiu/Custom-RR/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/monsiu/Custom-RR/ci.yml?branch=main&amp;style=flat-square&amp;label=CI&amp;logo=github"></a>
  <a href="https://flutter.dev"><img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.44.0-02569B?style=flat-square&amp;logo=flutter&amp;logoColor=white"></a>
  <img alt="Android" src="https://img.shields.io/badge/Android-7.0%2B-3DDC84?style=flat-square&amp;logo=android&amp;logoColor=white">
  <img alt="Platforms" src="https://img.shields.io/badge/Platforms-Android%20%7C%20Linux%20%7C%20Windows%20%7C%20macOS-444444?style=flat-square">
</p>

<p align="left">
  <img alt="ROMs" src="https://img.shields.io/badge/ROMs-18-7ed957?style=flat-square">
  <img alt="Recoveries" src="https://img.shields.io/badge/Recoveries-5-7ed957?style=flat-square">
  <img alt="Devices" src="https://img.shields.io/badge/Devices-500%2B-7ed957?style=flat-square">
  <img alt="Treble GSIs" src="https://img.shields.io/badge/Treble-GSIs-7ed957?style=flat-square">
</p>

A single home for popular **custom ROMs** and **custom recoveries**, with direct links to the official builders, screenshots, freshness signals, and step-by-step flashing instructions. **18 actively maintained ROMs**, **5 recoveries**, **500+ devices**, all sourced live from the LineageOS wiki + the PixelOS `official_devices` repo and refreshed nightly.

![Custom RR banner](images/readme/banner.png)

> ## Help launch Custom RR on Google Play, become a tester
>
> Custom RR is in **closed testing** on Google Play, and Google needs a group of
> testers before it can go live to everyone. **You can help it launch in three
> quick steps**, and you get the app early:
>
> 1. **Sign in to your Google account**, the same one you use on your phone.
> 2. **Join the testers group:** open [groups.google.com/g/custom-rr-play-testers](https://groups.google.com/g/custom-rr-play-testers) and click **Join group** (viewing the group does not make you a tester, you have to actually join).
> 3. **Opt in and install:** open [play.google.com/apps/testing/io.github.monsiu.custom_rr](https://play.google.com/apps/testing/io.github.monsiu.custom_rr), accept the invite, then get it on the [Play Store](https://play.google.com/store/apps/details?id=io.github.monsiu.custom_rr).
>
> Use the **same Google account** for all three steps, or Play will say you are
> not a tester. Access can take a little while to propagate after you join. The
> more testers who stay opted in, the sooner Custom RR reaches the public Play
> Store. Thank you!
>
> Prefer not to use Google Play? Grab the APK straight from
> [GitHub Releases](https://github.com/monsiu/Custom-RR/releases) or wait for
> [F-Droid](https://f-droid.org/). Questions? [Join the Discord](https://discord.gg/uWZR8vR855).

## Features

- **Curated Custom ROMs.** LineageOS, crDroid, PixelOS, Project Elixir, Evolution X, DerpFest, UN1CA, BlissROMs, /e/, GrapheneOS, CalyxOS, DivestOS, RisingOS Revived, VoltageOS, and more, each with description, features, screenshots, and a one-tap link to the official download page.
- **Curated Custom Recoveries.** TWRP, OrangeFox, PBRP, SHRP, with per-device support and direct downloads.
- **Defunct projects clearly marked.** ArrowOS, DotOS, Havoc-OS, PotatoAOSP, RisingOS (original), MoKee, RR, AOSPE, Dirty Unicorns, Octavi OS are listed in an archived section with last-build date and successor suggestions, so users do not flash code that hasn't shipped in years.
- **Project warning banners.** Per-entry warnings call out community-relevant concerns (for example the 2024 Project Elixir killswitch incident) so users get the context before they flash.
- **Device → Compatible Builds.** Pick your phone and the whole app filters to ROMs and recoveries that officially support it, with per-phone-model chips for every supported device.
- **Brand pages.** Tap Xiaomi, OnePlus, Samsung, Google Pixel, Realme, POCO, Nothing, etc. and see every device + every ROM/recovery that targets that brand.
- **Treble & GSI hub.** Per-project status badges, direct GSI downloads, the canonical TrebleDroid wiki index, an A-only vs A/B + arm64 vs arm32_binder64 cheat sheet, a 6-step flash flow, and a "GSI boots but camera is broken" FAQ.
- **Freshness signals on every entry.** Active / monthly / discontinued labels plus last-build date, refreshed nightly by a GitHub Action that flags projects going quiet.
- **Always-current remote catalog.** The catalog lives on `raw.githubusercontent.com`, and the app refreshes from it on launch, so new ROMs, recoveries, devices, links, and freshness dates appear the moment they are published, with no app or store update required. The bundled `assets/catalog.json` is only a fallback that keeps the app fully usable offline.
- **Clickable link chips on every detail page** (Telegram, GitHub, Discord, Matrix, forum, web) sourced from a curated `links` field in the catalog.
- **"How to flash" guides** for ROMs and recoveries, embedded per category, no wiki digging.
- **Deep links / shareable URLs** for every ROM, recovery, device, and brand (powered by `go_router`), easy to drop in XDA threads.
- **GitHub-release update check** against GitHub Releases, with one-tap APK download + install on Android in GitHub release builds. Store builds leave updates to the store.
- **Bundled pinch-zoom image viewer** for screenshots.
- **Material 3 + dynamic color.** Light / dark / AMOLED themes, adaptive layouts (drawer on phones, NavigationRail on tablets, permanent side panel on desktop), theme + accent persisted across launches.
- **In-app privacy policy page** rendered from the bundled [`PRIVACY.md`](PRIVACY.md).
- **Zero tracking, zero ads, no Play Services, GPL-3.0**, source on GitHub.
- **Cross-platform.** Android 7.0+ (minSdk 24, target Android 16 / SDK 36), Linux desktop, Windows desktop, and macOS desktop (10.15 Catalina or newer, universal Apple Silicon + Intel).

## Roadmap

- Localisation (`flutter_localizations` + ARB)
- Crash & analytics (Sentry or Firebase Crashlytics)
- Unofficial / community-maintained build listings
- Dedicated Magisk install section
- Auto-update for the Linux, Windows, and macOS desktop builds

## Deep links

Every page has a stable URL. Examples:

| URL                  | Page                                |
| -------------------- | ----------------------------------- |
| `/`                  | Home                                |
| `/roms`              | All ROMs                            |
| `/roms/lineage`      | LineageOS detail page               |
| `/recoveries`        | All recoveries                      |
| `/recoveries/twrp`   | TWRP detail page                    |
| `/devices`           | All devices                         |
| `/devices/xiaomi`    | Xiaomi-compatible ROMs & recoveries |
| `/treble`            | Treble / GSI hub                    |

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
- **[`auto-tag.yml`](.github/workflows/auto-tag.yml) + [`release.yml`](.github/workflows/release.yml)** - bumping `version:` in `pubspec.yaml` on `main` is the entire release flow. `auto-tag.yml` pushes a matching `vX.Y.Z` tag, which triggers `release.yml` to build the Android per-ABI APKs, the Linux tarball, and the Windows zip, then publish a draft release with auto-generated notes.
- **[`discord-notify.yml`](.github/workflows/discord-notify.yml)** - posts to a webhook on every published release.

## Build from source

```bash
git clone https://github.com/monsiu/Custom-RR.git
cd Custom-RR
flutter pub get
flutter run
```

**Requirements**: Flutter 3.22+, Dart 3.4+, Java 17, Android SDK 36 (compile/target), minSdk 24.

For reproducible builds, this repo ships a [`.fvmrc`](.fvmrc); use [fvm](https://fvm.app) to pin the Flutter version automatically.

## Releasing

Release builds expect signing config in `android/key.properties` (see [`android/key.properties.template`](android/key.properties.template)). Without it, release builds fall back to debug signing for local testing.

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
> you run it on an Apple Silicon or Intel Mac, please report back: does it
> launch, does the catalog load, do screenshots and the update check work,
> and which macOS version you're on. Open an issue on the
> [tracker](https://github.com/monsiu/Custom-RR/issues) or ping the Discord.
> Bug reports and signing/notarization help are very welcome.

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

## Support the project

[![Buy Me a Coffee](https://cdn.buymeacoffee.com/buttons/v2/arial-yellow.png)](https://www.buymeacoffee.com/monsiutech)

### Crypto donations

Same addresses shipped in the app. Listing them here too so donors can
cross-check the in-app values against an out-of-band source before
sending funds.

| Coin | Address |
| ---- | ------- |
| **BTC** (Bitcoin, P2WPKH) | `bc1qaxx6dxkz0s5cw4h9nysw4yvmsaf3qlk7j0gwa2` |
| **BTC Lightning** | `monsiutech@cake.cash` |
| **LTC** (Litecoin, P2WPKH) | `ltc1qdrjqjzk0sfn7grysxruxuuev6jpn9yqm8wrrg0` |
| **ETH** / EVM (mainnet) | `0x4e815A295F8096997867FBA2d7bDC6316ad970be` |
| **BNB** Smart Chain (also accepts ETH, USDT, USDC on BSC) | `0x4aCD5AD66DD8E64e3117d9cb0CB0434294027CDd` |
| **SOL** (Solana) | `6qC53PkKjoFtyhohHnYFApf3YccZwULFLTfrUMiruM97` |
| **XMR** (Monero) | `8ADyd3DvN5D6wAauq2Q2BSZp7aG3LhYZAFswk5dNQohVUBDT8G84MjPimsj5vzfB8TBrwtC3y3BATNm76bX21kWfUys3ehE` |

Have a different coin? Use the in-app **Swap to XMR** button (powered by
[Trocador AnonPay](https://trocador.app/anonpay/), no account, no KYC).

## Socials

[![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/monsiu)
[![Discord](https://img.shields.io/badge/Discord-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/uWZR8vR855)
[![Telegram](https://img.shields.io/badge/Telegram-26A5E4?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/monsiu)
[![Twitter / X](https://img.shields.io/badge/Twitter-000000?style=for-the-badge&logo=x&logoColor=white)](https://twitter.com/MonsiuTech)
[![YouTube](https://img.shields.io/badge/YouTube-FF0000?style=for-the-badge&logo=youtube&logoColor=white)](https://www.youtube.com/@monsiutech)

## Contact

Bug report, feature request or just want to say hi?

- Open an [issue on GitHub](https://github.com/monsiu/Custom-RR/issues) (preferred for anything code- or catalog-related).
- Email: [contactmonsiu@gmail.com](mailto:contactmonsiu@gmail.com)
- Telegram: [@monsiu](https://t.me/monsiu)

## License

Released under the **GNU General Public License v3.0 only** (`SPDX-License-Identifier: GPL-3.0-only`). See the [LICENSE](LICENSE) file for the full text.

## Catalog sources

Custom RR's catalog is regenerated by [`tool/sync_catalog.dart`](tool/sync_catalog.dart) from a small set of authoritative upstream sources. Credit and thanks to the maintainers of:

- [LineageOS wiki](https://github.com/LineageOS/lineage_wiki) - the canonical device list, used as the base for the Devices section and most ROM device support.
- [PixelOS-AOSP/official_devices](https://github.com/PixelOS-AOSP/official_devices) - the authoritative PixelOS device list, fetched live so the catalog reflects the current branch.
- [TrebleDroid/treble_experimentations wiki](https://github.com/TrebleDroid/treble_experimentations/wiki/Generic-System-Image-%28GSI%29-list) - the canonical cross-project Treble GSI index.
- Per-ROM download portals (LineageOS, crDroid, PixelOS, Project Elixir, Evolution X, DerpFest, UN1CA, BlissROMs, /e/ Foundation, GrapheneOS, CalyxOS, DivestOS, RisingOS, VoltageOS, and others) for download URLs and screenshots.

If a project you maintain is misrepresented here, [open an issue](https://github.com/monsiu/Custom-RR/issues) and it will be corrected.

## Stargazers over time

[![Stargazers over time](https://starchart.cc/monsiu/Custom-RR.svg?variant=adaptive)](https://starchart.cc/monsiu/Custom-RR)
