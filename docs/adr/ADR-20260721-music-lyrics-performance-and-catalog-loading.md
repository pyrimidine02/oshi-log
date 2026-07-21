# ADR-20260721: Music lyrics performance and catalog loading

## Problem

Opening a song could stall the UI. The lyrics tab created every lyric widget
inside one eager column, each row used intrinsic-height layout, setlist entry
requested both the bundled live context and three standalone resources, and
debug networking recursively copied and printed entire response bodies.

The song catalog also exposed API cursor boundaries through bottom-scroll
loading. Unit filters and counts changed as pages arrived, which made the
catalog appear incomplete and unstable.

## Options

1. Keep the current rendering and add a spinner or longer timeout.
2. Cap lyrics and songs to one server page.
3. Render lyrics lazily, remove duplicate requests, bound diagnostic logging,
   and collect song cursor pages behind the controller.

## Decision

Use option 3.

- Lyrics use a lazy builder and no per-row intrinsic measurement.
- Setlist entry uses the bundled live-context provider first and requests only
  fields omitted by a partial response. The Guide tab reuses the same context.
  Normal entry defers member-part loading until the user enables that layer.
- Response diagnostics retain redaction but log bounded type/key/count
  summaries for large collections.
- `MusicSongsController` requests 100 items per cursor until completion,
  de-duplicates by song ID, stops on missing or repeated cursors, and publishes
  one complete list. A 100-page guard limits malformed API chains. Disposal or
  a newer refresh stops the active cursor chain.

## Consequences

- Initial song catalog loading can take longer on slow networks, but filters,
  totals, and album-song lookup no longer change during scrolling.
- A later-page failure can leave a partial list with a visible retry action.
- The loading and rendering contracts remain independent of the presentation.
  A separately approved follow-up redesign on the same date now consumes these
  contracts through three task-focused sections without restoring eager lyric
  or cursor rendering.

## Verification

- Unit tests cover multi-page collection, ID de-duplication, and repeated
  cursor termination.
- Widget tests cover lazy construction of 200 lyric rows and one-request
  setlist entry.
- Network tests cover bounded summaries for a 1,000-line payload.
