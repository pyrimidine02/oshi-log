# ADR-20260912: Consistent, content-first mobile controls

## Context and scope

The routed app uses Field Home, Explore, Guide, Passport, and Community under
the existing indexed shell. Page headings, section actions, and custom mode
selectors use different sizing and selection treatments. Tight parent layouts
are not always considered. Home reserves almost a third of its briefing for
decorative art even when the server has no image.

This is a presentation correction within existing feature boundaries. Keep
Riverpod, route ownership, API calls, authentication, caches, and native maps.
Existing uncommitted router, information-page, artist-logo, and documentation
edits belong to prior work and must be preserved.

## Plan

1. Record the existing suite and coverage on CI's Flutter 3.41.0 SDK.
2. Add failing behavior checks for compact headers, text contrast, native mode
   selection, and missing-media briefing layout.
3. Reuse ThemeData/ColorScheme and Material controls. Reflow headings using
   their actual parent constraints; keep primary actions at least 48dp.
4. Present real event/place content first. Keep absent media compact and
   explain empty recommendations in user language.
5. Review changes; run analyzer, full tests, coverage comparison, and inspect
   light/dark/compact rendered previews. Record device-only checks separately.

## Server and database evidence

Inspected adjacent `../oshilog-api` source, not deployed data. Backend uses
Spring MVC/JPA, PostgreSQL/PostGIS, Redis, and Flyway. Relevant relative paths:

- `server/src/main/kotlin/org/pyrimidines/oshilog/gateway/rest/HomeController.kt`
  defines the summary, nullable banner, and source/fallback metadata.
- `server/src/main/kotlin/org/pyrimidines/oshilog/gateway/service/HomeSummaryService.kt`
  caps previews at five items and queries upcoming events within 30 days.
  Home is a summary, not an infinite feed or a live attendance dashboard.
- `server/src/main/kotlin/org/pyrimidines/oshilog/community/dto/PostDtos.kt`
  defines cursor pages (`items`, `nextCursor`, `hasNext`). Recommended/following
  cursor feeds require the existing authenticated capability.
- `server/src/main/kotlin/org/pyrimidines/oshilog/identity/user/dto/UserDtos.kt`
  separates public profile fields from private account details.
- `server/src/main/resources/db/migration/V002__schema.sql` defines nullable
  live-event `poster_url`, `ticket_url`, `end_time`, and `place_id`, plus nullable
  profile media. Missing images are valid data, not exceptional UI failures.

Client path: `HomeRemoteDataSource` → `HomeRepositoryImpl`/data mapper →
`HomeController` → `composeFieldHome` → `FieldHomePage`. Keep that path intact.
Do not invent distances, reservations, check-in state, or event artwork. No DB
queries, migrations, server mutations, credentials, or production requests are
part of this UI change.

## Decision and alternatives

Keep the travel identity: pilgrimage discovery, concerts and songs, then visit
records. Preserve the native map, passport document, and visit stamps. Use
neutral paper/ink/blue/teal, 16dp content-card corners, localized travel headings,
and factual service labels instead of repeated decorative uppercase captions.
Fill Material surface roles from the same palette; use legible auxiliary text
and one primary selection treatment.
Use Flutter's native segmented controls for local modes, with parent-owned
selection. Keep headings responsive and real media optional.

A new visual framework, custom animation system, and navigation redesign add
unneeded compatibility risk. Full-screen glass would also compete with map,
poster, and community content; retain current platform navigation ownership.

## Research

Official sources checked 2026-09-12. These inform UI decisions, not claims
about measured performance in this app:

- [Google Material 3 Expressive research](https://design.google/library/expressive-material-design-google-research):
  emphasize key actions, group related information, preserve familiar labeled
  interactions. Apply its hierarchy principles using available Flutter widgets;
  do not claim every Expressive component is implemented in Flutter.
- [Flutter adaptive best practices](https://docs.flutter.dev/ui/adaptive-responsive/best-practices):
  use available space, small widgets, touch-first controls, and preserved state.
- [Flutter accessibility](https://docs.flutter.dev/ui/accessibility): support
  text scaling, readable contrast, semantic controls, and assistive technology.
- [Bandsintown](https://www.bandsintown.com/) and
  [setlist.fm](https://www.setlist.fm/): service references for putting artist,
  date, venue, and song order ahead of ornamental content. This is a design
  inference from their public interfaces, not copied branding or a dependency.

Local SDK is Flutter 3.47.2 / Dart 3.13.2. Verification uses CI's Flutter 3.41.0
/ Dart 3.11.0 in an ASCII-only temporary checkout with independent generated
caches. Original native settings and dependency lock remain unchanged.

## Performance and validation

No new dependency, network request, eager list, blur, or perpetual animation.
Native controls own interaction semantics. LayoutBuilder is limited to small
header/control subtrees; removing absent artwork reduces layout/paint work.
Physical-device frame timings, VoiceOver/TalkBack, and authenticated end-to-end
flows require separate device QA. Test previews use fixtures, not live data.

Respect the user's laptop budget: run checks serially with `nice -n 10` and
`flutter test --concurrency=1`; run Linux golden rendering with one Docker CPU,
2GiB memory, and 128 PIDs maximum. Do not start native builds or simulators.

## Song detail failure

The shared detail hero overflowed at 320dp with full song metadata at text
scales 1.5 and 1.8 (horizontal 12/66px; vertical 27px). The compact metadata
layout previously started only at 2.0. Start it at 1.5 and let the lyrics
display-options label flex inside its row. Both catalog and event-setlist
entries use this page; route tests preserve eventId and verify back navigation.

Backend `MusicDtos.kt` and `MusicQueryService` use UUID song `id`, accept project
slug/UUID, and expose nullable setlist songId. Existing DTO/router contracts are
correct; no speculative aliases or navigation-strategy changes were added.
No phone or native crash report was available. These tests prove the layout
failure and its fix, not resolution of unobserved native process termination.

Follow-up: the user's persistent title-tap freeze was subsequently reproduced
through the actual information hub and music archive. Its independent cause
was a navigation ancestor loop; see
[song-title navigation freeze](ADR-20260912-song-title-navigation-freeze.md).

Validation on Flutter 3.41.0 / Dart 3.11.0:

- `nice -n 10 flutter test --no-pub --concurrency=1 --coverage`: 687 tests pass
  in 4m25s. Includes both song entry/back paths, intermediate text scales,
  compact/large-text controls, passport records, and existing regression tests.
- `nice -n 10 flutter analyze --no-pub`: no issues.
- Light/dark/compact home and mode-control previews were rendered and reviewed;
  six Linux preview tests also pass under the CPU/memory limits above. Updated
  macOS/Linux baselines without changing the image-comparison tolerance.
- Whole-project coverage increased from 16,157 / 46,051 (35.0850%) to
  16,237 / 46,045 (35.2633%). The existing 80% project target remains unmet.
  Shared field/page headers and both native mode controls are 100%; shared
  tabs 90.32%, home components 81.68%, and the passport view 98.55%.
- Reviewed diffs and `git diff --check`; original source/test trees match the
  tested copy. No native build, deployment, or device performance claim.

Remaining device/authenticated checks and their removal criteria are in TODO.md.
