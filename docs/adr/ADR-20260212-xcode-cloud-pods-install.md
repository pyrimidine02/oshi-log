# ADR-20260212: Xcode Cloud CocoaPods Install Script

## Status
Accepted

## Context
Xcode Cloud archives failed because CocoaPods-generated `.xcfilelist` files were
missing in the CI environment. The workflow UI does not expose a script editor
in the current setup, so pods must be installed via repository scripts.

## Decision
- Add `ci_post_clone.sh` at the repository root to run `flutter pub get` and
  `pod install --repo-update` for Xcode Cloud builds.
- Log each dependency step and retry `flutter pub get` and
  `pod install --repo-update` once so one transient registry/network failure
  does not fail an otherwise valid archive.
- Keep Claude worktrees local-only. Remove dangling worktree gitlinks from the
  repository index because Xcode Cloud cannot resolve them as submodules.

## Alternatives Considered
- Rely on Xcode Cloud UI pre-build scripts (not available in this configuration).
- Commit `Pods/` to the repository (not preferred).

## Consequences
- CocoaPods artifacts are generated on CI, preventing `.xcfilelist` lookup
  failures during archive.
- Bootstrap failures identify the exact dependency step, and transient
  dependency failures get one bounded retry.

## Verification

- `bash -n ci_post_clone.sh`
- `git submodule status` exits successfully without dangling worktree entries.
