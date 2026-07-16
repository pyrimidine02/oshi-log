# ADR-20260716: Generalized Fan-Subject Context and Real Journey Records

## Status

Accepted locally; backend deployment and device end-to-end verification are
pending as of 2026-07-16.

## Context

The app began with a project as its only durable context and units/bands as
secondary filters. The product direction now covers voice actors, artists,
bands/units, and anime as independently selectable targets without turning
every page into a new project switcher or changing project-scoped
authorization.

The route-wide Urban Travel Field Notes redesign also revealed two product
gaps: travel-review pages were visual mocks, and global search could not return
the same project, band, voice-actor, post, and public-profile identities used by
the rest of the app.

## Decision

### 1. Separate the journey lens from fan interests

- The selected project remains the operational journey lens for places,
  calendar, events, zukan, and project-scoped API routes.
- A generalized fan-subject model represents `PROJECT`, `UNIT`, and
  `VOICE_ACTOR` interests with stable subject and source identities. The wire
  parser also understands future `ARTIST` and `ANIME` values, but the current
  mobile discovery surface remains girls-band scoped. `UNIT` remains the
  compatible wire name for a band or unit.
- The project picker stays a compact one-tap bottom sheet. A separate interest
  action opens the generalized preference sheet rather than making the top bar
  tall or nesting another navigation bar.
- Unit/band and voice-actor preferences narrow discovery and composition but do
  not grant project authorization.

This preserves the existing bottom navigation and project route contracts while
allowing future target types to use the same repository/controller/UI boundary.
Generic reads use `scopeSubjectId`; `projectId` remains a legacy bridge.

### 2. Use one immutable subject contract

The client domain entity keeps:

- generalized subject ID and type;
- source entity ID and canonical key;
- localized name, description, and image;
- subscription state.

The UI switches on the type only for label, icon, and destination. It does not
hard-code a project-to-anime-to-band-to-person hierarchy in page state. A
generic subject detail route is ready for future server types, while current
filters and search results expose only projects, bands/units, and related voice
actors.

### 3. Replace travel-review mocks with real API state

- Add DTO, remote data source, repository, and Riverpod list/detail/mutation
  controllers.
- Create reviews with ordered place stops, optional live events, trip dates,
  route notes, image IDs, and fan-subject IDs.
- Send a visit proof only from an actual verified visit record.
- Send a live-attendance proof only when the server record has a non-empty ID,
  is `VERIFIED`, and belongs to the selected event. Declared attendance and
  missing IDs fail closed.
- Show edit/delete actions only for the current author and use real PATCH/DELETE
  calls.

### 4. Expand global discovery without losing source identity

Search results support places, news, live events, fan subjects, posts, and
public users. Fan subjects navigate by source type and source ID, so a voice
actor result opens the voice-actor detail route rather than being treated as a
project. Future artist/anime wire values remain parseable but are filtered from
the current girls-band mobile surface. Project and unit scopes are forwarded
only to server result families whose public contracts allow those scopes.

## User-interface consequences

- The five-destination main bottom bar and the separate community bottom bar
  remain intact.
- GBT blue remains the primary action and selection color; destructive red is
  reserved for errors and destructive actions.
- Project switching remains a small sheet interaction instead of a thick
  explore header.
- Home, explore map/events/ledger/zukan, calendar, profile, search, and travel
  review composition share the same paper, rule, typography, state, and touch
  target system established by the route-wide design contract.

## Compatibility and limits

- Existing project slug/code endpoints remain the source of truth.
- Existing project and unit filters continue to work while fan-subject support
  is additive.
- A person who is both a voice actor and recording artist must not be imported
  as two unrelated fan identities. Canonical cross-role identity linking is a
  server catalog concern and must precede dual-role catalog import.
- Travel-review image selection, tag composition, infinite-scroll pagination,
  and full-field editing remain follow-up UI work; the repository contract
  already supports their server fields.
- Production device proof remains disabled for automatic trusted rewards until
  the server attestation trust chain is configured.

## Verification

- Full `dart analyze`: passed with no issues.
- Full Flutter suite: 508 tests passed.
- Travel-review API and proof contract: 17 focused tests passed.
- Search generalized identity/scope contract: 10 focused tests passed.
- 320dp, 200 percent text, dark-mode, semantics, and minimum touch-target tests
  cover the shared route design and the new context sheets.

## Deployment state

No backend or mobile production deployment was performed. Real HTTPS and native
map/device proof flows remain part of the reviewed release and device-QA path.
