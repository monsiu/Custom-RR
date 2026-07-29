# Microsoft Store: native Windows release runbook

How to ship Custom RR as a **native Flutter Windows app (MSIX)** on the Microsoft Store,
distilled from taking ClauseShift through the exact same pipeline (PWA first, then a
native MSIX that passed certification). Every gotcha below was hit for real; follow the
order and you skip all of them.

Current Custom-RR status (2026-07-27, repo side DONE):

- `windows/` scaffold EXISTS and is branded (window title "Custom RR",
  `Runner.rc` CompanyName/ProductName set; `OriginalFilename` fixed to
  `Custom_RR.exe`). `BINARY_NAME` is `Custom_RR`. `app_icon.ico` regenerated
  multi-size (256/128/64/48/32/16) from `images/generated/launcher_full.png`.
- The APK self-updater already gates itself off (`update_installer.dart`:
  `kSelfUpdateEnabled && !kIsWeb && Platform.isAndroid`), so the Windows build
  ships no self-update path. That is exactly what the Store wants.
- No billing SDKs in this app, so there is nothing to strip (ClauseShift had to
  strip Play/Huawei/Amazon IAP per channel; we skip that whole class of work).
- `msix` 3.18.0 IS a dev dependency with the `msix_config` block from section
  2.3, and `.github/workflows/msstore.yml` exists (build -> patch
  BackgroundColor -> pack, msix + unpackaged-zip artifacts, self-signed
  fallback while the identity variables are unset).
- Partner Center product CREATED 2026-07-27 as "MSIX or PWA app": **Store ID
  `9NTS7Q5V12RG`**, names reserved `Custom RR` (dashboard name) + `Custom RR:
  ROMs & Recovery`. Identity: `Package/Identity/Name = MonsiuTech.CustomRR`,
  `Package/Identity/Publisher = CN=9B88F9CA-9E86-4631-ADD8-3CF8DE54C531`,
  PublisherDisplayName `Monsiu Tech`. PFN `MonsiuTech.CustomRR_der63fajnrhfp`.
  Store URL `https://apps.microsoft.com/detail/9NTS7Q5V12RG`. Repo variables
  `MSIX_IDENTITY_NAME` + `MSIX_PUBLISHER` are SET.
- REMAINING: push the repo-side changes, dispatch the workflow, smoke test,
  submit (section 5).

---

## 0. The big picture

1. Partner Center: create the product (RIGHT TYPE), reserve the name, read the
   3 identity values.
2. Repo: add the `msix` packager + `msix_config` to `pubspec.yaml`, set the two
   repo variables, add a `msstore.yml` workflow that builds a store-signed MSIX
   on `windows-latest`.
3. Smoke test the unpackaged zip artifact on a real Windows machine.
4. Partner Center: upload the MSIX, fill the submission sections, submit.
5. Certification: hours to 3 business days. Then it is live.

Cost: $0 beyond the one-time Store developer registration (already done for
"Monsiu Tech", Seller ID 95197540). CI minutes: a Windows MSIX build run costs
roughly 2x a Linux minute-for-minute (~$0.50/run on a private repo; Custom-RR is
public so Actions are free).

---

## 1. Partner Center product setup (one-time)

Account facts (same account as ClauseShift):

- Registration is FREE via the new flow at `storedeveloper.microsoft.com` ONLY
  (other entry points still show the legacy paid flow). Individual account needs
  gov-ID + selfie verification.
- Publisher display name: **Monsiu Tech**. Windows publisher ID GUID
  `6eb8757f-ed60-490e-9724-203c9826162d`.

Steps:

1. Partner Center > Apps and games > New product > **"MSIX or PWA app"**.
   **HICCUP (cost ClauseShift days):** do NOT pick "EXE or MSI app". That type
   has no MSIX package identity and its Store ID ("bigId") stays `null` forever;
   the Product Identity page just errors. ClauseShift had to delete the win32
   draft and recreate as MSIX/PWA, which instantly minted the Store ID.
