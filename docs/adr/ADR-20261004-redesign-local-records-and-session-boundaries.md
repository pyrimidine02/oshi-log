# Screen redesign, local records, and session boundaries

Date: 2026-10-04
Status: Accepted; final integration verification recorded in HANDOFF.md.

## Problem

The approved PR9–21 plan changes navigation to Home / Map / Live / Community / My.
Legacy links must survive. Several desired public reads and travel capabilities
are absent from the current server contract. Existing login flows can also lose
the original destination, and private local photos must never become public
without explicit selection and submission.

## Decision

- Keep one Riverpod-owned GoRouter across auth changes. Canonical routes own
  screens; legacy aliases retain identifiers, repeated queries, and fragments.
  Preserve the common bottom navigation on community roots.
- Public shell entries use in-place auth gates where the server still requires
  authentication. Inline login releases one pending action only after explicit
  success in the matching session and original route. Dismissal is terminal.
  External browser OAuth cancels automatic action replay and keeps a validated
  return URI in memory; process-death restoration is not promised.
- Reuse the existing repositories and explicit server data. Centralize JST
  event-date rules and spoiler hiding. Unknown timing, source, permissions,
  performer identity, and original-language text stay unknown in the UI.
  Lyrics require current availability and an explicit `OK` rights policy.
  Missing policy, loading, or errors hide the text and offer provided HTTPS
  official links. A live-context bundle cannot bypass this display guard.
  App language does not establish regional permission: country-restricted
  lyrics remain hidden until an authoritative region contract exists. Known
  release/expiry bounds apply even while the page stays open.
- Store Today ordering, skipped entries, and downloaded text locally per account.
  Starting another day requires confirmation. Failed refresh retains the old
  snapshot and timestamp; maps and media are outside the text-download promise.
- Keep trips and original photos private in account-scoped application storage.
  Dates require confirmation. Merge/split operate on explicit selections.
  A public review draft receives selected entries and metadata-stripped photo
  exports only. No upload happens before final public submission. Preserve
  successful upload IDs for retry; reject stale account/project operations.
  Validate the existing 1–20 place, 10 event, and 10 photo limits before export.
- Reject stale API request dispatch, normal responses, refresh results, and retries
  after a session change. Cache clearing advances a generation so delayed
  fetches, cached fallbacks, and background refreshes cannot restore old-account
  data. Existing cache policies remain intact for the active generation.
- Do not request notification permission on login or incoming messages. Locale
  and theme remain available to guests, and onboarding can be skipped entirely.
- Complete the approved PR8c separation after screen work settles: reusable UI,
  localization, and accessibility belong to `design_system`; infrastructure and
  feature-free contracts belong to `platform`. Both must import no features.

## Alternatives

Using public travel-review creation as private persistence was rejected: creation
publishes immediately and requires at least one place. Inventing new wire fields
or anonymous access would misrepresent server capabilities. An additional state
framework, offline map engine, or itinerary optimizer is unnecessary for this scope.

## Consequences and validation

Local albums have no server sync or recovery after app-data removal. Guest music,
collections, community, and search remain constrained by server authorization.
Event-only reviews, scheduled participation, content universal links, and richer
place information remain separate server work.

Focused tests cover route compatibility, auth cancellation and session changes,
partial failures, offline timestamps, durable photo copies, and selected-public
handoff. JA/KO, light/dark, 320dp, and 200% text fixtures check layout. Golden
fixtures do not prove device Japanese font rendering, native map tiles, permission
dialogs, OAuth provider UI, or device performance. Final suite, coverage, analysis,
architecture, and build outcomes are recorded in the implementation status.

The main release is checked with the workflow's Flutter 3.41.0 / Dart 3.11.0,
using an isolated SDK from official tag `3.41.0` (revision `44a626f4f0`). The
global Flutter 3.47.2 installation remains unchanged. SDK-pinned dependencies
follow the CI resolver. Reviewed golden differences use that SDK's reference
images without increasing comparison tolerances. See the
[official Flutter SDK archive](https://docs.flutter.dev/install/archive) and
[3.41.0 source tag](https://github.com/flutter/flutter/tree/3.41.0).

Hosted Ubuntu CI revealed font metrics, wrapping and raster differences beyond
the local SDK-only changes. Extend the existing Home host-specific reference
policy to the affected matrices: Linux uses `goldens/linux`, other hosts keep
`goldens`. One test helper selects the directory; missing references still fail.
Review actual/master/diff artifacts before adopting Linux references. Do not
increase comparison tolerances or replace the Mac references. Native Japanese
glyph quality remains device QA, not a claim established by these fixtures.

Calendar and passport fixtures must express JST civil dates using explicit
`+09:00` offsets and compare transport ranges as UTC instants. Host timezone
must not change the assertions. The three fixture fixes reproduce failure under
UTC first and pass the 14 focused tests under both UTC and Asia/Seoul afterward.

Golden profiles are macOS / Asia/Seoul and hosted Linux / UTC. Event preparation
intentionally adds device-local time outside JST, as required by the screen
specification, so changing only the host timezone changes that screen. Linux
references include the extra UTC row; Mac references retain the JST view.
Timezone logic tests run in both zones; visual comparisons use their declared
profile. This is not a production date-logic change.
