import SwiftUI
import CoreLocation
import MapboxMaps

/// One renderable unit in the map annotation layer. Either a lone `Listing`
/// pin or a `PricePinClusterGroup` aggregating 2+ listings that would visually
/// collide at the current zoom. See
/// `ListingMapView.recomputeAnnotationLayout(proxy:)` for the grouping rules.
enum MapAnnotationItem: Identifiable, Equatable {
    case single(Listing)
    case cluster(PricePinClusterGroup)

    var id: Int {
        switch self {
        case .single(let listing):
            // Stable, hashable id scoped under a tag so it cannot collide with
            // a cluster's id (which is a hash of sorted member UUIDs).
            var hasher = Hasher()
            hasher.combine("single")
            hasher.combine(listing.id)
            return hasher.finalize()
        case .cluster(let group):
            return group.id
        }
    }

    /// Compares two `MapAnnotationItem` values for equality.
    /// 
    /// When both items are `.single`, equality is true if their `listing.id` values match. When both are `.cluster`, equality is determined by the cluster group equality. Items of different cases are not equal.
    /// Compare two `MapAnnotationItem` values for structural equality.
    /// 
    /// When both values are `.single`, equality is determined by comparing their `Listing.id`.
    /// When both values are `.cluster`, equality is delegated to the cluster group's `Equatable` conformance.
    /// Values with different enum cases are not equal.
    /// - Returns: `true` if both items represent the same listing (`.single`) or the same cluster (`.cluster`), `false` otherwise.
    static func == (lhs: MapAnnotationItem, rhs: MapAnnotationItem) -> Bool {
        switch (lhs, rhs) {
        case (.single(let l), .single(let r)):
            return l.id == r.id
        case (.cluster(let l), .cluster(let r)):
            return l == r
        default:
            return false
        }
    }
}

struct ListingMapView: View {
    @Bindable var viewModel: ListingDiscoveryViewModel

    /// Height of floating chrome hovering over the bottom of the map (fee tag +
    /// selected-listing card / empty-state pill + its bottom padding above the
    /// floating tab bar). Drives the Mapbox ornament margins so the wordmark
    /// / attribution sit with our UI rather than under it.
    var bottomChromeInset: CGFloat = 0

    /// UUID bumped by the parent (`DiscoveryView`) every time the recenter
    /// button is tapped. The `.onChange` observer re-lands the camera on
    /// `viewModel.targetCamera` — this keeps the parent ignorant of our
    /// private `viewport` state while still letting it trigger a re-land.
    var recenterTrigger: UUID = UUID()

    /// UUID bumped by the parent when the user taps the "Search this area"
    /// pill. The `.onChange` observer resets the pan anchor to the current
    /// camera center and re-reads visible listings so the ViewModel's count
    /// reflects what's on screen.
    var searchThisAreaTrigger: UUID = UUID()

    /// Bound to the parent so it can show/hide the "Search this area" pill.
    /// Flips true when the camera center drifts more than
    /// `panThresholdDegrees` from `anchorCameraCenter`; flips back when a
    /// re-anchor (initial land, city change, pill tap) resets the anchor.
    @Binding var hasPannedFromAnchor: Bool

    init(
        viewModel: ListingDiscoveryViewModel,
        bottomChromeInset: CGFloat = 0,
        recenterTrigger: UUID = UUID(),
        searchThisAreaTrigger: UUID = UUID(),
        hasPannedFromAnchor: Binding<Bool> = .constant(false)
    ) {
        self.viewModel = viewModel
        self.bottomChromeInset = bottomChromeInset
        self.recenterTrigger = recenterTrigger
        self.searchThisAreaTrigger = searchThisAreaTrigger
        self._hasPannedFromAnchor = hasPannedFromAnchor
    }

