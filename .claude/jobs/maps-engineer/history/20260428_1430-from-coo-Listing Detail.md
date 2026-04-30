# Message — from coo to maps-engineer — 2026-04-28 14:30

**Topic**: NeighborhoodMapView for Listing Detail
**Priority**: high
**Responding to**: (initial)

## Objective

Build a small read-only Mapbox component for Listing Detail. It renders a fixed-height map centered on a listing's coordinate with a single annotation. Pan/zoom gestures off.

## Acceptance criteria

- New file: `marti/Marti/Views/Shared/NeighborhoodMapView.swift`.
- Public API exactly:
  ```swift
  struct NeighborhoodMapView: View {
      let coordinate: CLLocationCoordinate2D
      var height: CGFloat = 200
  }
  ```
- Body renders a Mapbox `Map` (or whichever v11 SwiftUI bridge is canonical in this project) at `height` pt tall, full container width.
- Camera fixed at `coordinate` with a sensible default zoom for "neighborhood" framing (recommend zoom 13–14, the rest is your call).
- Single annotation at `coordinate` — visual is your call (a simple circle / dot or our existing pin asset, whichever is least code). No clustering. No price label.
- Pan, zoom, rotate, and pitch gestures all disabled. Tap on the annotation is a no-op.
- Reuses existing `MapboxConfig.configure()` — no new config, no new SPM dependency, no Mapbox v11 ref change.
- Build passes:
  ```
  xcodebuild -project marti/Marti.xcodeproj -scheme Marti -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
  ```
- Park doc written at `.claude/jobs/maps-engineer/park/2026-04-28-maps-engineer.md`.

## Context

`/ship-feature Listing Detail` is in flight. Backend-engineer is skipped — no schema change. ios-engineer will consume your component to render the "approximate location" map embed required by PRD Feature 2 acceptance criterion 5 ("Map showing approximate location (neighborhood level, not exact address)"). Discovery's full-bleed Mapbox view is too entangled with the discovery ViewModel (clusters, `searchThisArea`, selection state) to reuse — we want a minimal, dependency-free read-only embed.

## Relevant files / specs

- Spec: `docs/specs/Listing Detail.md` (locked decisions in the Open Questions section)
- PRD: `docs/PRD.md` Feature 2 acceptance criterion 5
- Existing Mapbox integration reference: `marti/Marti/Views/Discovery/ListingMapView.swift`, `marti/Marti/Services/MapboxConfig.swift`, `MartiApp.swift` (where `MapboxConfig.configure()` is called)
- Architecture: `docs/ARCHITECTURE.md` (Views are dumb, no business logic in the body)
- Mapbox SPM is currently pinned to `main` — that's a separate ship-prep blocker; do NOT change the pin in this work.

## Constraints

- No new SPM packages.
- No changes to `MapboxConfig`, `MartiApp.swift`, or any Discovery file.
- Do NOT pin Mapbox to a v11 release tag in this PR — that's a separate item in `STATUS.md` blockers.
- Do NOT add `@Observable` view models for this component — it's a leaf design-system primitive, not a screen.
- Test coverage for this component is optional per `.claude/rules/testing.md` ("Snapshot tests only for design-system primitives") — your judgment.
- Scope: this component only. Don't refactor `ListingMapView`. Don't extract a shared map factory.

## Expected response

Reply by writing your park doc and returning a structured summary in your final message that includes:

1. The exact file path you created.
2. The public API as it shipped (init signature + any defaulted params).
3. The annotation visual you chose (e.g., "8pt cyan circle" / "existing price pin without the label" / etc.) and zoom level.
4. Confirmation the build is green (paste the last few lines of the xcodebuild output).
5. Anything you discovered that ios-engineer needs to know when wiring this in.
