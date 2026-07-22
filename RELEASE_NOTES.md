## Custom RR v1.3.3

This release makes the flash script generator brand-aware, adds a Rate option
and GitHub Sponsors support, and points sharing at Google Play.

### Added

- **Sponsor on GitHub.** You can now back Custom RR through GitHub Sponsors from
  the home support prompt, the About page, and the support dialogs.
- **Rate the app.** A gentle, dismissible prompt on Google Play builds invites a
  rating, and a "Rate Custom RR" option is always on the About page.

### Changed

- **Sharing points to Google Play.** "Share the app" now links the Google Play
  listing.
- **About page tidied.** Removed the redundant Play status card and added a
  one-tap "Check for updates" that opens the Play listing.

### Fixed

- **Flash script generator is now brand-aware.** Samsung uses Download mode with
  Heimdall or Odin, Xiaomi, Redmi and POCO include Mi Unlock and anti-rollback
  warnings, Motorola and Sony include their unlock-code steps, realme and OPPO
  include Deep Testing, and other brands use standard fastboot unlock, replacing
  the old one-size-fits-all steps that could not work on some devices.

See the full diff and commit log via the **Full Changelog** link below.
