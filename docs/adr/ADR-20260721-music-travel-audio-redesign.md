# ADR-20260721: Travel audio music information architecture

## Problem

The music archive mixed decorative album overlays, repeated counts, horizontal
filter chips, and placeholder icons. Song detail spread related information
across four tabs while the large blurred cover hero pushed lyrics and guides
below the fold. Member parts and call cues also appeared as lyric filters even
though they are live-performance reference material.

## Options

1. Restyle the existing cards and keep the four-tab information architecture.
2. Copy a streaming service layout and remove the travel-document identity.
3. Keep the travel and passport editorial language, but reorganize the archive
   around listening, reading lyrics, and using live-reference information.

## Decision

Use option 3.

- The archive is a `TRAVEL AUDIO INDEX` with one count line, one Albums/Songs
  switcher, and one unit menu.
- Album covers remain unobstructed. Type, year, and track count sit below the
  art. Song rows use a slim index rail, title, unit, duration, and navigation
  affordance.
- Album details use a draggable sheet with a compact 104dp cover dossier and a
  lazy track list connected to the sheet scroll controller. Loading, error,
  empty, and data states all consume that controller, and errors can retry.
- Song detail uses a compact dossier and three destinations: Lyrics, Live
  guide, and Song record.
- Lyrics expose only pronunciation and translation display options and retain
  lazy row construction. Member parts and call cues share one chronological,
  lazily built timeline in Live guide.
- Song record orders streaming first, then metadata, versions, difficulty, and
  collapsed availability and credits. Event setlists preserve the event query
  while navigating to another song.
- At large text sizes, the tab bar becomes horizontally scrollable and each tab
  keeps at least a 48dp target. The lyrics options collapse to an icon while
  retaining an accessible tooltip. Cover art yields to a text-first dossier in
  song detail and album sheets, and album cards use a horizontal layout.

## Consequences

- The first useful lyric or guide content appears much closer to the top.
- Counts and unit filters update progressively because the controller publishes
  every completed song page. A `+` marks counts that are still loading or have
  another album page, rather than presenting partial values as final totals.
- The travel identity comes from typography, folio labels, rules, and index
  rails instead of decorative stamps or repeated cards.
- Song record loads its secondary providers only when that tab is built. Large
  lyrics remain lazy and no longer request part or call-guide fallbacks.

## Verification

- Widget tests cover three-tab structure, a compact dossier, a full-metadata
  320dp layout at 300% text scale, 48dp tab targets, lazy 200-line lyrics, a
  lazy 1,000-entry live timeline, event-key preservation, and live-context
  request de-duplication.
- Controller tests prove all cursor pages are collected, de-duplicated, guarded
  against repeated cursors, and published page-by-page before completion.
- Album track and catalog filter controls retain 48dp touch-target tests.
- The archive was built and rendered against the live 16-album, 39-song catalog
  on an iPhone 17 Pro simulator running iOS 26.5.
- Static analysis reports no issues and the full 579-test Flutter suite passes.
- `idb` is unavailable on this workstation, so native accessibility-tree
  inspection remains tracked in `TODO.md`; semantic widget coverage remains the
  automated fallback.
