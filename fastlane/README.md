# Fastlane metadata

This folder provides text and image metadata consumed by F-Droid and
IzzyOnDroid (and any other store that follows the
[fastlane structure](https://docs.fastlane.tools/getting-started/android/setup/)).

## Layout

```
fastlane/
  metadata/
    android/
      en-US/
        title.txt
        short_description.txt
        full_description.txt
        changelogs/
          <versionCode>.txt
        images/
          icon.png
          phoneScreenshots/
            01.png
            02.png
            ...
          (optional) sevenInchScreenshots/
          (optional) tenInchScreenshots/
          (optional) featureGraphic.png
```

## What is still missing

- `images/icon.png` (512x512 launcher icon, PNG, no transparency).
- `images/phoneScreenshots/*.png` (at least 1, recommended 4-8). Take
  these from a clean device or emulator at typical phone resolution.
- Optionally `images/featureGraphic.png` (1024x500) for a hero banner
  on F-Droid listing.

Drop them in and the listing will pick them up on next ingestion. The
text files in `en-US/` are the source of truth for the listing copy;
do not edit them from inside the app.

## Notes

- Keep the `versionCode` filename in `changelogs/` aligned with the
  `+N` in `pubspec.yaml` (e.g. `0.2.0+3` -> `changelogs/3.txt`).
- IzzyOnDroid mirrors APKs straight from GitHub Releases, so make
  sure each release ships a signed APK in the release assets.
