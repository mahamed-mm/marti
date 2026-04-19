import SwiftUI
import CoreLocation
import MapboxMaps

struct ListingMapView: View {
    @Bindable var viewModel: ListingDiscoveryViewModel

    @State private var viewport: Viewport = .camera(
        center: CLLocationCoordinate2D(latitude: 2.0469, longitude: 45.3182),
        zoom: 11
    )
    @State private var loadFailed: Bool = false

    var body: some View {
        map
            .background(Color.canvas)
            .overlay {
                if showSkeletons {
                    LoadingPinSkeletons()
                }
            }
            .onChange(of: viewModel.listings.map(\.id)) { _, _ in
                recenter()
            }
            .onAppear { recenter() }
    }

    // MARK: - Map

    @ViewBuilder
    private var map: some View {
        if loadFailed {
            mapFallback
        } else {
            Map(viewport: $viewport) {
                ForEvery(viewModel.listings, id: \.id) { listing in
                    MapViewAnnotation(coordinate: CLLocationCoordinate2D(
                        latitude: listing.latitude,
                        longitude: listing.longitude
                    )) {
                        ListingPricePin(
                            listing: listing,
                            isSelected: viewModel.selectedPinID == listing.id
                        )
                        .onTapGesture {
                            viewModel.selectPin(listing.id)
                        }
                    }
                    .allowOverlap(true)
                }
            }
            .mapStyle(.dark)
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
            .ignoresSafeArea(edges: .bottom)
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

    /// Recenters the map viewport to display the current listings from `viewModel`.
    /// 
    /// If `viewModel.listings` is empty the function does nothing. If there is exactly one listing it sets the viewport to a camera centered on that listing with zoom level 13; if there are multiple listings it sets the viewport to an overview that fits all listing coordinates.

    private func recenter() {
        guard !viewModel.listings.isEmpty else { return }
        let coords = viewModel.listings.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
        if coords.count == 1 {
            viewport = .camera(center: coords[0], zoom: 13)
        } else {
            viewport = .overview(geometry: MultiPoint(coords))
        }
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
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
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