    @State private var viewport: Viewport = .camera(
        center: CLLocationCoordinate2D(latitude: 2.0469, longitude: 45.3182),
        zoom: 11
    )
    @State private var loadFailed: Bool = false
    /// Guards the one-shot initial camera animation. Flipping true on first
    /// appear stops us from re-snapping every time this view re-enters (e.g.
    /// tab switches), so the user's pan survives across list/map toggles.
    @State private var didLandInitialCamera: Bool = false
    /// Debounce handle for viewport-count updates. Camera events fire per
    /// frame during pan/zoom; we coalesce to the final resting camera so the
    /// ViewModel updates at most ~8/sec during drags and exactly once after.
    @State private var cameraDebounce: Task<Void, Never>?
    /// Renderable pin/cluster list derived from `viewModel.listings` +
    /// current camera projection. Recomputed in `.onCameraChanged` /
    /// `.onStyleLoaded` / when the underlying listings change.
    @State private var annotationItems: [MapAnnotationItem] = []
    /// Listing whose coordinate is closest to the current camera center.
    /// Renders as "focused" on its pin (subtle inner highlight). Independent
    /// of `selectedPinID`: selection is tap-driven, focus is camera-driven.
    @State private var focusedListingID: UUID?

    /// Last camera center treated as the "anchored" view for the
    /// "Search this area" affordance. Set on initial land, city filter
    /// change, and every pill tap. Nil until the map's style has loaded and
    /// we have an authoritative first camera to anchor to.
    @State private var anchorCameraCenter: CLLocationCoordinate2D?

    /// Screen-space distance (in points) within which two pins are considered
    /// colliding and are grouped into a cluster. One full pin hit-target
    /// (44×44) — below this, two capsules would visually stack.
    private let clusterCollisionRadius: CGFloat = 44

    /// Camera zoom increment applied when the user taps a cluster, resolving
    /// the overlap by pulling member pins apart. 1.5 is roughly one "step"
    /// of Mapbox zoom — enough to separate city-block collisions without
    /// overshooting into street-level detail.
    private let clusterTapZoomStep: Double = 1.5

    /// Right-margin push for the Mapbox attribution `(i)` button so it clears
    /// the wordmark to its left (observed render width ~85–95 pt).
    private let mapboxWordmarkClearance: CGFloat = 100

    /// Pan distance (in either latitude or longitude degrees) past which we
    /// consider the camera to have left its anchored view, surfacing the
    /// "Search this area" pill. 0.02° is roughly ~2km at Somalia's latitude
    /// — a rough, zoom-agnostic approximation, intentional per spec.
    private let panThresholdDegrees: Double = 0.02

    var body: some View {
        map
            .background(Color.canvas)
            .overlay {
                if showSkeletons {
                    LoadingPinSkeletons()
                }
            }
            .onAppear {
                // Land the opening camera on the user's city (or the Mogadishu
                // stand-in) exactly once. Subsequent appears preserve the pan.
                guard !didLandInitialCamera else { return }
                didLandInitialCamera = true
                let target = viewModel.targetCamera
                withViewportAnimation(.easeOut(duration: 0.6)) {
                    viewport = .camera(center: target.coordinate, zoom: target.zoom)
                }
                anchorCameraCenter = target.coordinate
                if hasPannedFromAnchor { hasPannedFromAnchor = false }
            }
            .onChange(of: viewModel.filter.city) { _, _ in
                let target = viewModel.targetCamera
                withViewportAnimation(.easeOut(duration: 0.6)) {
                    viewport = .camera(center: target.coordinate, zoom: target.zoom)
                }
                anchorCameraCenter = target.coordinate
                if hasPannedFromAnchor { hasPannedFromAnchor = false }
            }
            .onChange(of: recenterTrigger) { _, _ in
                // Parent tapped the recenter button — re-land on the current
                // `targetCamera` and reset the anchor so the "Search this
                // area" pill doesn't re-surface from the animation's pan.
                let target = viewModel.targetCamera
                withViewportAnimation(.easeOut(duration: 0.6)) {
                    viewport = .camera(center: target.coordinate, zoom: target.zoom)
                }
                anchorCameraCenter = target.coordinate
                if hasPannedFromAnchor { hasPannedFromAnchor = false }
            }
    }

    // MARK: - Map

    @ViewBuilder
    private var map: some View {
        if loadFailed {
            mapFallback
        } else {
            MapReader { proxy in
                mapCore(proxy: proxy)
            }
        }
    }

