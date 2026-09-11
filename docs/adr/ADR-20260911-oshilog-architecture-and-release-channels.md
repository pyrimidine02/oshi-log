# ADR-20260911: Oshi-log architecture, journey design, and release channels

## Status

Implemented and locally verified on 2026-09-12.

## Problem

- Feature folders already contain presentation/application/domain/data layers,
  but domain entities import transport DTOs and repository contracts expose DTOs.
- Development currently defaults to the old production API host. Release mode
  alone cannot distinguish TestFlight/internal testing from store distribution.
- Existing ads initialize before authentication bootstrap, and native ad loading
  has no UMP consent gate. Optional monetization must not block app startup.
- Repeated visual redesigns need one coherent travel/pilgrimage/concert record
  hierarchy, reusable widgets, and accessible narrow-screen layouts.

## Alternatives

1. Rewrite the app and replace Riverpod. Rejected: unnecessary migration risk.
2. Rename folders and retain reverse dependencies. Rejected: no actual isolation.
3. Repair existing feature boundaries, API mappings, shared design, and explicit
   release configuration with regression coverage. Selected.

## Decision

1. Measure existing analyzer/test/coverage baseline. Preserve the pre-existing
   uncommitted router `TEMP-VERIFY` change outside this refactor's commit.
2. Compare used API contracts to the adjacent `oshilog-api` server source and
   maintained specifications. Move DTO-to-entity mapping into data; keep existing
   Riverpod controllers as view models and repositories as data access seams.
   Add boundary checks and behavior tests for confirmed contract defects.
3. Refine existing design tokens and main journey screens around discovering
   pilgrimage places, planning concerts, and revisiting personal records.
   Keep existing routes and real data; separate view composition from loading
   and state logic. Verify light/dark, text scaling, and compact screens.
4. Select environment explicitly at build time. Development/staging target
   `https://dev.oshilog.org`; production targets `https://api.oshilog.org`.
   Internal Android and default Xcode Cloud builds use staging. Store builds
   explicitly select production. Credentials and signing remain externally owned.
5. Keep AdMob optional, with test inventory outside production and no network
   ad request before SDK consent readiness. Ads must not delay auth/storage.
6. Review changes, run analyzer and full tests, compare coverage, validate channel
   configuration and build viability, then commit and push main.

## Validation and practical limits

- App baseline: `e39ed8f`. Server checkout: adjacent `oshilog-api`, HEAD
  `4b7d1f15` with uncommitted changes. The audit uses the current local server
  working tree, not a claim about the exact code deployed to either domain.
- Baseline: 594 Flutter tests pass; reported LCOV covers 15,063 / 44,986
  executable lines (33.48%). The existing suite does not meet the stated 80%
  project target. New behavior needs regression coverage and no coverage drop.
- Final suite: 659 tests pass, including repository/controller integration,
  auth races, environment isolation, consent lifecycle, and component goldens.
  LCOV covers 16,153 / 46,048 executable lines (35.08%); coverage increased,
  but the project-wide 80% target remains unmet.
- Final `flutter analyze --no-pub` and changed-file format checks pass. The
  staging iOS simulator debug build passes from the ASCII verification checkout.
  Native signing and production store submission were not exercised locally.
- Local SDK observed: Flutter 3.47.2, Dart 3.13.2. CI currently pins 3.41.0;
  compatibility must be checked when choosing APIs and lockfile updates.
