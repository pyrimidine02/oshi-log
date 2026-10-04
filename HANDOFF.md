# Redesign handoff — 2026-10-04

User authorized completion of the approved PR9–21 plan and deferred PR8c.
Workspace: `/Users/sonhoyoung/dev/oshi-log-redesign`.
Branch: `feature/oshilog-redesign`; starting commit: `497ef46`.
The original `girlsbandtabi_app` checkout was left untouched. Existing PR9 dirty
work was preserved; its patch and untracked files are backed up in the evidence
directory below. Root remains the only Git writer.

## Implemented

- Persistent Home / Map / Live / Community / My routing, compatible legacy
  aliases, event preparation, on-site place tools, saved items and unified records.
- Map viewport search and list fallback, collections and shared spoiler guards,
  song preparation and archive navigation, community review entry and utility states.
- Skippable onboarding, guest language/theme preferences, action-time login,
  cancellation safety, auxiliary-auth return routes, and explicit notification permission.
- Account-scoped Today lists and text downloads; local private trips, durable
  photos, candidate merge/split and date confirmation. Only explicit selections
  seed public review drafts; photo uploads wait for final public submission.
- Session generations reject stale API dispatch, responses and refreshes. Cache
  clearing prevents delayed work from restoring old-account data.
- PR8c: 85 shared files moved to `platform` / `design_system`, 540 Dart files'
  imports updated, dependency allowlist empty.
- Final audit fixes: public-selection limits match server (1–20 places, at most
  10 events / photos); lyrics require explicit rights and current availability,
  reject unconfirmed region restrictions and expire while visible; archive
  ordinals remain readable at 200% text. Added missing JA/KO visual matrices.

## Verification

- Baseline isolated with initial dirty work: 808 passed, 5 pre-existing failures;
  line coverage 18,578 / 47,638 = 39.00%.
- Final full suite: `flutter test --coverage --concurrency=1 --no-pub` —
  1,112 passed, 0 failed (6m50s). Line coverage: 22,708 / 50,385 = 45.07%,
  up 6.07 percentage points. Architecture violations and allowlist: zero.
- Formatting: 581 changed Dart files checked, no formatting changes needed.
- `flutter analyze --no-pub`: No issues found (3.5s).
- `flutter build bundle --no-pub`: exit 0; compiled kernel and asset manifests
  verified under `build/flutter_assets`. No signed native build produced.
- Evidence: `/tmp/oshilog-redesign-20261004-evidence/`.
- Detailed scope and final results:
  `docs/product/redesign-implementation-status-20261004.md`.

## Remaining dependencies and limits

- Server S1/S2/S4/S9/S19: public reads, home event status, planned attendance,
  event-only reviews and private-album sync. Current public reviews require a
  place and publish immediately; local private albums never use that endpoint.
- Region-restricted lyrics need an authoritative region contract; app language
  does not establish permission. Call-source metadata is unavailable.
- External browser OAuth restores a validated in-memory URI without replaying
  the pending action. Process-death restoration is not guaranteed.
- Local private data has no server recovery after app-data removal. Offline
  Today downloads contain text only, not map tiles or media.
- Flutter 3.47.2 / Dart 3.13.2 installed; CI pins Flutter 3.41.0 and still needs
  verification there. Goldens use repository fonts and prove layout, not actual
  Japanese OS glyphs. Real map tiles, permission/OAuth UI and native performance
  need device QA. No web target exists; bundle compilation is not a signed build.

No push, deployment, server/DB mutation, credential or native-signing change.
