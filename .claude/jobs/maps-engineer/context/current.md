# Current state — maps-engineer

> Last updated: 2026-04-28 (post-NeighborhoodMapView ship)

## What's in flight

Nothing. NeighborhoodMapView is shipped and the build is green.

## What's clean / stable

- `marti/Marti/Views/Shared/NeighborhoodMapView.swift` — read-only
  Mapbox embed for Listing Detail. Public API:
  ```swift
  struct NeighborhoodMapView: View {
      let coordinate: CLLocationCoordinate2D
      var height: CGFloat = 200
      init(coordinate: CLLocationCoordinate2D, height: CGFloat = 200)
  }
  ```
  Defaults: zoom 13.5 (neighborhood framing), all camera gestures
  disabled via `GestureOptions(panEnabled: false, …)`, ornaments
  hidden via off-canvas margins, brand-tuned Standard v11 style
  cloned from `ListingMapView`.
- `marti/Marti/Views/Discovery/ListingMapView.swift` — full-bleed
  discovery map. Untouched this session.
- `marti/Marti/Services/MapboxConfig.swift` — accessor for
  `MBXAccessToken`. Untouched this session.
- `marti/Marti/Extensions/MapConfiguration.swift` — default user
  location stand-in. Untouched.

## What's blocked

- Mapbox SPM pin is still `main`. This is a known ship-prep blocker
  tracked in `STATUS.md`, NOT something to fix mid-feature. Pin to a
  v11.x.y release tag before the next `/ship-prep`.

## Open questions

- None.

## Next actions

- Wait for ios-engineer to wire `NeighborhoodMapView` into Listing
  Detail. If they hit issues at the boundary (e.g. height in a
  ScrollView, accessibility focus order), respond to inbox.
- Before next `/ship-prep`: pin Mapbox SPM to a released v11 tag and
  message COO with the chosen version.
