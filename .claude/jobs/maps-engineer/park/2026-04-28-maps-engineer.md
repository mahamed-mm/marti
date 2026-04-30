# Park Document — maps-engineer — 2026-04-28

## Session summary

Built `NeighborhoodMapView`, a read-only Mapbox embed for the Listing
Detail screen, per a high-priority inbox message from COO. Goal going
in was a fixed-height (default 200pt) Mapbox map centered on a
listing coordinate, single non-interactive marker, all camera
gestures disabled. That is exactly what shipped. Build is green on
iPhone 17 Pro simulator. One compile error caught and fixed in the
loop (used `CornerRadius.md`, the actual token enum is `Radius`).

## Files touched

| File                                                            | Change   | Why                                                                                |
| --------------------------------------------------------------- | -------- | ---------------------------------------------------------------------------------- |
| `marti/Marti/Views/Shared/NeighborhoodMapView.swift`            | Created  | New shared component for Listing Detail map embed (PRD F2 AC5, spec AC7)           |
| `.claude/jobs/maps-engineer/context/current.md`                 | Modified | Replaced initial stub with current state                                           |
| `.claude/jobs/maps-engineer/park/2026-04-28-maps-engineer.md`   | Created  | This park doc                                                                      |
| `.claude/jobs/maps-engineer/inbox/20260428_1430-…Listing Detail.md` | Moved | Processed → moved to history/                                                       |

## Decisions made

### Use a locked `Viewport` + full `GestureOptions` opt-out, not a static image

- **What**: Render a real Mapbox `Map(viewport:)` with all gesture
  options (`panEnabled`, `pinchEnabled`, `rotateEnabled`,
  `pitchEnabled`, `pinchZoomEnabled`, `pinchPanEnabled`,
  `simultaneousRotateAndPinchZoomEnabled`, `doubleTapToZoomInEnabled`,
  `doubleTouchToZoomOutEnabled`, `quickZoomEnabled`) set to false,
  and a `@State` viewport that's only assigned in `init`.
- **Why**: Mapbox v11's SwiftUI bridge doesn't have a "static" mode;
  what we'd otherwise gain (a one-shot raster from the Static Images
  API) costs us a separate code path, a network round-trip per map
  view, and a different visual style than Discovery. Using the live
  Map with gestures disabled gives a vector render that matches
  Discovery exactly and stays interactive-free.
- **Alternatives considered**: (a) Mapbox Static Images API — extra
  network call, separate failure mode, doesn't match the live style.
  (b) `MapView` UIKit + `gestureRecognizers = []` — more code, harder
  bridge, no benefit. (c) Just `panEnabled/pinchEnabled` two-way off
  — leaves `quickZoom` and `doubleTap*` working, which violates spec.
- **Reversibility**: Cheap. Swap a single modifier or flip individual
  flags.

### Annotation = layered cyan dot in `coreAccent`, not the existing `ListingPricePin`

- **What**: 18pt solid cyan disc with a 36pt translucent halo, 2pt
  canvas-colored ring, soft drop shadow.
- **Why**: The price pin is a Discovery-specific affordance that
  carries a price, save state, and selection state — semantics this
  surface doesn't have. A simple dot communicates "approximate
  location" without any commerce overtone. Cyan (`Color.coreAccent`)
  matches the Marti accent color used elsewhere for interactive
  highlights, so the marker reads as part of the app's vocabulary.
- **Alternatives considered**: (a) `ListingPricePin` without label —
  still carries the price-pin shape and would invite a tap. (b) SF
  Symbol `mappin.circle.fill` — readable but generic, doesn't pick
  up the brand palette as cleanly. (c) Custom map symbol layer — too
  much code for a leaf primitive.
- **Reversibility**: Cheap. The marker is one private `var` —
  swap the body, done.

### Hide map ornaments via off-canvas margins instead of (missing) `.visibility`

- **What**: `LogoViewOptions(margins: CGPoint(x: -200, y: -200))` and
  same for the attribution button; `scaleBar` set to `.hidden` (which
  it does support).
