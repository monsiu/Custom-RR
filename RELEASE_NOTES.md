## Custom RR v1.1.0

This release expands the catalog and makes browsing clearer, especially for
community-maintained builds and Samsung Galaxy S24 Ultra users.

### Highlights

- **Unofficial builds are now clearly grouped.** Community-maintained builds now
  appear in a dedicated section on the Custom ROMs list, with an explainer and
  a quick info button.
- **Galaxy S24 Ultra support lands.** Two requested entries are now in the
  catalog:
  - **LineageOS for S24 Ultra (Unofficial)** with builds, install links,
    source, and screenshots.
  - **Dr.Ketan ROM** for SM-S928B/DS.
- **AndyYan's LineageOS 21 pre-QPR2 GSI** was added to Treble & GSI with direct
  download links and the XDA thread.
- **Catalog cards read better.** Counts now use proper wording, and brands that
  only have recoveries no longer show a confusing "0 ROMs" label.
- **GitHub updater behavior is now explicit by channel.** Source builds keep
  updater code disabled by default; GitHub release builds keep in-app update
  support, while store builds rely on their own update channels.

### Privacy and policy

- The privacy policy now explicitly separates website analytics from app
  behavior. The app itself still has no analytics or tracking.

### Android distribution note

- The Play build manifest now removes transitive media/storage permissions from
  an updater dependency that is not used in Play builds.

### Cleanup

- Removed the empty ARK brand entry.
- Merged duplicate 10.or/10or branding.

See the full diff and commit log via the **Full Changelog** link below.
