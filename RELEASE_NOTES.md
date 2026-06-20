## Custom RR v1.3.0

This release opens Custom RR up to thousands of community ROM builds, adds a new
privacy ROM and a GSI flashing mode, and makes the whole app's artwork lighter
and always up to date.

### Highlights

- **Community builds (OpenDesktop integration).** A new Community builds screen
  brings in thousands of community ROM uploads from OpenDesktop's Phone ROMs
  catalog, with search and sorting by downloads, newest, or rating. Every build
  shows the device codenames it targets, and listings are clearly marked as
  unvetted, third-party uploads that open on their original page.
- **Right on your device and brand pages.** Each device page now shows the
  matching unofficial community builds for that exact model in their own
  section, with a clear "not vetted" warning and a shortcut to browse them all.
  Brand pages (for example Xiaomi) show the same section for the whole maker.
- **AXP.OS joins the catalog.** Added AXP.OS, a privacy and security hardened
  ROM (the successor to DivestOS) with Slim and Pro flavors, covering Fairphone,
  Pixel, OnePlus, LG, Samsung, and Sony devices.
- **GSI / Treble mode in the flash script generator.** A new toggle builds a
  generic system image flashing script for Treble devices, with the right steps
  for Samsung and for other phones and tablets.
- **The full official TWRP device list.** The TWRP page now lists the complete
  official TWRP device roster across dozens of brands, and many more device
  brands show their real logo on the Devices grid.
- **Filter by your selected device.** The ROMs and Recoveries lists can be
  narrowed to just the entries that match the device you have selected.
- **Join the Play beta from the app.** A new home-screen invite and a
  step-by-step page explain how to become a Google Play tester and get early
  builds. It can be dismissed and stays available from the About page.

### Refinements

- **Lighter, always-current artwork.** Brand and ROM logos now load from the
  online catalog and are cached on your device, so new or corrected logos appear
  without an app update, delivered through a content delivery network for
  quicker, more reliable loading. A subtle shimmer placeholder shows while
  images load.
- **Socials in About.** The About page now has a Socials option linking to
  Twitter / X, Telegram, and YouTube.

### Fixes

- A placeholder phone icon no longer shows through transparent brand logos, and
  a missing logo falls back cleanly to the generic placeholder.
- Long device names no longer overflow their chips on detail and device pages.
- Fixed cramped action buttons on the My Devices cards.
- Tapping About in the navigation menu now opens the full About page instead of
  a small popup.

See the full diff and commit log via the **Full Changelog** link below.