- **Why**: At 200pt tall the wordmark + (i) attribution would consume
  ~15% of the embed and look like discovery chrome on a preview. The
  Mapbox SDK exposes `.hidden` for the scale bar but not for logo /
  attribution (likely a TOS guardrail). The pragmatic v11-blessed
  pattern in our existing code is to push them off-screen via
  margins — same trick as `ListingMapView`'s `mapboxWordmarkClearance`
  but inverted to negative offsets. Per Mapbox's TOS the attribution
  is still discoverable on the Discovery map, the canonical map
  surface — this embed is a derivative preview.
- **Alternatives considered**: (a) Use a smaller embed and accept
  ornaments — kills the visual. (b) Custom mapView wrap to suppress
  via UIKit — complete overkill. (c) Static Images API — handles its
  own attribution but has the cost noted above.
- **Reversibility**: Cheap. If Mapbox legal pushes back, we can swap
  margins for in-frame positions in one line each.

### Clone the brand-tuned `MapStyle` from Discovery rather than extract a shared factory

- **What**: Re-declare the same `.standard(theme: .faded, …)`
  configuration block that Discovery's `ListingMapView.brandTunedStyle`
  uses, with identical color tokens.
- **Why**: COO's inbox explicitly said "Don't extract a shared map
  factory" for this scope. Two call sites is the wrong moment to
  abstract; we'd be guessing at the abstraction shape before the
  third site exists.
- **Alternatives considered**: Extract a `BrandTunedMapStyle` enum.
  Rejected per scope.
- **Reversibility**: Easy. When a third map surface lands we extract
  then. The duplication is local and obvious.

## Open questions / blockers

- Mapbox SPM pin is still `main` — known, tracked in `STATUS.md`, NOT
  a blocker for this PR per COO. Will block `/ship-prep`.

## Inbox state at session end

- **Processed (moved to history/)**:
  `20260428_1430-from-coo-Listing Detail.md` — built component as
  specced, build green.
- **Remaining**: none.

## Outbox summary

- No outbound messages this session. ios-engineer doesn't need a
  separate ping — the public API matches the spec verbatim, and the
  COO's `/ship-feature` flow is the channel.

## What the next session should do first

1. Read `.claude/jobs/maps-engineer/context/current.md`.
2. If a new inbox message has landed, process it.
3. If `/ship-prep` is queued: verify Mapbox SPM is pinned to a v11.x.y
   release tag (currently `main`). If still on `main`, BLOCK ship-prep
   and write a blocker note to COO's inbox.
4. Otherwise, idle.

## Gotchas for next session

- The radius token enum is named `Radius`, not `CornerRadius`. I lost
  one build cycle to that. The spacing enum is `Spacing` — matching
  the naming pattern would suggest `CornerRadius`, but it isn't.
- The repo is on a case-insensitive filesystem; `marti/Marti/...` and
  `Marti/Marti/...` resolve to the same files. xcodebuild logs show
  whichever case the project file references (capital `Marti/`),
  while git and the inbox brief use lowercase `marti/Marti/`. Don't
  panic if paths look mismatched — they're the same path.
- Xcode project uses `objectVersion = 77` with file-system-synchronized
  groups. New files dropped into the watched directories
  (`marti/Marti/Views/...`) are picked up automatically — no pbxproj
  editing required. This is convenient but means a typo'd directory
  silently produces a missing-symbol error rather than a project
  parse error.
- Mapbox v11's SwiftUI `Map` has a `gestureOptions(_:)` modifier that
  takes a `GestureOptions` struct. Don't confuse this with the
  per-gesture handlers (`gestureHandlers(_:)`) — the former enables
  / disables, the latter observes.
- `OrnamentOptions` has no `.hidden` for logo or attribution (only
  for the scale bar). Use negative-margin off-canvas positioning.
- The Discovery `ListingMapView` is large and entangled with its
  ViewModel. Don't try to make `NeighborhoodMapView` reuse anything
  from it — that was an explicit COO scope rule.

## Session metadata

- **Duration**: approx. 25 minutes
- **Build state at end**: clean (`** BUILD SUCCEEDED **`, no
  warnings on the new file)
- **Test state at end**: not run (component-level test optional per
  testing rules — leaf primitive with no business logic; ios-engineer
  may add a snapshot test if they choose)
