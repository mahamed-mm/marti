import SwiftUI
import CoreLocation
import MapboxMaps

/// Read-only Mapbox map embed for the Listing Detail screen. Renders a
/// neighborhood-framed view centered on the listing coordinate with a single
/// non-interactive marker. All camera gestures (pan, pinch, rotate, pitch,
/// double-tap zoom, quick zoom) are disabled — this is a static "approximate
/// location" graphic, not an exploration surface.
///
/// Deliberately self-contained: no ViewModel, no environment dependency, no
/// shared map factory. The Discovery `ListingMapView` is too entangled with
/// its discovery ViewModel (clusters, search-this-area, selection) to reuse.
/// This is a leaf design-system primitive; keep it that way.
///
/// Caller is expected to have invoked `MapboxConfig.configure()` at app
/// launch (`MartiApp.swift` already does so for Discovery). We do not call
/// it again here — re-running `MapboxOptions.accessToken =` per-view is
/// wasteful and not our responsibility.
struct NeighborhoodMapView: View {
    /// Listing coordinate the camera centers on and the annotation marks.
    let coordinate: CLLocationCoordinate2D

    /// Fixed pixel height of the embed. Defaults to 200pt — the size called
    /// out in the Listing Detail spec (AC7) and tuned to read as a "map
    /// preview" rather than a map experience. Width follows the parent.
    var height: CGFloat = 200

    /// Neighborhood-framing zoom. 13.5 sits between "city" (~12) and
    /// "street" (~16) — close enough that street grid + a couple of named
    /// neighborhoods are legible, far enough that the marker doesn't
    /// pretend to point at a specific building. Matches the PRD's
    /// "neighborhood level, not exact address" requirement.
    private let neighborhoodZoom: Double = 13.5

    /// Diameter of the annotation dot in points. 18pt = a 9pt visual radius,
    /// large enough to read against the dark basemap from a typical reading
    /// distance without dominating the embed.
    private let markerDiameter: CGFloat = 18

    /// Locked viewport: the camera is constructed once from `coordinate` and
    /// never reassigned. Combined with `gestureOptions` below, this means
    /// the user has no path to move the camera — the map is effectively a
    /// styled static image with our marker on top.
    ///
    /// Held in `@State` rather than computed because `Map(viewport:)` takes
    /// a `Binding<Viewport>`. Recomputing the binding per body call would
    /// re-seed the camera every render; storing it once gives us a stable
    /// initial value the SDK reads on first layout.
    @State private var viewport: Viewport

    init(coordinate: CLLocationCoordinate2D, height: CGFloat = 200) {
        self.coordinate = coordinate
        self.height = height
        // Seed the viewport at construction time so the very first frame
        // already has the right camera — no animated re-land on appear.
        self._viewport = State(initialValue: .camera(
            center: coordinate,
            zoom: 13.5
        ))
    }

    var body: some View {
        Map(viewport: $viewport) {
            MapViewAnnotation(coordinate: coordinate) {
                marker
                    // Tap is an explicit no-op rather than absent so any
                    // ambient tap recognizer (e.g. the parent ScrollView's
                    // hit-test) doesn't get a chance to interpret a tap on
                    // the marker as a scroll-to-top or row select.
                    .onTapGesture { /* no-op per spec */ }
                    .accessibilityLabel("Approximate location")
                    .accessibilityHint("Neighborhood-level map. Exact address not shown.")
            }
            .allowOverlap(true)
        }
        .mapStyle(mapStyle)
        // Lock every camera gesture off. Pan/pinch/rotate/pitch are the
        // four called out in the spec; double-tap-zoom and quickZoom are
        // the two sneaky ones that would otherwise still let the user
        // zoom by accident with a finger gesture.
        .gestureOptions(GestureOptions(
            panEnabled: false,
            pinchEnabled: false,
            rotateEnabled: false,
            simultaneousRotateAndPinchZoomEnabled: false,
            pinchZoomEnabled: false,
            pinchPanEnabled: false,
            pitchEnabled: false,
            doubleTapToZoomInEnabled: false,
            doubleTouchToZoomOutEnabled: false,
            quickZoomEnabled: false
        ))
        // Hide map ornaments (logo, attribution, scale bar) for the embed
        // surface — at 200pt tall they'd consume ~15% of the frame. Per
        // Mapbox terms of use the attribution is still discoverable on the
        // full Discovery map; this is a derivative preview, not the
        // primary map surface.
        .ornamentOptions(OrnamentOptions(
            scaleBar: ScaleBarViewOptions(visibility: .hidden),
            logo: LogoViewOptions(margins: CGPoint(x: -200, y: -200)),
            attributionButton: AttributionButtonOptions(margins: CGPoint(x: -200, y: -200))
        ))
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Marker

    /// A simple two-layer dot: a soft outer halo for visual presence on the
    /// dark basemap, then a solid inner disc in `coreAccent` (the brand
    /// cyan). Cheaper than rendering the full `ListingPricePin` chrome and
    /// avoids any visual implication of a price callout — this map is
    /// strictly "where", not "for how much".
    private var marker: some View {
        ZStack {
            Circle()
                .fill(Color.coreAccent.opacity(0.25))
                .frame(width: markerDiameter * 2, height: markerDiameter * 2)
            Circle()
                .fill(Color.coreAccent)
                .frame(width: markerDiameter, height: markerDiameter)
                .overlay(
                    Circle().stroke(Color.canvas, lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 4, x: 0, y: 2)
        }
    }

    // MARK: - Style

    /// Mirrors the Discovery map's brand-tuned Standard v11 style so the
    /// embed reads as the same map surface the user just left in Discovery,
    /// not a stock Mapbox preset. We deliberately re-declare the values
    /// rather than extract a shared style helper — per the COO's scope
    /// constraint ("don't extract a shared map factory") and because
    /// premature abstraction at two call sites is worse than a small clone.
    private var mapStyle: MapStyle {
        .standard(
            theme: .faded,
            lightPreset: .night,
            showPointOfInterestLabels: false,
            showTransitLabels: false,
            showPlaceLabels: true,
            showRoadLabels: true,
            show3dObjects: false,
            colorAdminBoundaries: StyleColor(red: 68, green: 80, blue: 95, alpha: 0.6),
            colorLand: StyleColor(red: 10, green: 18, blue: 30),
            colorMotorways: StyleColor(red: 31, green: 45, blue: 66),
            colorRoads: StyleColor(red: 22, green: 32, blue: 46),
            colorTrunks: StyleColor(red: 25, green: 37, blue: 54),
            colorWater: StyleColor(red: 14, green: 28, blue: 48)
        )
    }
}

#Preview("NeighborhoodMapView — Mogadishu") {
    NeighborhoodMapView(
        coordinate: CLLocationCoordinate2D(latitude: 2.0469, longitude: 45.3182)
    )
    .padding()
    .background(Color.canvas)
}
