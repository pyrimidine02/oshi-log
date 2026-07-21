# ADR-20260720: Apple map and information hierarchy

## Status

Accepted on 2026-07-20. Revised and verified on 2026-07-21 after the Explore
navigation and spacing review.

## Problem

Explore placed search, project context, filters, map controls, selected-place
details, a draggable list, and route switching on the same canvas. Repeated
labels and decorative icons reduced the visible map. The first redesign also
put a second navigation layer too far above the global bottom bar because an
`extendBody` inset was counted more than once.

Information and the former Field kit had the same hierarchy problem: many
isolated cards and icon boxes competed with the actual reference material.
Updates also became difficult to revisit as the archive grew, while map search
changed its height with the number of results.

## Decision

- Preserve routes, providers, native map lifecycle, API contracts, and the
  existing five-destination main navigation.
- Keep the map canvas map-first: one 48dp place search, one horizontal filter
  chip rail, and one 48dp current-location action.
- Let the map background extend under system bars and rounded corners. Keep
  every interactive overlay and non-map Explore page inside Flutter's native
  safe-area insets so Android cutouts, iPhone notches, Dynamic Island, and
  landscape side insets use one platform-owned rule.
- Present map search in a stable 82% sheet with an invariant 48dp search field.
  Let only the result region scroll or change as matches arrive.
- Use a draggable place sheet with compact, half, and full detents. Compact and
  half states show horizontal field-note cards; full state shows the vertical
  place ledger.
- Put Map, Events, Visits, and Stamps in one four-way segmented control. It
  lives in the map sheet on Map and directly above main navigation on non-map
  pages.
- Treat the `MediaQuery.padding.bottom` supplied by the host `extendBody`
  scaffold as the measured main-navigation height. Do not add the nominal 64dp
  bar again. Reserve the host inset separately for the embedded map so its
  sheet control is not covered.
- Keep exactly 8dp between the Explore selector and main navigation. Reserve
  this lower stack once in Events, Visits, and Stamps.
- Reframe Field kit as `팬 자료실` rather than a trip-preparation checklist.
  Group its destinations as Schedule, Music & cheering, and Memories &
  collection so lyrics and call guides remain everyday references. Keep the
  travel/passport identity in mastheads, folios, rules, field notes, and a
  narrow passport spine.
- Keep the update archive discoverable with a fixed title search, year filter,
  latest/oldest sort, and a lazily built article list above the scrolling
  results.
- Rebuild visit history as a responsive Travel Logbook whose empty states lead
  directly to the map or event schedule.
- Keep actions at least 44pt, prefer 48dp controls, expose semantic labels and
  selected state, and preserve system text scaling and reduced motion.

## Consequences

- Search and filters remain immediately available without covering most of the
  map.
- Explore mode switching has one visual grammar while respecting the map's
  special bottom-sheet interaction.
- Removing duplicate lower insets restores more than 100dp of usable content
  on the verified iPhone viewport and keeps the selector 8dp above main
  navigation.
- Empty pages still retain honest empty states; they no longer reserve the same
  navigation height two or three times.
- Old updates can be found without scrolling through every newer hero card,
  and map search no longer jumps as result counts change.
- No routing, persistence, dependency, native signing, or server migration is
  required.

## Performance and accessibility

- The sheet listener changes widget state only when crossing the full-list
  threshold, rather than rebuilding for every drag frame.
- Horizontal result cards and the vertical ledger are not mounted together.
- Update summaries use a sliver builder instead of eagerly mounting the whole
  archive, and search/filter state creates new result lists before sorting.
- Tests cover 320dp width, 200% and 300% text scale, 48dp actions, selected
  semantics, host-injected safe-area padding, the embedded map inset, and
  invariant map-search geometry. Layout cases also cover a legacy Android
  status bar, Dynamic Island, and landscape side cutouts.

## Design references

- Apple Human Interface Guidelines, Maps:
  https://developer.apple.com/design/human-interface-guidelines/maps
- Apple Human Interface Guidelines, Menus:
  https://developer.apple.com/design/human-interface-guidelines/menus
- Find nearby attractions in Maps on iPhone, Apple Support:
  https://support.apple.com/en-in/guide/iphone/iphbaf51b2c0/ios
- View and save information about a place in Maps, Apple Support:
  https://support.apple.com/en-mn/guide/iphone/iph8c9c2528b/ios
- Find nearby places on iOS, Google Maps Help:
  https://support.google.com/maps/answer/4610185?co=GENIE.Platform%3DiOS&hl=en
- Hide lists or days on map, Wanderlog Help Center:
  https://help.wanderlog.com/hc/en-us/articles/5159543865499-Hide-lists-or-days-on-map
- Search UX patterns, Mapbox documentation:
  https://docs.mapbox.com/help/getting-started/search/

## Verification

- iPhone 17 Pro simulator, iOS 26.5: native Apple map, Map → Events → Visits,
  return navigation, corrected 8dp lower spacing, map-sheet clearance, and
  unchanged search-sheet geometry before and after a `DICE` result were
  visually inspected. The final map also fills the area behind Dynamic Island
  while its search and filters remain below the safe-area boundary.
- Focused Explore and map widget tests pass. Static analysis reports no issues,
  and the full Flutter suite passes all 563 tests.
- Native accessibility-tree inspection remains in `TODO.md` because `idb` is
  not installed on this workstation.