    /// The Mapbox `Map` body plus its mapbox-specific + SwiftUI modifiers.
    /// Extracted into a helper so the compiler's type-inference doesn't trip
    /// on the combined closure depth (Map content + every camera / style /
    /// Builds the map view and wires Mapbox event handlers to drive annotations, camera updates, and related UI state.
    /// 
    /// The returned view renders the map with current `annotationItems`, applies the app's map style and ornament layout, and hooks camera/style/load/tap/change events to:
    /// - update visible-listing counts and recompute screen-space annotation clustering,
    /// - maintain the pan-anchor used for the "Search this area" affordance,
    /// - handle map loading failure,
    /// - clear the selected pin when the user taps empty map space,
    /// and react to listing-id changes and external "search this area" triggers.
    /// - Parameters:
    ///   - proxy: A `MapProxy` used for reading the map's camera state and interacting with the map runtime.
    /// Composes the map view and its annotation layer, wiring camera, style, interaction, and change handlers.
    ///
    — Provides the interactive Map view that renders `annotationItems`, applies the tuned map style and ornament options, and installs handlers to update visible listings, recompute annotation layout, manage the pan anchor gate, respond to style load and loading errors, dismiss selection on empty-map taps, and react to listing and "search this area" triggers.
    /// - Parameter proxy: A `MapProxy` used to read the underlying map state and drive camera- and style-dependent updates.
    /// - Returns: A view containing the configured `Map` and its annotation content.
    @ViewBuilder
    private func mapCore(proxy: MapProxy) -> some View {
        Map(viewport: $viewport) {
            ForEvery(annotationItems, id: \.id) { item in
                annotationContent(for: item, proxy: proxy)
            }
        }
        .mapStyle(brandTunedStyle)
        .ornamentOptions(ornamentOptions)
        .onCameraChanged { _ in
            scheduleVisibleListingsUpdate(proxy: proxy)
            recomputeAnnotationLayout(proxy: proxy)
            updatePanGate(proxy: proxy)
        }
        .onStyleLoaded { _ in
            // First authoritative bounds read: once the style has loaded
            // the camera has resolved to its initial frame, so the header
            // can show a non-zero count before the user pans. Also seeds
            // the pan anchor from the first resolved camera.
            scheduleVisibleListingsUpdate(proxy: proxy)
            recomputeAnnotationLayout(proxy: proxy)
            if anchorCameraCenter == nil, let map = proxy.map {
                anchorCameraCenter = map.cameraState.center
                if hasPannedFromAnchor { hasPannedFromAnchor = false }
            }
        }
        .onMapLoadingError { _ in
            loadFailed = true
        }
        // Tapping empty map area dismisses the selected-listing card,
        // which is anchored in `DiscoveryView` above the floating tab bar.
        .onTapGesture {
            if viewModel.selectedPinID != nil {
                viewModel.selectPin(nil)
            }
        }
        .ignoresSafeArea(edges: [.top, .bottom])
        // Listings array replaced (filter change, refresh, etc.) —
        // re-project into annotation items. Comparing the id list keeps
        // this cheap and ignores incidental @Model faulting.
        .onChange(of: viewModel.listings.map(\.id)) { _, _ in
            recomputeAnnotationLayout(proxy: proxy)
        }
        .onChange(of: searchThisAreaTrigger) { _, _ in
            handleSearchThisArea(proxy: proxy)
        }
    }

