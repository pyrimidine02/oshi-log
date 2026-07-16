# ADR-20260716: Flutter 3.41 CI compatibility

## Problem

The main deployment workflow uses Flutter 3.41, while the local workstation
uses Flutter 3.32.6. The first main build failed because the SDKs expose
different `CupertinoPageTransitionsBuilder` and sliver reorder callback
contracts.

## Decision

Use `PageTransitionsTheme()` so each Flutter SDK selects its own platform
transition implementation. Use the `SliverReorderableList.onReorder` contract
required by Flutter 3.41 and normalize its forward-move index in an immutable
helper. Apply the same copy-based policy to place addition and removal.

## Consequences

- Flutter 3.41 CI can analyze the app without the removed named parameters.
- iOS and macOS retain Flutter's SDK-default Cupertino transition behavior.
- Reordering, adding, and removing travel-review stops cannot mutate an
  unmodifiable list in place.
- A temporary compatibility ignore remains until local and CI Flutter versions
  are aligned, tracked in `TODO.md`.
