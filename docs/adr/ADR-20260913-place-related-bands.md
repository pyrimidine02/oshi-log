# ADR: Preserve place associations and filter related bands

Date: 2026-09-13. Status: accepted within the requested place-data correction.

## Problem

Place details rendered every band from the selected project. The server supplied
`unitIds`, but DTO decoding and cached serialization discarded it. The DEV detail
contract also uses `descriptionMarkdown`, which the app did not read.

## Decision

Retain unit, project and character IDs through DTO serialization and domain
mapping. Filter the existing project-scoped Riverpod band result by the place's
explicit unit IDs; empty IDs produce the existing localized empty state. Keep
selected-project scope for shared places. Read Markdown descriptions as a
fallback to the legacy description field. Bump only the place-detail cache key
to v2 so older cache rows cannot hide the newly retained fields.

## Alternatives and effects

Changing place memberships cannot repair a screen that ignores them. Fetching
separate band details or changing global project selection adds requests and
scope changes unnecessary for this fix. Existing routes, dependencies and native
settings remain unchanged. Filtering is linear in the project band list and skips
the band request entirely when the place has no associations.

## Validation

Flutter 3.41.0: 735 unit/widget tests pass, including association filtering and
DTO-to-JSON-to-domain preservation. Static analysis passes. API field names were
checked against authenticated DEV place detail responses on 2026-09-13. Installed
TestFlight behavior requires a new app build and device QA.
