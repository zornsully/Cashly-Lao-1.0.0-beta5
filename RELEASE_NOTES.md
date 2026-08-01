# Cashly Lao 1.0.4

> Reviewed notes for the `v1.0.4` candidate. Publication remains subject to
> local signed-artifact validation and explicit owner approval. No release is
> published or deployed automatically.

## New features

- Native Android and iOS entry now bypasses the marketing site completely:
  restored sessions continue to Dashboard, while signed-out users go directly
  to Login.
- Added the responsive, selected-currency Cashly Lao dashboard for web,
  tablet, and mobile.
- Redesigned Accounts around compact currency groups, correct per-currency
  asset/liability/net-worth summaries, filters, sorting, and safer negative
  balance presentation.

## Improvements

- The public landing page remains available on the web only, including its
  verified release information and download area.
- Legal pages now return native users to the app flow rather than Landing.

## Bug fixes

- Prevented mobile deep links to `/` from displaying the web marketing page.

## Security updates

- Development releases use verified local signing, certificate validation,
  SHA-256 checksums, and a fail-closed public-download policy.

## Breaking changes

- None.

## Known issues

- iOS, Windows, and macOS public packages remain unavailable until their
  signing and distribution requirements are configured.
