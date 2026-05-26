# Privacy Policy for Custom RR

**Effective date:** May 26, 2026
**Last updated:** May 26, 2026

Custom RR ("the app") is an open-source Android app that catalogs custom ROMs
and recoveries, with links, screenshots, and flashing instructions. The app is
published by Monsiu Tech Solutions ("we", "us").

We do not run our own backend. We do not collect, store, sell, or share
personal data on our own servers.

## Data we do not collect

The app does not collect or transmit:

- Names, email addresses, phone numbers, or other identifiers you enter into
  your device.
- Account credentials.
- Precise or coarse location.
- Contacts, photos, microphone, or camera data.
- Analytics, advertising IDs, crash telemetry, or behavioral tracking.

## Data stored locally on your device

The app stores the following only on your device, never sent to us:

- Your in-app preferences (theme, last-used filters, dismissed notices), via
  Android `SharedPreferences`.
- Cached catalog data, screenshots, and a local SQLite cache to speed up
  browsing offline.
- Clipboard contents you choose to copy by tapping a donation address.

You can clear all of this by uninstalling the app or by using Android's
"Clear storage" option in app settings.

## Third-party services the app contacts

When you use certain features, the app makes network requests to these
third parties. They receive standard request metadata such as your IP
address, the requested URL, and a `User-Agent` string. We do not see or
log these requests.

| Service | When | Why | Their policy |
| --- | --- | --- | --- |
| GitHub (`raw.githubusercontent.com`, `api.github.com`) | On launch and on manual refresh | Fetch the latest ROM catalog, freshness data, and update info from this project's repository | [GitHub General Privacy Statement](https://docs.github.com/site-policy/privacy-policies/github-general-privacy-statement) |
| Image CDNs (e.g. `wiki.lineageos.org`) | When viewing device pages | Load device thumbnails | Each site's own policy |
| XDA Forums (`xdaforums.com`) | When you open an XDA section | Fetch RSS feeds for recent threads | [XDA Privacy Policy](https://www.xda-developers.com/privacy/) |
| Trocador AnonPay (`trocador.app`) | Only if you tap "Use other crypto (swap to XMR)" in the donate sheet | Create a swap transaction and open the payment page in an in-app browser | [Trocador Privacy Policy](https://trocador.app/en/privacypolicy/) |
| Buy Me a Coffee (`buymeacoffee.com`) | Only if you tap that link from the About page | Open the donation page in your browser | [Buy Me a Coffee Privacy Policy](https://www.buymeacoffee.com/privacy-policy) |
| Web Archive (`web.archive.org`) | Only if you tap a "View archived" link for a discontinued ROM | Open the archived page | [Internet Archive Terms](https://archive.org/about/terms.php) |
| External links you tap (ROM project sites, SourceForge, etc.) | Only when you tap them | Open the link in your browser | Each site's own policy |

We have no agreement with these services and receive no data from them.
Once you leave the app for an external page, that site's policy applies.

## Crypto donations

Donation wallet addresses shown in the app are public on-chain addresses.
Copying one places the address on your device's clipboard; no network request
is made by the copy action itself. Sending crypto to any address is a
voluntary on-chain transaction handled by your own wallet.

If you choose the "Use other crypto (swap to XMR)" option, a request is sent
to Trocador to create a swap transaction. The data sent is limited to:

- The destination Monero address (ours, fixed in the app).
- A label ("Monsiu Tech") and contact email so Trocador can notify us if a
  swap completes.
- The display preference of USD as the fiat reference.

The swap itself is operated entirely by Trocador. We never see your sending
wallet, IP, or transaction details. See Trocador's policy above.

## Permissions

The app requests only the standard permissions needed by Flutter and by
package dependencies:

- `INTERNET`: to fetch the catalog, images, RSS feeds, and the Trocador
  swap URL.
- `ACCESS_NETWORK_STATE`: to detect whether you are online before retrying
  network calls.

The app does not request location, contacts, camera, microphone, SMS, or
phone permissions.

## Children's privacy

The app is not directed to children under 13 and we do not knowingly
collect data from anyone. Because the app collects no personal data on our
side, no special handling for minors is needed.

## Open source

The source code is publicly available at
[github.com/monsiu/Custom-RR](https://github.com/monsiu/Custom-RR). You can
audit exactly what the app does.

## Changes to this policy

If we change this policy, we will update the "Last updated" date above and
publish the change in the repository. Material changes will also be noted in
release notes.

## Contact

Questions or privacy requests:

- Email: <contactmonsiu@gmail.com>
- Issues: <https://github.com/monsiu/Custom-RR/issues>
