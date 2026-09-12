# ADR: Community deep-page consistency

Date: 2026-09-12
Status: accepted; local validation complete, installed-device QA pending

## Problem

Community details, composers, travel reviews, profiles and action sheets used
inconsistent captions, form styles and action treatments. The title-tap freeze
is tracked separately in ADR-20260912-song-title-navigation-freeze.md.

Reproduction at 320dp and 200% text exposed a 144px overflow in the logged-out
comment prompt, and a 16px overflow when scrolling into comment reply actions.
Action/confirmation sheets also overflowed by 175px/126px at 320x480 with 200%
text. iOS shared sheets applied the 280px keyboard inset twice, leaving content
280px above the keyboard. Dedicated tests reproduce each defect.
Shared text/icon button minimum sizes were 44dp rather than the project 48dp
standard. Existing large-text detail coverage did not scroll to these actions.

## Decision and scope

Keep existing routes, Riverpod state and repository contracts. Apply the shared
Material theme to deep pages; retain actual travel context through visit order,
places, concert links and visit history. Remove redundant ornamental English
captions. Keep article titles, author context and readable text hierarchy.

Use labeled native actions: primary save/submit, secondary cancel/close,
text actions for social interactions, destructive operations in existing menus
and confirmation flows. Minimum targets are 48dp. Reflow rather than shrink text;
scroll modal content so actions remain reachable on small screens and keyboards.
Reuse the existing document editor for post and travel-review composition.

No new packages, architecture layers, route strategies or native configuration.
No production data mutations. Existing autosave, upload, permissions, reporting,
follow/block and server payloads must retain their behavior.

## Contract evidence

Adjacent backend: `../oshilog-api/server/src/main/kotlin/org/pyrimidines/oshilog/`.
`community/dto/PostDtos.kt` defines title/content, topic (32 chars), tags (5 entries,
16 chars each), author and counters. Post create/update keep the current repository
mapping. Travel review edits remain title/content/routeNote patches; creation
retains stops/events/proof and subject IDs. Existing PostgreSQL/Flyway schema
review is recorded in ADR-20260912-mobile-ui-consistency.md. No schema changes.

## Alternatives

A new page framework or unified feature controller would increase regression
risk without fixing the layout defects. A color-only pass would leave keyboard,
large-text, modal and action-discoverability problems unresolved.

## Validation and performance

Use Flutter 3.41.0 / Dart 3.11.0 (CI version), a separate temporary workspace and
serial low-priority tests. No simultaneous simulator, native build or test runner.
Test actual callbacks, text input, scroll, dismissal, autosave and limits.
No new background work or animations; wrapping and scrolling are local layout
changes. Native-device frame timing and VoiceOver/TalkBack remain explicit QA.

Results on Flutter 3.41.0 / Dart 3.11.0:

- Full serial suite: **718 passed**, 5m12s. Log:
  `/tmp/oshilog-community-full-tests.log`.
- `flutter analyze --no-pub`: **no issues**, 5.7s. Log:
  `/tmp/oshilog-community-analyze.log`.
- Line coverage: **17,424/46,126 (37.77%)**, up from
  **16,739/46,044 (36.35%)** before this pass. The repository-wide 80% target
  remains unmet existing debt; this change does not claim to satisfy it.
- Post/menu/confirmation overflow and iOS keyboard displacement were first
  reproduced in failing tests and then passed with the fixes.
- Modal tests inject MediaQuery above the Navigator through MaterialApp.builder;
  assertions verify actions remain above the simulated keyboard, rather than
  testing only an underlying page's MediaQuery.
- Post social actions, comment sorting, reply expansion, sending, profile actions,
  date selection and modal close/selection retain tested callbacks. Existing
  autosave and route regression tests pass in the full suite.
- Read-only cross-review found no remaining concrete regressions in the changed
  callbacks, permissions, editor contracts and shared sheet paths.
- Original `lib/` and `test/` match the tested copy by checksum. `git diff --check`
  passes. Tests ran one at a time with `nice -n 10`; no simulator/native build.

Rendered fixture previews (Flutter widgets, not installed-app/server screenshots):
`/tmp/oshilog-community-post-light.png`, `/tmp/oshilog-community-post-dark.png`,
`/tmp/oshilog-community-post-compact.png`,
`/tmp/oshilog-community-profile-light.png`, `/tmp/oshilog-community-profile-dark.png`,
`/tmp/oshilog-community-travel-compose.png`. The final profile previews confirm
that the synthetic route artwork is absent. Native-device accessibility, keyboard
behavior and frame timing remain in TODO.md. No claim of installed-app validation.

## Reviewed flows

| Surface | Action behavior |
| --- | --- |
| Post detail/comments | Labeled like/save/comment; native sort; wrapping replies; typing/send |
| Post create/edit | Shared editor; topic/tag close and selection; existing autosave |
| Travel review create/edit | Same editor with travel limits; primary submit and cancel |
| Travel metadata/place picker | Date and selected-place context; explicit modal close |
| Public/self profile | Follow/message/more; edit/title actions; long-label reflow |
| Community settings/connections | Same action hierarchy; concise title and owner context |
| Shared action/confirmation sheets | Scrollable choices; adaptive confirmation actions; keyboard positioning |

Public profile placeholder artwork was removed after visual inspection: its
synthetic route curve/grid represented no real trip. Actual user cover images
remain. Private role values are not used to infer activity rankings; the existing
access-level label is labeled as account level.

## Sources

Rechecked 2026-09-12. Current Flutter docs identify Flutter 3.47.2; implementation
uses APIs available in the tested CI SDK 3.41.0.

- Flutter accessibility: https://docs.flutter.dev/ui/accessibility
- Flutter adaptive/responsive guidance:
  https://docs.flutter.dev/ui/adaptive-responsive/best-practices
- Material research, design reference rather than a Flutter API contract:
  https://design.google/library/expressive-material-design-google-research

Travel identity and restrained visual treatment are product decisions informed
by these references, not claims that a particular aesthetic is mandatory.