- The first CI run passed analysis and 656 tests; only the three new home
  goldens failed (4.92-6.63% pixel differences). Their first baselines had been
  generated with 3.47.2. Golden generation and comparison must use CI's pinned
  Flutter 3.41.0 (official tag `44a626f4f0`, Dart 3.11.0). Keep the existing
  1.5% comparator tolerance; do not mask SDK drift by widening it.
  See the [official SDK archive](https://docs.flutter.dev/install/archive).
- `flutter analyze` crashes on this Korean checkout path with Flutter issue
  [191309](https://github.com/flutter/flutter/issues/191309). `dart analyze`
  completes and identified two existing `unawaited_return_in_try_block` warnings.
  Final Flutter analysis runs from an ASCII verification checkout.
- Baseline iOS simulator build passes. Flutter 3.47 automatically raises its
  temporary iOS target to 15.0; SDK-generated project/Podfile/lockfile changes
  were restored rather than silently changing the app's supported iOS version.
- Initial public OpenAPI probes: dev returned HTTP 404; production HTTP 502.
  Source-contract verification does not prove either deployed server healthy.
- Public projects probes rechecked on 2026-09-12: development HTTP 200 with an
  empty project list; production HTTP 502. Authenticated device flows and store
  distribution cannot be inferred from unit/widget tests or a simulator build.
- The repository has no `integration_test/` suite. Existing repository/controller
  tests cover mocked service integration; live account/device E2E remains a
  release QA task, recorded in `TODO.md`.
- A build-time channel stays fixed in its binary. Promoting the same internal
  artifact to production does not change its API endpoint. Build a production
  artifact explicitly for store submission.
- AdMob account settings, real IDs, store privacy disclosures, and external
  Xcode Cloud workflow settings require corresponding external configuration.

## Research references

Accessed 2026-09-11; product references inform design, not backend capabilities.

- [Flutter architecture recommendations](https://docs.flutter.dev/app-architecture/recommendations)
  (documentation identifies Flutter 3.47.2): UI/data separation, view models,
  repositories, dependency injection, immutable models, component tests.
- [Polarsteps](https://www.polarsteps.com/): plan, track, and revisit journeys;
  map context and personal travel memories inform the information hierarchy.
- [setlist.fm](https://www.setlist.fm/): artist/date/venue/setlist presentation
  informs concert record identity.
- [Apple accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility):
  accessibility reference for interface review.
- [AdMob Flutter privacy](https://developers.google.com/admob/flutter/privacy):
  refresh consent, expose required privacy options, check `canRequestAds`.
- [AdMob Flutter test ads](https://developers.google.com/admob/flutter/test-ads):
  separate test inventory from production advertising.

## Performance intent

Reuse cached images and lazy lists. Split independently changing screen sections
into widgets; keep network work outside build methods. No new perpetual animation,
map renderer, or eager record-list loading is part of this change.

## Contract and boundary findings

- DTO factories on domain entities reversed the layer dependency. Mapping now
  belongs to feature `data/mappers`; repositories publish domain values, including
  upload preparation/confirmation. Collection mappings detach from DTO lists.
  A source-boundary test guards domain and presentation imports.
- Current server live-event DTOs expose `placeId`, `venue`, `venueTypes`,
  `address`, `regionCodes`, and summary `endTime`. The client previously dropped
  these fields. Preserve them through DTO, cache serialization, domain mapping,
  venue presentation, and linked-place navigation.
- Event categorization must use a valid end time, not only the start time:
  an ongoing concert belongs in the upcoming/current agenda until it finishes.
- Home loading must capture the selected unit filter with the request, scope its
  memory cache by that filter, and ignore stale completions before changing
  state or failure cooldown. Repository initialization also belongs inside the
  guarded request so an initialization exception cannot leave loading stuck.
- Calendar range projection is bounded by the requested month; a very long
  source event must not iterate over its entire lifetime. Parallel fetches must
  attach error handlers to both futures immediately.
- Banner/title repository fallback futures need `await` inside their `try`
  blocks so asynchronous failures are mapped instead of escaping.
- X authorization and exchange must send the same validated callback URI. The
  app must recognize the server's `girlsbandtabi://oauth/x/callback` handoff while
  retaining state/PKCE checks and the registered legacy HTTPS callback default.
  The removed generic callback route is not a replacement for native provider
  POST login endpoints.
- API-origin namespaces isolate tokens, PKCE state, cached responses, preferences,
  and queued mutations. They intentionally do not adopt unscoped legacy auth or
  outbox data, whose server provenance is unknown. Users authenticate again on
  the new origin; theme and locale remain device preferences.
- Review also found that logout omitted favorite/reaction/attendance outboxes
  and local bookmarks. Origin isolation alone cannot separate successive users
  on the same API. Logout must clear those personal values and invalidate pending
  controller work before a later account can replay or restore old mutations.
- Authentication changes serialize against logout, including pending token and
  provider-proof writes. Cleanup failures keep the session unauthenticated;
  regression tests exercise delayed login, logout, and account-owned writes.

## Visual scope

The existing Field pages remain the routed experience. Shared paper surfaces,
section headings, badges, and touch targets support place discovery, concert
agendas, and visit ledgers. Confirmed unreachable sibling pages are removed;
route strategy and native map ownership stay unchanged. Component goldens check
light, dark, and compact enlarged-text layouts; they are not screenshots of a
live authenticated production session.
