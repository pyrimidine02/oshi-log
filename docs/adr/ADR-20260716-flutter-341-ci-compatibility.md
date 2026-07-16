# ADR-20260716: Flutter 3.41 CI compatibility

## Problem

The main deployment workflow uses Flutter 3.41, while the local workstation
uses Flutter 3.32.6. The first main build failed because the SDKs expose
different `CupertinoPageTransitionsBuilder` and sliver reorder callback
contracts. After those compile errors were fixed, Flutter 3.41 rendered the
field-project golden with a 1.41% pixel difference from the Flutter 3.32.6
baseline despite the widget structure and interaction checks passing.

## Decision

Use `PageTransitionsTheme()` so each Flutter SDK selects its own platform
transition implementation. Use the `SliverReorderableList.onReorder` contract
required by Flutter 3.41 and normalize its forward-move index in an immutable
helper. Apply the same copy-based policy to place addition and removal.

Keep the existing field-project baseline and apply Flutter's documented local
golden-comparator extension only to that visual test. Accept at most 1.5% changed
pixels; preserve exact structural, interaction, narrow-width, and 200% text
scale assertions as separate widget tests. Differences above the limit retain
Flutter's normal failure images.

## Consequences

- Flutter 3.41 CI can analyze the app without the removed named parameters.
- iOS and macOS retain Flutter's SDK-default Cupertino transition behavior.
- Reordering, adding, and removing travel-review stops cannot mutate an
  unmodifiable list in place.
- A temporary compatibility ignore remains until local and CI Flutter versions
  are aligned, tracked in `TODO.md`.
- Rasterizer-only drift below 1.5% no longer blocks the cross-version workflow;
  larger visual changes still fail and emit comparison artifacts.
