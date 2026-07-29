# Cashly Lao 1.0.2

> Approved release notes for the `v1.0.2` candidate. Publication remains
> subject to the protected signing and deployment checks.

## New features

- Added a responsive Cashly Lao dashboard for web, tablet, and mobile.
- Added a balance-led Smart Money Score with daily, weekly, and monthly
  explanations and practical next steps.
- Added dynamic release information to the landing page, including platform
  availability, release details, and safe download states.

## Improvements

- Added persistent Firestore cache support and safer offline transaction
  queueing.
- Added structured release metadata and signed Android artifact checks.

## Bug fixes

- Improved release-download error handling so unavailable metadata does not
  expose a broken download button.

## Security updates

- Production releases are prepared for approval-gated publishing with verified
  checksums and a fail-closed Android signing requirement.

## Breaking changes

- None.

## Known issues

- iOS, Windows, and macOS public packages remain unavailable until their
  signing and distribution requirements are configured.