2. Reserve the app name (e.g. `Custom RR`). The name-reservation input is an
   Angular reactive form: if automating, set the value via the native value
   setter + dispatch input/change/blur; plain clicks/typing time out.
   - Reserve EVERY display name the package might carry. ClauseShift got the
     validation error "manifest uses a display name that you have not reserved"
     because the manifest said `ClauseShift` while only "ClauseShift: Contract
     Review" was reserved. Reserve both the short and long forms up front
     (Manage app names page). A fresh reservation does NOT propagate to an
     already-open submission's validator: delete + re-upload the package to
     force re-validation.
3. On a brand-new account/product the Store ID can take 24-48h to mint even
   after verification shows Authorized. Nothing unblocks it; just wait.
4. Open Product management > **Product identity** and copy the 3 values:
   - `Package/Identity/Name` (e.g. `MonsiuTech.CustomRR`)
   - `Package/Identity/Publisher` (e.g. `CN=9B88F9CA-9E86-4631-ADD8-3CF8DE54C531`)
   - `Package/Properties/PublisherDisplayName` (e.g. `Monsiu Tech`)

Set the first two as GitHub **repo variables** (they are public manifest values,
not secrets):

```
gh variable set MSIX_IDENTITY_NAME -R monsiu/Custom-RR --body "MonsiuTech.CustomRR"
gh variable set MSIX_PUBLISHER     -R monsiu/Custom-RR --body "CN=9B88F9CA-..."
```

---

## 2. App-side prep

### 2.1 Desktop-hostile plugins

Audit every plugin for a Windows implementation and make sure mobile-only
features self-gate instead of crashing:

- Custom RR: `open_filex`, `dio`, `device_info_plus` all have Windows support;
  the updater is Android-gated already. `share_plus` works on Windows (share
  dialog); if any share/save path feels wrong on desktop, prefer a save-file
  dialog on desktop and the share sheet on mobile (ClauseShift added a
  `FileExport.saveOrShare` helper for this).
- **HICCUP (build breaker):** if the app ever adds `local_auth`, its
  `local_auth_windows` package uses `<experimental/coroutine>` which the current
  MSVC STL rejects (hard error STL1011). Fix in `windows/CMakeLists.txt`:
  `add_compile_definitions(_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS)`
  (it propagates to plugin subprojects). Not needed today; keep for reference.
- After dependency bumps, `windows/flutter/generated_plugins.cmake` can gain new
  Windows FFI plugin entries (ClauseShift hit this with
  `flutter_local_notifications` 22). Regenerate + commit it; harmless when the
  Dart side no-ops off Android.

### 2.2 Branding polish (windows/)

- `windows/CMakeLists.txt`: `BINARY_NAME` (currently `Custom_RR`; the exe name
  users see in Task Manager).
- `windows/runner/Runner.rc`: CompanyName / ProductName / FileDescription /
  LegalCopyright, and fix `OriginalFilename` (`android.exe` -> `custom_rr.exe`).
- `windows/runner/main.cpp`: window title (already "Custom RR").
- App icon: `windows/runner/resources/app_icon.ico`. Build a multi-size .ico
  from the GREEN-BACKGROUND launcher art (a bare transparent robot renders
  dull/flat in the taskbar + title bar):
  `magick images/generated/launcher_windows.png -define icon:auto-resize=256,128,64,48,32,16 windows/runner/resources/app_icon.ico`
  where `launcher_windows.png` is the robot composited on the brand green
  (`magick -size 720x720 xc:'#7ed957' images/generated/launcher_full.png -gravity center -composite images/generated/launcher_windows.png`).
  NOTE: the .ico only affects the raw/unpackaged exe. An INSTALLED MSIX app
  draws window/taskbar/Start icons from the MSIX tile assets generated from
  `msix_config.logo_path` (section 2.3), so brand both - point logo_path at the
  same green `launcher_windows.png` so the Store tiles/taskbar icon match.

