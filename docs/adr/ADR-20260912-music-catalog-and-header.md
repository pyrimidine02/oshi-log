# ADR-20260912: Music catalog and content-sized song headers

## Problem

The reported iPhone screenshot hides song metadata behind the pinned tabs.
A fixed expanded header height combines safe-area/toolbar spacing with long
localized text. The regression fixture reproduces metadata ending at y=249
while tabs start at y=231. Artist cards independently render absent member
summaries as a false zero count. Albums previously stop after the first page
until the user scrolls, preventing complete catalog search/filtering.

## Decision

Use the standard app bar, a content-sized SliverToBoxAdapter song header, and
separate pinned Material tabs. Keep the existing NestedScrollView, route and
Riverpod providers. Move lyrics controls into the lazy lyrics list so small
remaining viewport heights and enlarged text cannot overflow a fixed column.
Remove ornamental dossier/index labels; preserve full title and artist text.
Bound catalog controls to 65% of the available viewport inside a scroll view,
leaving room for results. Keep the same widget tree across keyboard resizes so
search focus and filters survive. Controls retain native popup menus and 48dp
minimum touch targets.

Drain album pages serially, publishing each page, as the song controller already
does. Use at most 100 items/request, deduplicate IDs, reject missing/repeated
cursors and bound a chain to 100 pages. Report partial failures with retry.
Search and sort loaded metadata locally; expose title/release ordering, units,
and album types. Unknown release dates sort last. Song release dates come from
the linked album, not fabricated song fields.

Preserve nullable memberCount through UnitDto/domain mapping. List responses
without membership are unknown; actual detail arrays or supplied counts can
provide a count. Hide unknown counts and their accessibility label. Fetching
one detail per visible artist would add avoidable requests.

## Server and DB contract

Inspected adjacent oshilog-api source, without changing server or DB:

- MusicController: GET albums supports cursor, size, q, unitId, releaseFrom/To;
  fixed release-date sorting. GET songs additionally supports albumId and sort.
- MusicQueryService bounds size to 1..100 and uses numeric-offset cursors. The
  transport remains paginated; the user sees one progressively complete list.
- V002 schema: albums have optional unit_id; songs have album_id and
  primary_unit_id. Current responses contain no multi-appearance album array.
- UnitDtos/UnitQueryService: UnitDto list omits members/memberCount;
  UnitDetailDto loads members. Missing membership never establishes zero.

Offset pagination is not a stable snapshot if catalog data changes during a
load. No new bulk endpoint, database migration, or per-artist request is needed.

## Alternatives and performance

Increasing expandedHeight only treats one title/font/device combination.
Fetching all artwork or starting requests concurrently would increase memory
and server pressure. Keep lazy rows/grids, cached images and sequential metadata
requests. Local sort is O(n log n); list widgets build visible rows. The chain
limit is 10,000 returned items and fails explicitly if more pages remain.

## Validation and references

Flutter 3.41.0 / Dart 3.11.0. Run tests serially with nice priority 10 in the
compatible SDK copy, without simulator/native builds. Regression checks cover
notch geometry on all tabs, long localized titles, 300% text and tab access,
lazy lyrics, cursor errors/retry, missing member counts and catalog controls.
Installed-device rendering and native frame timings remain separate QA.

Official Flutter references consulted for pinned slivers and coordinated scrolling:
- https://api.flutter.dev/flutter/widgets/NestedScrollView-class.html
- https://api.flutter.dev/flutter/material/SliverAppBar-class.html

Final validation: all 732 tests pass (6m00s); flutter analyze reports no issues.
Coverage: 17,760 / 46,340 lines (38.33%), above the previous
17,424 / 46,126 (37.77%). The existing whole-project 80% target remains unmet.
Source/test files match the tested SDK copy; git diff --check is clean.
