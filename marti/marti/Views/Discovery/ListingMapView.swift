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
            .onChange(of: viewModel.listings.map(\.id)) { _, _ in
                recenter()
            }
            .onAppear { recenter() }
            .sheet(isPresented: sheetIsPresented) {
                if let listing = selectedListing {
                    sheetContent(for: listing)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                        .presentationBackground(Color.surfaceDefault)
                        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                        .presentationCornerRadius(Radius.lg)
                }
            }
            // Fade the floating tab bar out while the preview sheet is up.
            .hideFloatingTabBar(viewModel.selectedPinID != nil)
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
                        pricePin(for: listing)
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
            // Tapping empty map area dismisses the preview sheet.
            .onTapGesture {
                if viewModel.selectedPinID != nil {
                    viewModel.selectPin(nil)
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private func pricePin(for listing: Listing) -> some View {
        let dollars = listing.pricePerNight / 100
        let isSelected = viewModel.selectedPinID == listing.id
        return Text("$\(dollars)")
            .font(.martiLabel2)
            .foregroundStyle(isSelected ? Color.canvas : Color.textPrimary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                Capsule().fill(isSelected ? Color.coreAccent : Color.surfaceDefault)
            )
            .overlay(
                Capsule().stroke(Color.dividerLine, lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .accessibilityLabel("Listing for $\(dollars) per night")
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

    // MARK: - Sheet

    /// Binding that ties the system `.sheet` presentation to the viewModel's pin
    /// selection — drag-to-dismiss or tap outside clears `selectedPinID`.
    private var sheetIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.selectedPinID != nil },
            set: { newValue in
                if !newValue { viewModel.selectPin(nil) }
            }
        )
    }

    private var selectedListing: Listing? {
        guard let id = viewModel.selectedPinID else { return nil }
        return viewModel.listings.first(where: { $0.id == id })
    }

    private func sheetContent(for listing: Listing) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.base) {
                    Text("\(viewModel.listings.count) listing\(viewModel.listings.count == 1 ? "" : "s")")
                        .font(.martiCaption)
                        .foregroundStyle(Color.textTertiary)

                    NavigationLink {
                        ListingDetailPlaceholderView(listing: listing)
                    } label: {
                        ListingCardView(
                            listing: listing,
                            variant: .mapPreview,
                            isSaved: viewModel.savedListingIDs.contains(listing.id),
                            onToggleSave: {
                                Task { await viewModel.toggleSave(listingID: listing.id) }
                            }
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Spacing.base)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.lg)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(Color.surfaceDefault)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Centering

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
}
