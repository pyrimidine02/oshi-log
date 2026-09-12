# ADR-20260912: Song-title navigation freeze

## Problem and reproduction

The previous song tests used a synthetic GoRouter and entered the detail page
directly. They verified a real large-text layout defect, but missed the reported
freeze when tapping a title in the routed app.

Reproduced with the actual `appRouterProvider`, Korean localization, iOS theme,
`FieldGuidePage`, `FieldGuideMusicPage`, `MusicCatalogTab`, and music controllers.
Only external data/storage boundaries are substituted with deterministic data.

Steps: information → fan library → music/lyrics → songs → song title. The title
tap never returns, before the detail provider or page can render. The test
process uses approximately one CPU core. Pause the isolate instead of leaving
the reproduction running.

Dart VM service stack captured at the freeze:

```text
GoRouterState.of                         package:go_router/src/state.dart:129
AppRouterExtension._resolveCurrentPathFromContext
AppRouterExtension._isInOverlayContext
AppRouterExtension.goToSongDetail
MusicCatalogTab song onTap               music_catalog_tab.dart:369
_SongsList row onTap                     music_catalog_tab.dart:1098
_InkResponseState.handleTap
```

The music archive is opened with `Navigator.push(MaterialPageRoute)` inside the
stateful shell. Installed go_router 14.8.1's `GoRouterState.of(context)` searches
page associations in an unbounded ancestor loop. From this non-GoRouter page,
it reaches a navigator context that returns the same navigator and never finds
a registered page state. A try/catch cannot recover from a synchronous loop.

## Decision

Read `GoRouter.of(context).state.uri.path` in the shared navigation helper.
Installed go_router 14.8.1 defines `GoRouter.state` as the last active go/push
match (`router.dart:264`, `delegate.dart:188`). No ancestor page association is
needed to decide whether a detail belongs to the shell or an overlay.

This fixes the shared path used by song, event, place, news, and post detail
helpers. Preserve their routes, query parameters, navigation strategy, and back
stack. Avoid a dependency upgrade or new navigation system for this defect.

The existing temporary initial-route change predates this repair and is not
part of the fix. No API, DB, authentication, or native setting change is needed.

## Verification

The exact previously frozen route passes after the helper change: title tap,
pending detail/lyrics responses, displayed detail, then back to the music list.
Regression tests exercise real song-list and album-sheet title buttons on iOS
and Android Flutter platform variants. They also open the actual event overlay
through both `go` and `pushNamed`, tap its setlist title, preserve `eventId`, and
return to the same event. All eight entry-flow checks pass.

- Flutter 3.41.0 / Dart 3.11.0 / go_router 14.8.1.
- Full `flutter test --no-pub --concurrency=1 --coverage`: 695 passing tests,
  4m17s. Includes existing navigation, layout, and controller regressions.
- `flutter analyze --no-pub`: no issues. `git diff --check`: clean.
- Coverage increases from 16,237 / 46,045 (35.26%) to 16,739 / 46,044 (36.35%).
  The pre-existing 80% whole-project target remains unmet.
- Original source and test trees match the tested temporary copy.

Validation runs serially with `nice -n 10` and `--concurrency=1`. No simulator or
native build is started. The captured Flutter navigation freeze is reproduced;
an installed-device build and OS-level termination report remain separate QA.

## Pre-push check

Removed the temporary `/information` initial route override; normal startup
remains `/login`. Re-ran all eight catalog/album/setlist entry tests on the
restored startup configuration: passed (Flutter 3.41.0, serial). The full
718-test suite and analysis passed before this debug-only override was removed.