### 2.3 pubspec: msix packager

Add to `dev_dependencies`: `msix: ^3.16.8` (3.18.x also fine; see the
BackgroundColor hiccup below which applies to all current versions).

```yaml
msix_config:
  display_name: Custom RR
  publisher_display_name: Monsiu Tech        # see HICCUP below
  identity_name: io.github.monsiu.customrr   # placeholder; CI overrides
  msix_version: 1.3.3.0                      # placeholder; CI overrides
  logo_path: images/generated/launcher_windows.png  # green-bg (not the bare transparent robot)
  trim_logo: false                           # see HICCUP below
  capabilities: internetClient
  store: false                               # CI passes --store explicitly
  install_certificate: false                 # see HICCUP below
```

- **HICCUP (package validation rejection #1):** `publisher_display_name` must
  BYTE-MATCH the Partner Center account name. ClauseShift's package said
  "Monsiu Tech Solutions" while the account is "Monsiu Tech" and Partner Center
  rejected the upload with an explicit mismatch error. Use exactly
  `Monsiu Tech`.
- **HICCUP (ugly launcher tiles):** the msix package's `trim_logo` defaults to
  TRUE: it trims your icon's solid margin then zoom-fills the tile, producing
  clipped, aliased Start-menu tiles. Set `trim_logo: false`. Verify by unzipping
  the built `.msix` (it is a zip) and eyeballing `Images/*.png`.
- **HICCUP (CI hang):** on the self-signed test path, `msix:create` prompts
  interactively "install test certificate?" and exits 255 on CI. Set
  `install_certificate: false`.
- **HICCUP (blue tile plate / accent-colored install dialog):** the msix
  package HARDCODES `<uap:VisualElements BackgroundColor="transparent">` with no
  config knob. Windows then paints the App Installer hero field and Start tile
  plate with the user's ACCENT COLOR (often blue) behind your icon. Fix in CI:
  split `msix:create` into `msix:build` -> `sed` the generated
  `build/windows/x64/runner/Release/AppxManifest.xml`
  (`BackgroundColor="transparent"` -> your brand hex, e.g. `#7ED957`) ->
  `msix:pack`. This is safe: `pack` only checks the manifest exists, it does not
  regenerate it. Make the sed step FAIL LOUDLY if the "transparent" string is
  not found, so a package update cannot silently undo the patch.

### 2.4 Version mapping

MSIX versions are `A.B.C.D` with D reserved (must be 0 for Store) and every
submission must be strictly ascending. Map the pubspec version `X.Y.Z+N` to
`X.Y.Z.0` via the CLI `--version` flag (it overrides `msix_version`).

- ClauseShift extra wrinkle (does NOT apply here unless it happens): its PWA-era
  package was already `1.0.1.0`, so the native package had to map `0.1.14` ->
  `1.1.14.0` (major+1) to keep ascending. Custom RR starts fresh at
  `1.3.3.0`, so plain mapping works.

---

## 3. CI workflow (msstore.yml)

Dispatch-only workflow on `windows-latest`. Skeleton mirroring what shipped for
ClauseShift (adapted: no billing strips, no secret dart-defines needed):

```yaml
name: Microsoft Store

on:
  workflow_dispatch:
    inputs:
      tag:
        description: "Tag or ref to build (e.g. v1.3.3 or main)"
        required: true
        default: "main"

jobs:
  build:
    runs-on: windows-latest
    defaults: { run: { shell: bash } }
    steps:
      - uses: actions/checkout@v4
        with: { ref: "${{ inputs.tag }}" }
      - id: flutter_version
        run: echo "version=$(cat .flutter-version)" >> "$GITHUB_OUTPUT"
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ steps.flutter_version.outputs.version }}
          channel: stable
          cache: true
      - run: flutter pub get

      - name: Build Windows release
        run: flutter build windows --release

      - name: Package MSIX
        env:
          MSIX_IDENTITY_NAME: ${{ vars.MSIX_IDENTITY_NAME }}
          MSIX_PUBLISHER: ${{ vars.MSIX_PUBLISHER }}
        run: |
          VER=$(grep -m1 '^version:' pubspec.yaml | tr -d ' ' | cut -d: -f2)
          NAME=${VER%%+*}
          ARGS=(--version "${NAME}.0")
          if [ -n "$MSIX_IDENTITY_NAME" ] && [ -n "$MSIX_PUBLISHER" ]; then
            ARGS+=(--store --identity-name "$MSIX_IDENTITY_NAME" --publisher "$MSIX_PUBLISHER")
          fi
          # build -> patch BackgroundColor -> pack (see section 2.3)
          dart run msix:build "${ARGS[@]}"
          MANIFEST=build/windows/x64/runner/Release/AppxManifest.xml
          grep -q 'BackgroundColor="transparent"' "$MANIFEST" || { echo "manifest changed; revisit patch"; exit 1; }
          sed -i 's/BackgroundColor="transparent"/BackgroundColor="#7ED957"/' "$MANIFEST"
          grep -q 'BackgroundColor="#7ED957"' "$MANIFEST"
          dart run msix:pack "${ARGS[@]}"

      - name: Zip unpackaged build (smoke-test artifact)
        run: 7z a windows-unpackaged.zip ./build/windows/x64/runner/Release/*

      - uses: actions/upload-artifact@v4
        with:
          name: msstore-upload
          path: build/windows/x64/runner/Release/*.msix
      - uses: actions/upload-artifact@v4
        with:
          name: windows-unpackaged
          path: windows-unpackaged.zip
```

Notes and hiccups baked into that skeleton:

- **Two modes:** with the `MSIX_IDENTITY_NAME`/`MSIX_PUBLISHER` repo variables
  set, it produces a STORE package (`--store`, unsigned; the Store signs it).
  Without them it falls back to a self-signed test MSIX.
- **`--store` MSIX cannot be sideloaded.** `Add-AppxPackage` refuses it (no
  local trust). Do not waste time trying; smoke test another way (section 4).
- The **unpackaged zip** artifact is the smoke-test vehicle: an MSIX is a zip,
  and the Release folder is a complete runnable payload (exe +
  `flutter_windows.dll` + `data/` + plugin DLLs + bundled VC++ runtime).
- **Git Bash flag mangling:** if you ever call Windows SDK tools like
  `makeappx.exe` from a bash step, prefix with
  `MSYS2_ARG_CONV_EXCL="/o;/bv;/d;/p"` or Git Bash rewrites `/o`-style flags as
  paths. (Needed only if you must produce a `.msixbundle`; a plain `.msix` is
  fine for a first-ever submission. Only apps whose PREVIOUS submission shipped
  a bundle are forced to keep shipping bundles - that was a real ClauseShift
  rejection: "previous submission was released with a .msixbundle; subsequent
  submissions must continue to contain a bundle".)
- `makeappx.exe` location on runners: glob under
  `C:\Program Files (x86)\Windows Kits\10\bin\*\x64\makeappx.exe`; fallback:
  the msix pub package vendors a copy under its `Redist.x64` directory.
- Add the store dart-defines you need to the `flutter build windows` step.
  Custom RR probably wants none (do NOT pass `GITHUB_RELEASE_BUILD=true`; the
  Store distributes updates itself, same reasoning as the Play build).

---

## 4. Smoke test on Windows (before submitting)

1. Download the `windows-unpackaged` artifact on a Windows machine/VM.
2. Extract, run `custom_rr.exe` (or `Custom_RR.exe`) directly. No install, no
   certificate needed. SmartScreen will warn ("More info > Run anyway"); that is
   expected for an unsigned loose exe and does NOT happen to the Store install.
3. What differs from the packaged app: no Store identity/licensing, and any
   packaged-only behavior. Everything else (UI, network, catalog, deep links
   within the app) is faithful.
4. If you want to test the actual MSIX install UX (tiles, install dialog),
   build once WITHOUT the repo variables (self-signed test MSIX) and install
   that; you must trust the test cert or extract-and-run instead.
5. Verify the tile art: `unzip -o custom_rr.msix 'Images/*' -d /tmp/tiles` and
   check the PNGs are full-bleed brand color with the icon uncropped, and
   `AppxManifest.xml` has your `BackgroundColor` hex (not `transparent`).

---

## 5. Partner Center submission runbook

> The `msstore-upload` artifact is built **automatically on every release**
> (release.yml fans out to the Microsoft Store workflow), so a ready-to-upload
> `.msix` is always waiting - the only manual job is to download it and drop it
> into the submission below. To build one off-cycle, run the "Microsoft Store"
> workflow by hand (`gh workflow run msstore.yml --ref <tag>`).

Open the product > Start submission. Six sections must go green:

1. **Pricing and availability**: Free. All markets (default).
2. **Properties**: category (e.g. Utilities & tools). Product declarations:
   - Custom RR has NO generative AI, so the AI declaration stays unticked.
     (ClauseShift got FAILED under policy 11.16 for not declaring AI + not
     having an in-app "report AI content" affordance. Not applicable here, but
     if AI features ever land: tick the declaration AND ship a report path.)
3. **Age ratings**: IARC questionnaire, answer honestly. If asked for an
   existing IARC Global Rating ID on other storefronts later, note the IARC
   cert is per-product (ClauseShift's ID cannot be reused for Custom RR).
4. **Packages**: upload the `.msix` from the `msstore-upload` artifact.
   - Upload by drag or file input; if automating, `setInputFiles` on the
     `input[type=file]` works even though the dropzone is custom.
   - **HICCUP:** the checklist statuses on the overview render AFTER each
     section title (the "Incomplete" under "Packages" belongs to Packages).
   - **HICCUP:** the device-family table must match your package. Desktop only:
     make sure ONLY "Windows 10/11 Desktop" is checked. ClauseShift's Packages
     section sat "Incomplete" because a stale "Windows 10 Mixed Reality" row
     was checked from an older package.
   - **HICCUP:** a stale "Analyzing package" progress widget can pin Save
     disabled forever. RELOAD the page: uploads and removal marks persist
     server-side in the draft.
   - Min OS 10.0.17763 is what a current Flutter MSIX declares; leave it.
5. **Store listings**: description, 1+ screenshots (1920x1080 desktop shots
   look best; window-chrome mockups around real app screenshots read well),
   short description, "What's new".
   - **HICCUP (data loss):** clicking Save on the listings page BEFORE the form
     values hydrate WIPES description/What's new (saves empty strings over
     them). Wait for the form to populate, then save, then re-open and verify.
   - **HICCUP:** screenshot thumbnails process asynchronously with
     stuck-looking progress bars for ~2 min; judge completion by the
     "Desktop (N)" tab count, not the spinners.
   - **HICCUP (multi-language):** if your MSIX declares multiple languages,
     Partner Center spawns a listing slot per language, each "Incomplete".
     Either fill them all or remove the extra language listings and keep one
     neutral English listing (Manage languages). Custom RR is en-only today, so
     this should not trigger.
6. **Submission options**: the hidden required field that keeps this section
   "Incomplete" is the **runFullTrust justification**. Every desktop-bridge
   (Win32/Flutter) app carries the `runFullTrust` capability; write 1-2
   sentences: "Native Win32 desktop application built with Flutter; full trust
   is required to run the compiled desktop binary. The app only accesses the
   network and user-chosen files."
   - If the app ever takes payments through a third-party processor, policy
     10.8.2 requires noting the secure third-party purchase API in the cert
     notes. Custom RR takes none (donations link out to Buy Me a Coffee /
     crypto addresses, which is display + external links, not an in-app
     purchase flow). Mention in the notes: "Donations are external links only;
     no in-app purchasing."
   - Testing notes: describe anything a reviewer needs. Custom RR has no login,
     so "No account required; catalog loads from public sources" suffices.

Then **Submit**. One submission can be in flight at a time per product.

Automation gotchas (if driving Partner Center with a browser agent):

- Many Save/Remove/Submit controls live in **shadow DOM**:
  `document.querySelectorAll` finds nothing and JS clicks silently no-op. Drive
  them via accessibility-tree refs (a11y click tools), which work instantly.
- Listing textareas need the native value setter + input/change/blur events.
- "Submit for certification" is also in a shadow root: click via a11y ref.

---

## 6. Certification and after

- Certification usually completes in hours; allow up to 3 business days.
  It auto-publishes on pass (unless you chose manual publish).
- Store URL: `https://apps.microsoft.com/detail/<StoreID>` (the Store ID is on
  the Product identity page; protocol launcher
  `ms-windows-store://pdp/?productid=<StoreID>`).
- After it is live:
  - Add a Microsoft Store badge/link to the README Download section, the
    website, and `zapstore.yaml`-adjacent listing surfaces.
  - Updates: bump pubspec version, dispatch `msstore.yml`, upload the new MSIX
    to a new submission. Store handles delivery; version must ascend.
  - IARC "Live Rating Notice" email carries the Global Rating ID; file it.
- **Post-cert re-test:** install the Store version on a real machine and check
  the Start tile + install dialog colors (the BackgroundColor patch from
  section 2.3) and that mobile-only surfaces (updater, APK flows) are absent.

---

## 7. Quick decision log (why it is this way)

| Decision | Reason |
| --- | --- |
| Native MSIX, not PWA | Custom RR has no hosted web app; Flutter Windows is the natural target. (ClauseShift used a PWABuilder PWA as a stopgap, then replaced it in-place with the native MSIX on the same Store ID - same-identity higher-version upload = in-place upgrade, listings/reviews retained.) |
| Plain `.msix`, not `.msixbundle` | First-ever package sets the precedent. Bundles are only mandatory once you have shipped one. |
| No self-updater in the Store build | The default build already compiles it out (`kGithubReleaseBuild` unset). Store policy + Store-managed updates. |
| Repo VARIABLES (not secrets) for identity | `Package/Identity/*` values are public in every installed manifest; variables keep the workflow logs readable. |
| `install_certificate: false` | CI would hang on the interactive cert prompt (exit 255). |
| Manifest BackgroundColor patch in CI | The msix package hardcodes `transparent`; only a build/sed/pack split fixes the accent-colored tile plate. A local `dart run msix:create` will still show the accent border - only CI output is patched. |

## 8. Pre-flight checklist

- [x] Partner Center product created as "MSIX or PWA app", name(s) reserved
- [x] Product identity values copied; `MSIX_IDENTITY_NAME` + `MSIX_PUBLISHER` repo variables set
- [x] `msix` dev dep + `msix_config` in pubspec (`publisher_display_name: Monsiu Tech`, `trim_logo: false`, `install_certificate: false`)
- [x] `Runner.rc` `OriginalFilename` fixed; `app_icon.ico` regenerated from launcher art
- [x] `msstore.yml` added (build -> sed BackgroundColor -> pack; msix + unpackaged artifacts)
- [ ] `flutter build windows --release` succeeds in CI
- [ ] Unpackaged zip smoke-tested on real Windows
- [ ] Tile PNGs + patched manifest verified inside the built `.msix`
- [ ] All 6 submission sections green (incl. runFullTrust justification)
- [ ] Submitted; certification verdict watched; README/website badges updated on pass