    /// Returns the `MapViewAnnotation` for a single pin or cluster. Split
    /// out of `mapCore(proxy:)` so both the outer modifier chain and the
    /// Creates a map annotation for the given item, rendering either a single listing pin or an aggregated cluster at the item's coordinate.
    /// - Parameters:
    ///   - item: A `MapAnnotationItem` representing either a single listing or a cluster group to render.
    ///   - proxy: A `MapProxy` providing map context used by annotation interactions.
    /// Builds a map annotation view for a given `MapAnnotationItem`.
    /// 
    /// Produces a `MapViewAnnotation` positioned at the item's coordinate that renders either:
    /// - a listing price pin for `.single`, which selects that listing when tapped, or
    /// - a cluster pin for `.cluster`, which zooms toward the cluster centroid when tapped.
    /// - Parameters:
    ///   - item: The annotation item to render; either a single listing or a cluster group.
    ///   - proxy: The map proxy used for cluster tap handling and coordinate context.
    /// - Returns: A `MapContent` representing the annotation view for the provided item.
    @MapContentBuilder
    private func annotationContent(for item: MapAnnotationItem, proxy: MapProxy) -> some MapContent {
        switch item {
        case .single(let listing):
            MapViewAnnotation(coordinate: CLLocationCoordinate2D(
                latitude: listing.latitude,
                longitude: listing.longitude
            )) {
                ListingPricePin(
                    listing: listing,
                    isSelected: viewModel.selectedPinID == listing.id,
                    isSaved: viewModel.savedListingIDs.contains(listing.id),
                    isFocused: focusedListingID == listing.id
                )
                .zIndex(pinZIndex(for: listing))
                .onTapGesture {
                    viewModel.selectPin(listing.id)
                }
            }
            .allowOverlap(true)
        case .cluster(let group):
            MapViewAnnotation(coordinate: CLLocationCoordinate2D(
                latitude: group.centroid.latitude,
                longitude: group.centroid.longitude
            )) {
                PricePinCluster(
                    count: group.memberIDs.count,
                    minDollars: group.minDollars
                )
                .onTapGesture {
                    handleClusterTap(group: group, proxy: proxy)
                }
            }
            .allowOverlap(true)
        }
    }

