# Local screenshots (optional)

The app currently loads ROM/recovery screenshots from remote URLs.
To bundle screenshots locally and stop depending on third-party CDNs,
drop PNG/WEBP files in this directory using the naming scheme:

```text
{entryId}_1.png
{entryId}_2.png
...
```

where `{entryId}` matches the `id` field in `lib/data.dart`
(e.g. `havoc_1.png`, `lineage_1.png`).

Then add the assets folder to `pubspec.yaml`:

```yaml
flutter:
  assets:
    - images/
    - assets/screenshots/
```

The catalog already prefers remote URLs; switch entries in `lib/data.dart`
to local paths by replacing the `https://...` strings with
`assets/screenshots/havoc_1.png` etc.
