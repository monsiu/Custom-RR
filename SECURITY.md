# Security Policy

## Supported versions

Custom RR ships from a single active release line. Only the latest release on
the [Releases page](https://github.com/monsiu/Custom-RR/releases) receives
security fixes. Please reproduce any issue on the newest version before
reporting.

## Reporting a vulnerability

Please do **not** open a public issue for security problems.

Use one of these private channels instead:

- **Preferred:** GitHub's private vulnerability reporting, via the repository
  **Security** tab > **Report a vulnerability**.
- **Email:** contactmonsiu@gmail.com with the subject `Custom RR security`.

Include what you need to demonstrate the issue: affected version, platform
(Android / Linux / Windows / macOS), steps to reproduce, and the impact you
observed.

## What to expect

- An acknowledgement of your report.
- An assessment of whether it is confirmed, and the planned fix or mitigation.
- Credit in the release notes once a fix ships, unless you prefer to stay
  anonymous.

## Scope

Custom RR is a catalog app with no backend of its own and no analytics. It
bundles a fallback catalog, refreshes a JSON catalog and freshness data from
this GitHub repository, loads catalog images from a public CDN (jsDelivr), shows
live community content fetched from third parties (community ROM uploads from
OpenDesktop and project discussions), and opens official project and download
links in your browser. The most relevant concerns are therefore things like the
in-app update flow (GitHub builds only), handling of the catalog, image, and
community data fetched at runtime, and deep-link parsing.

Third-party content surfaced in the app (community builds, project pages, and
download links) is shown as-is and is not vetted by Custom RR. Flashing custom
ROMs, recoveries, GSIs, or root solutions is inherently risky and is done at
your own discretion; problems caused by third-party firmware or uploads linked
from the catalog are not vulnerabilities in Custom RR.