    private var mapFallback: some View {
        VStack(spacing: Spacing.base) {
            Image(systemName: "map")
                .font(.system(size: 40))
                .foregroundStyle(Color.textTertiary)
            Text("Map unavailable")
                .font(.martiHeading5)
                .foregroundStyle(Color.textPrimary)
            Text("We couldn't load the map. Switch back to the List view to keep browsing.")
                .font(.martiFootnote)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Debounces viewport-count refreshes. `onCameraChanged` fires per render
    /// frame during pan/zoom; we wait 120ms of quiet, then read the resting
    /// camera's coordinate bounds through the `MapProxy` and push into the
    /// ViewModel. The explicit `@MainActor` annotation keeps the capture of
    /// `proxy` + `viewModel` on the main actor under Swift 6 strict
    /// Schedules a debounced update of which listings are visible in the current map camera bounds.
    /// Cancels any in-flight debounce work and, after a short (120 ms) quiet period, reads the map's camera state and updates the view model with the computed coordinate bounds.
    /// Debounces and schedules an update of visible listings using the current map bounds.
    /// Cancels any pending update, waits 120 milliseconds, then reads the map bounds from `proxy` and calls `viewModel.updateVisibleListings(bounds:)`.
    /// - Parameter proxy: The map proxy used to access the underlying map and its current camera state.
    private func scheduleVisibleListingsUpdate(proxy: MapProxy) {
        cameraDebounce?.cancel()
        cameraDebounce = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled, let map = proxy.map else { return }
            let bounds = map.coordinateBounds(for: CameraOptions(cameraState: map.cameraState))
            viewModel.updateVisibleListings(bounds: bounds)
        }
    }

    /// Resets the pan anchor to the current camera center and refreshes the
    /// ViewModel's visible-listing count against the current bounds. Fires
    /// Re-anchors the map to the current camera center and refreshes the visible-listing set.
    /// 
    /// Updates the view's anchor center to the map's current camera center, clears the `hasPannedFromAnchor` flag if set, and requests `viewModel` to update visible listings for the current camera bounds.
    /// - Parameters:
    /// Sets the pan anchor to the map's current camera center, clears the "has panned" gate if set, and refreshes the view model's visible-listings using the current camera bounds.
    /// - Parameter proxy: A `MapProxy` used to read the underlying `map` and its camera state; no action is taken if `proxy.map` is `nil`.
    private func handleSearchThisArea(proxy: MapProxy) {
        guard let map = proxy.map else { return }
        anchorCameraCenter = map.cameraState.center
        if hasPannedFromAnchor { hasPannedFromAnchor = false }
        let bounds = map.coordinateBounds(for: CameraOptions(cameraState: map.cameraState))
        viewModel.updateVisibleListings(bounds: bounds)
    }

    /// Flips `hasPannedFromAnchor` when the camera center drifts past
    /// `panThresholdDegrees` from `anchorCameraCenter`. Runs per camera
    /// frame alongside `scheduleVisibleListingsUpdate` — the work here is a
    /// Updates the `hasPannedFromAnchor` flag by comparing the map camera's current center to the stored anchor center.
    /// 
    /// Compares the maximum of the absolute latitude and longitude differences to `panThresholdDegrees`; sets `hasPannedFromAnchor` to `true` when the drift is greater than or equal to the threshold, otherwise sets it to `false`. The property is updated only when the computed value differs from the current `hasPannedFromAnchor`.
    /// Updates the `hasPannedFromAnchor` binding based on current camera drift from the stored anchor center.
    /// 
    /// If the map or `anchorCameraCenter` is unavailable, the method returns without changing state.
    /// - Parameters:
    ///   - proxy: The `MapProxy` used to read the underlying map's current camera center. The function reads `proxy.map?.cameraState.center` and compares it to `anchorCameraCenter`, toggling `hasPannedFromAnchor` when the maximum of latitude/longitude drift crosses `panThresholdDegrees`.
    private func updatePanGate(proxy: MapProxy) {
        guard let map = proxy.map, let anchor = anchorCameraCenter else { return }
        let current = map.cameraState.center
        let drift = max(
            abs(current.latitude  - anchor.latitude),
            abs(current.longitude - anchor.longitude)
        )
        let panned = drift >= panThresholdDegrees
        if panned != hasPannedFromAnchor {
            hasPannedFromAnchor = panned
        }
    }

    // MARK: - Pin collision + focus

    /// Reprojects `viewModel.listings` into `annotationItems` by measuring
    /// pairwise screen-space distance and grouping anything closer than
    /// `clusterCollisionRadius` into a single cluster pill. Runs
    /// synchronously on the main actor; with the ~4–10 listings we render
    /// for v1 the O(n²) cost is negligible. Also updates `focusedListingID`
    /// to the listing nearest the current camera center.
    ///
    /// This is a parallel computation to `scheduleVisibleListingsUpdate` —
    /// it does not share its 120ms debounce. Grouping runs per camera frame
    /// so cluster pills split/merge while the user is mid-pinch rather than
    /// Updates the map annotation layer and the currently focused listing using the map's current camera and projection.
    /// 
    /// Projects the view model's listings into screen space, derives cluster/singleton annotation items from those projections,
    /// and replaces `annotationItems` when the newly computed items differ. Also computes a camera-driven `focusedListingID`:
    /// the nearest listing to the camera center only when that listing appears as an individual annotation (not when it is part of a cluster).
    /// If the map is unavailable or there are no listings, clears the corresponding state as needed.
    /// Recomputes the set of map annotations and the currently focused listing based on the map's current projection and clustering state.
    /// 
    /// Projects visible listings into screen space, groups nearby projections into annotation items (single pins or clusters), and updates `annotationItems` if the computed layout differs from the current one. Also computes `focusedListingID` as the unclustered listing whose screen position is nearest the camera center; clears focus when no such listing exists.
    /// - Parameters:
    ///   - proxy: A `MapProxy` providing access to the underlying map and its camera state. If the proxy's `map` is unavailable the function returns without making changes.
    private func recomputeAnnotationLayout(proxy: MapProxy) {
        guard let map = proxy.map else { return }
        let listings = viewModel.listings

        guard !listings.isEmpty else {
            if !annotationItems.isEmpty { annotationItems = [] }
            if focusedListingID != nil  { focusedListingID = nil }
            return
        }

        // Project every listing to screen space once; grouping below reads
        // from this cache instead of recomputing projection per comparison.
        let projections: [(listing: Listing, point: CGPoint)] = listings.map { listing in
            let coord = CLLocationCoordinate2D(latitude: listing.latitude, longitude: listing.longitude)
            return (listing, map.point(for: coord))
        }

        let newItems = groupProjections(projections, radius: clusterCollisionRadius)
        if newItems != annotationItems {
            annotationItems = newItems
        }

        // Focused pin: listing whose screen-space position is closest to the
        // camera center point. Computed from the same projections cache so
        // we don't re-invoke `map.point(for:)`. Skipped when the nearest
        // listing is part of a cluster — a cluster has no focused member.
        let centerScreen = map.point(for: map.cameraState.center)
        var nearest: (id: UUID, distance: CGFloat)?
        for entry in projections {
            let d = hypot(entry.point.x - centerScreen.x, entry.point.y - centerScreen.y)
            if let current = nearest, d >= current.distance { continue }
            nearest = (entry.listing.id, d)
        }
        let newFocus: UUID? = nearest.flatMap { candidate in
            newItems.contains(where: {
                if case .single(let l) = $0 { return l.id == candidate.id }
                return false
            }) ? candidate.id : nil
        }
        if newFocus != focusedListingID {
            focusedListingID = newFocus
        }
    }

    /// Groups screen-projected listings whose points fall within `radius` of
    /// each other into clusters. Uses a simple union-find over the n×n
    /// distance matrix — O(n²) but n is small (≤ ~50 in the worst case).
    /// Cluster ids are deterministic hashes of sorted member ids so they
    /// Groups projected listings whose screen-space points lie within `radius` and produces stable annotation items.
    /// - Parameters:
    ///   - projections: An array of tuples pairing a `Listing` with its projected screen-space `CGPoint`.
    ///   - radius: The maximum screen-space distance (in points) between two projections to consider them part of the same cluster.
    /// Groups listings by proximity in screen space and returns annotation items representing singles or clusters.
    /// 
    /// Listings whose projected points are within `radius` of each other are merged into a cluster; listings not merged remain individual `.single` items. Cluster items contain a deterministic integer `id` (stable across runs for the same member set), the cluster's centroid coordinate (arithmetic mean of member latitudes/longitudes), the cluster's `memberIDs` sorted lexicographically by UUID string, and `minDollars` computed as the minimum `pricePerNight` among members divided by 100.
    /// - Parameters:
    ///   - projections: An array of tuples pairing a `Listing` with its projected screen `CGPoint`.
    ///   - radius: Collision radius in screen points; two projections whose distance is less than or equal to this value are considered part of the same cluster.
    /// - Returns: An array of `MapAnnotationItem` where each element is either `.single(listing)` or `.cluster(PricePinClusterGroup)`. The array is ordered deterministically by the lexicographically smallest member UUID string of each bucket to ensure stable iteration order.
    private func groupProjections(
        _ projections: [(listing: Listing, point: CGPoint)],
        radius: CGFloat
    ) -> [MapAnnotationItem] {
        var parent = Array(0..<projections.count)

        /// Finds the representative root of the disjoint-set element at the given index and compresses its path.
        /// 
        /// This updates the `parent` array so all traversed nodes point directly to the root (path compression), reducing future lookup time.
        /// - Parameter i: The index of the element whose set representative should be found.
        /// Finds the representative root index of the set containing the given element.
        /// Performs path compression so intermediate nodes are linked directly to the root.
        /// - Parameter i: The index of the element to locate.
        /// - Returns: The root index representing the set that contains `i`.
        func find(_ i: Int) -> Int {
            var root = i
            while parent[root] != root { root = parent[root] }
            var node = i
            while parent[node] != root {
                let next = parent[node]
                parent[node] = root
                node = next
            }
            return root
        }

        /// Merges the disjoint-set containing `a` into the set containing `b`.
        /// - Parameters:
        ///   - a: Index of the first element.
        ///   - b: Index of the second element.
        /// Merge the disjoint-set containing the element at index `a` with the set containing the element at index `b`.
        /// - Parameters:
        ///   - a: Index of the first element whose set will be merged.
        ///   - b: Index of the second element whose set will be merged.
        func union(_ a: Int, _ b: Int) {
            let rootA = find(a), rootB = find(b)
            if rootA != rootB { parent[rootA] = rootB }
        }

        for i in 0..<projections.count {
            for j in (i + 1)..<projections.count {
                let dx = projections[i].point.x - projections[j].point.x
                let dy = projections[i].point.y - projections[j].point.y
                if hypot(dx, dy) <= radius { union(i, j) }
            }
        }

        var buckets: [Int: [Int]] = [:]
        for i in 0..<projections.count {
            buckets[find(i), default: []].append(i)
        }

        // Emit items in stable order: sort buckets by smallest member id
        // (lexicographic UUID string) so the array's iteration order doesn't
        // reshuffle between renders. `.min()` never returns nil because every
        // bucket comes from the union-find root map and therefore contains at
        // least one index, but we fall back to empty strings so strict
        // concurrency sees no `!`.
        return buckets.values
            .sorted { lhs, rhs in
                let lMin = lhs.map { projections[$0].listing.id.uuidString }.min() ?? ""
                let rMin = rhs.map { projections[$0].listing.id.uuidString }.min() ?? ""
                return lMin < rMin
            }
            .map { indices -> MapAnnotationItem in
                if indices.count == 1 {
                    return .single(projections[indices[0]].listing)
                }
                let members = indices.map { projections[$0].listing }
                // `UUID` isn't `Comparable`, so sort by its string form to
                // guarantee a canonical order for hashing and for the
                // cluster's `memberIDs` copy.
                let sortedIDs = members.map(\.id).sorted { $0.uuidString < $1.uuidString }
                var hasher = Hasher()
                hasher.combine("cluster")
                for id in sortedIDs { hasher.combine(id) }
                let id = hasher.finalize()

                let centroidLat = members.reduce(0.0) { $0 + $1.latitude }  / Double(members.count)
                let centroidLon = members.reduce(0.0) { $0 + $1.longitude } / Double(members.count)
                let minDollars  = (members.map { $0.pricePerNight }.min() ?? 0) / 100

                return .cluster(PricePinClusterGroup(
                    id: id,
                    memberIDs: sortedIDs,
                    centroid: (centroidLat, centroidLon),
                    minDollars: minDollars
                ))
            }
    }

    /// Zooms the camera onto a cluster's centroid so the member pins split
    /// apart. Increment is bounded so a tap at max zoom is a no-op rather
    /// Animates the map camera to the cluster's centroid and zooms in to help resolve the cluster.
    /// - Parameters:
    ///   - group: The cluster group whose centroid will be used as the target camera center.
    /// Zooms the map viewport toward the tapped cluster's centroid.
    /// 
    /// Increases the current map zoom by `clusterTapZoomStep` (capped at 20) and animates the camera to the cluster's centroid.
    /// - Parameters:
    ///   - group: The cluster group whose centroid and member information determine the target camera center.
    ///   - proxy: A `MapProxy` used to read the current map camera state.
    private func handleClusterTap(group: PricePinClusterGroup, proxy: MapProxy) {
        let currentZoom = proxy.map?.cameraState.zoom ?? 12
        let targetZoom = min(currentZoom + clusterTapZoomStep, 20)
        let center = CLLocationCoordinate2D(
            latitude:  group.centroid.latitude,
            longitude: group.centroid.longitude
        )
        withViewportAnimation(.easeOut(duration: 0.4)) {
            viewport = .camera(center: center, zoom: targetZoom)
        }
    }

    /// Explicit z-order so stacked pin content renders in a predictable,
    /// attention-ordered hierarchy: selected floats above saved, saved above
    /// focused, everything else at the base layer. Applied per-annotation
    /// so even when clusters aren't formed (e.g. two pins just outside the
    /// Determines the drawing z-index priority for a listing pin based on selection, saved, and focus state.
    /// - Parameter listing: The listing to evaluate.
    /// Compute the z-index priority for a listing pin based on selection, saved state, and focus.
    /// - Returns: `3` if the listing is selected, `2` if the listing is saved (and not selected), `1` if the listing is focused, `0` otherwise.
    private func pinZIndex(for listing: Listing) -> Double {
        if viewModel.selectedPinID == listing.id                    { return 3 }
        if viewModel.savedListingIDs.contains(listing.id)           { return 2 }
        if focusedListingID == listing.id                           { return 1 }
        return 0
    }

    /// Mapbox Standard v11 tuned to the Marti palette so the map reads as an
    /// extension of the app, not a stock dark preset. `theme: .faded` damps
    /// basemap label contrast so price pins win the typographic hierarchy —
    /// place and road labels stay visible for orientation but recede behind
    /// the interactive layer. Water is lifted toward a bluer, brighter tone
    /// than land so coastlines (Mogadishu, Hargeisa) read as distinct shapes;
    /// roads sit above water in brightness so coastal crossings stay legible
    /// as foreground. Motorways/trunks keep their tonal order above roads.
    private var brandTunedStyle: MapStyle {
        .standard(
            theme: .faded,
            lightPreset: .night,
            showPointOfInterestLabels: false,
            showTransitLabels: false,
            showPlaceLabels: true,
            showRoadLabels: true,
            show3dObjects: false,
            colorAdminBoundaries: StyleColor(red: 68, green: 80, blue: 95, alpha: 0.6), // textTertiary-adjacent, muted
            colorLand: StyleColor(red: 10, green: 18, blue: 30),         // near-canvas
            colorMotorways: StyleColor(red: 31, green: 45, blue: 66),    // surfaceElevated
            colorRoads: StyleColor(red: 22, green: 32, blue: 46),        // nudged above water so coastal crossings read as foreground
            colorTrunks: StyleColor(red: 25, green: 37, blue: 54),
            colorWater: StyleColor(red: 14, green: 28, blue: 48)         // bluer + ~3pt lift over land so coastline shapes read at country zoom
        )
    }

    /// Customizes Mapbox's default map ornaments so they stop colliding with
    /// our floating chrome: the scale bar is hidden (this is a listing-browse
    /// surface, not a navigation map), and the logo + attribution button are
    /// pinned to the bottom-leading corner, pushed above the bottom chrome so
    /// they live with our UI instead of under the selected-listing card. The
    /// attribution button is shifted right so the blue (i) doesn't stack on
    /// top of the wordmark.
    private var ornamentOptions: OrnamentOptions {
        let bottomMargin = max(bottomChromeInset + Spacing.sm, 8)
        return OrnamentOptions(
            scaleBar: ScaleBarViewOptions(visibility: .hidden),
            logo: LogoViewOptions(
                position: .bottomLeading,
                margins: CGPoint(x: Spacing.screenMargin, y: bottomMargin)
            ),
            attributionButton: AttributionButtonOptions(
                position: .bottomLeading,
                margins: CGPoint(x: Spacing.screenMargin + mapboxWordmarkClearance, y: bottomMargin)
            )
        )
    }

    // MARK: - Loading state

    private var showSkeletons: Bool {
        !loadFailed && viewModel.isLoading && viewModel.listings.isEmpty
    }
}

/// Static capsule placeholders scattered over the map frame during the first
/// load. Not `MapViewAnnotation`s — positioned in view-space so they don't move
/// with the camera. Matches the app's existing static-skeleton convention
/// (`SkeletonListingCard`, `SkeletonHeader`) rather than adding a shimmer
/// modifier the rest of the app doesn't use.
private struct LoadingPinSkeletons: View {
    /// Fixed relative offsets from the map center — deterministic so the
    /// pattern doesn't jump across re-renders.
    private struct Layout {
        let dx: CGFloat
        let dy: CGFloat
        let width: CGFloat
    }

    private let layouts: [Layout] = [
        .init(dx: -90, dy: -60, width: 56),
        .init(dx:  60, dy: -90, width: 48),
        .init(dx: -40, dy:  30, width: 52),
        .init(dx: 100, dy:  20, width: 60),
        .init(dx: -110, dy: 90, width: 50)
    ]

    var body: some View {
        GeometryReader { proxy in
            ForEach(Array(layouts.enumerated()), id: \.offset) { _, layout in
                Capsule()
                    .fill(Color.surfaceHighlight)
                    .overlay(Capsule().stroke(Color.dividerLine, lineWidth: 0.5))
                    .frame(width: layout.width, height: 32)
                    .shadow(token: .pin)
                    .position(
                        x: proxy.size.width * 0.5 + layout.dx,
                        y: proxy.size.height * 0.5 + layout.dy
                    )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
