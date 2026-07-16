# ADR-20260716: Mobile-server endpoint contract sync

## Problem

Current server work removed client-awarded activity XP, added exact per-place
statistics, and introduced credential-bound recovery for inactive accounts.
Mobile still called the removed XP endpoint, derived place counts from capped
ranking lists, and treated inactive accounts as generic login failures.

## Alternatives

1. Keep compatibility endpoints on the server.
2. Automatically reactivate inactive accounts during normal login.
3. Move mobile to server-owned XP and statistics, then require explicit user
   confirmation before account recovery.

## Decision

Use option 3. Delete the obsolete XP client surface and all callers. Read place
counts from `GET /projects/{projectId}/places/{placeId}/stats`. When login
returns `ACCOUNT_INACTIVE`, ask for confirmation and then call the matching
password, Google, or Apple recovery endpoint. Google and Apple reuse the fresh
provider proof captured by the immediately preceding failed login exactly once;
they do not reopen the native provider UI after confirmation.

Update the mobile endpoint catalog and contract checks for the current server
delta. Keep the full OpenAPI JSON unchanged until it can be generated from a
running stabilized server; controller annotations alone cannot reproduce
request and response schemas safely.

## Consequences

- XP ownership and deduplication stay on the server event pipeline.
- Place statistics use one exact request instead of two capped ranking scans.
- Account reactivation remains explicit and credential-bound.
- Recovery endpoints bypass stale local authentication and provider proofs are
  retained only in memory for a single confirmed attempt.
- X/Twitter-only inactive accounts need a matching server recovery endpoint.
- `api_docs.json` refresh remains tracked in `TODO.md`.
