# Security Policy

## Supported versions

Custom RR is pre-1.0 and ships from a single active line. Only the latest
release on the [Releases page](https://github.com/monsiu/Custom-RR/releases)
receives security fixes. Please reproduce any issue on the newest version
before reporting.

## Reporting a vulnerability

Please do **not** open a public issue for security problems.

Use one of these private channels instead:

- **Preferred:** GitHub's private vulnerability reporting, via the repository
  **Security** tab > **Report a vulnerability**.
- **Email:** contactmonsiu@gmail.com with the subject `Custom RR security`.

Include what you need to demonstrate the issue: affected version, platform
(Android / Linux / Windows), steps to reproduce, and the impact you observed.

## What to expect

- An acknowledgement of your report.
- An assessment of whether it is confirmed, and the planned fix or mitigation.
- Credit in the release notes once a fix ships, unless you prefer to stay
  anonymous.

## Scope

Custom RR is an offline-first catalog app: it bundles data, refreshes a JSON
catalog from this GitHub repository, and opens official download links in your
browser. It collects no analytics and runs no backend. The most relevant
concerns are therefore things like the in-app update flow (GitHub builds),
handling of catalog data fetched at launch, and deep-link parsing.

Flashing custom ROMs, recoveries, GSIs, or root solutions is inherently risky
and is done at your own discretion; problems caused by third-party firmware
linked from the catalog are not vulnerabilities in Custom RR.
