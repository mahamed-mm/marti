import SwiftUI

struct DiscoveryView: View {
    @State private var viewModel: ListingDiscoveryViewModel
    @State private var pushedListing: Listing?

    /// Height of the floating tab bar passed down by `MainTabView`. Used to
    /// anchor the map-mode bottom chrome above the bar without hardcoding.
    /// Default of 0 is for preview and test ergonomics only — in app context
    /// `MainTabView` always wires `FloatingTabView`'s measured height here.
    let tabBarHeight: CGFloat

    /// Measured height of the bottom-chrome VStack (fee tag + selected card or
    /// empty-state pill, including bottom padding) in map mode.
    @State private var mapBottomChromeHeight: CGFloat = 0

    /// One-shot gate for the fee-inclusion onboarding toast. Flips to `true`
    /// the first time the map appears in a session (when the user hasn't
    /// previously dismissed the toast) and never flips back, so toggling
    /// list→map→list→map within one launch doesn't re-show the toast after
    /// its auto-dismiss fires.
    @State private var hasShownFeeToastThisSession = false

    /// Bumped every time the recenter button is tapped. `ListingMapView`
    /// observes this via `.onChange(of: recenterTrigger)` and re-lands its
    /// camera on `viewModel.targetCamera`. Using a trigger UUID keeps the
    /// map's `viewport` state private to the map view.
    @State private var recenterTrigger: UUID = UUID()

    /// Bumped every time the "Search this area" pill is tapped.
    /// `ListingMapView` resets its anchor to the current camera and refreshes
    /// the visible-listing count for the new frame.
    @State private var searchThisAreaTrigger: UUID = UUID()

    /// Mirrors `ListingMapView.hasPannedFromAnchor` so the parent can show
    /// or hide `SearchThisAreaPill` inside `bottomChrome`.
    @State private var hasPannedFromAnchor: Bool = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let availableCities: [City?] = [nil, .mogadishu, .hargeisa]

    init(viewModel: ListingDiscoveryViewModel, tabBarHeight: CGFloat = 0) {
        _viewModel = State(initialValue: viewModel)
        self.tabBarHeight = tabBarHeight
    }

    var body: some View {
        Group {
            switch viewModel.viewMode {
            case .list:
                listLayout
            case .map:
                mapLayout
            }
        }
        .background(Color.canvas.ignoresSafeArea())
        .task {
            if viewModel.listings.isEmpty {
                await viewModel.loadListings()
            }
        }
        .sheet(isPresented: $viewModel.isSearchSheetPresented) {
            SearchSheetView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.isAuthSheetPresented) {
            AuthSheetPlaceholderView()
        }
        .navigationDestination(item: $pushedListing) { listing in
            ListingDetailPlaceholderView(listing: listing)
        }
        .hideFloatingTabBar(viewModel.viewMode == .map)
    }

    // MARK: - Layouts

    /// List view: editorial hero header over the scrolling rails. The city
    /// chip row lives directly under the hero (as a sibling) rather than
    /// inside it, so the hero's display typography isn't competing with the
    /// chip row for weight inside one container.
    private var listLayout: some View {
        VStack(spacing: 0) {
            DiscoveryHeroHeaderView(viewModel: viewModel) {
                viewModel.isSearchSheetPresented = true
            }
            cityChips
                .padding(.top, Spacing.sm)
            ListingListView(viewModel: viewModel)
        }
        .overlay(alignment: .bottom) {
            LinearGradient(
                colors: [Color.canvas.opacity(0), Color.canvas],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)
            .allowsHitTesting(false)
            .padding(.bottom, tabBarHeight)
        }
        .overlay(alignment: .bottom) {
            MapToggleFAB {
                viewModel.setViewMode(.map)
            }
            .padding(.bottom, tabBarHeight + Spacing.md)
        }
    }

    /// Map view: full-bleed Mapbox map drawing under the status bar and home
    /// indicator, with three independent floating "islands" (list-icon button,
    /// display-only title capsule, filter-icon button) hovering over the raw
    /// map content via `.overlay(alignment: .top)`. Bottom chrome (fee toast +
    /// selected card / empty-state pill) is anchored via
    /// `.overlay(alignment: .bottom)` above the floating tab bar. Each island
    /// carries its own material + hairline + drop shadow so legibility comes
    /// from the islands themselves rather than a top-edge scrim.
    private var mapLayout: some View {
        ListingMapView(
            viewModel: viewModel,
            bottomChromeInset: mapBottomChromeHeight,
            recenterTrigger: recenterTrigger,
            searchThisAreaTrigger: searchThisAreaTrigger,
            hasPannedFromAnchor: $hasPannedFromAnchor
        )
        .ignoresSafeArea(edges: [.top, .bottom])
        .overlay(alignment: .bottom) {
            bottomChrome
                .padding(.horizontal, Spacing.screenMargin)
                .padding(.bottom, bottomChromeTrailingSpacing)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { newValue in
                    mapBottomChromeHeight = newValue
                }
        }
        .overlay(alignment: .top) {
            HStack(spacing: 0) {
                FloatingMapIconButton(
                    systemImage: "list.bullet",
                    accessibilityLabel: "Show list view"
                ) {
                    viewModel.setViewMode(.list)
                }
                Spacer(minLength: Spacing.sm)
                DiscoveryHeaderPill(
                    title: viewModel.headerLiveSummary,
                    subtitle: nil
                )
                Spacer(minLength: Spacing.sm)
                FloatingMapIconButton(
                    systemImage: "slider.horizontal.3",
                    accessibilityLabel: "Filters"
                ) {
                    viewModel.isSearchSheetPresented = true
                }
            }
            .padding(.horizontal, Spacing.screenMargin)
            .safeAreaPadding(.top, Spacing.sm)
        }
        .onAppear {
            if !viewModel.feeTagDismissed, !hasShownFeeToastThisSession {
                hasShownFeeToastThisSession = true
            }
        }
        .task(id: hasShownFeeToastThisSession) {
            guard hasShownFeeToastThisSession, !viewModel.feeTagDismissed else { return }
            try? await Task.sleep(for: .seconds(4))
            if !Task.isCancelled { viewModel.dismissFeeTag() }
        }
    }

    // MARK: - Bottom chrome (map mode)

    @ViewBuilder
    private var bottomChrome: some View {
        VStack(spacing: 0) {
            mapUtilityRows
            if showFeeTag {
                FeeInclusionTag(onDismiss: { viewModel.dismissFeeTag() })
                    .padding(.bottom, feeTagBottomSpacing)
                    .transition(.opacity)
            }
            anchoredItem
        }
        .animation(.default, value: showFeeTag)
        .animation(.default, value: viewModel.selectedListing?.id)
    }

    /// Stacked rows of floating map utilities that share vertical real-estate
    /// with the carousel / selected-card. Pill appears conditionally above
    /// the recenter button; recenter is always visible. Combined chrome
    /// height is measured by the outer `.onGeometryChange`, so Mapbox
    /// ornaments clear the full stack.
    @ViewBuilder
    private var mapUtilityRows: some View {
        VStack(spacing: Spacing.md) {
            if hasPannedFromAnchor {
                HStack {
                    Spacer(minLength: 0)
                    SearchThisAreaPill(action: searchThisArea)
                    Spacer(minLength: 0)
                }
                .transition(.opacity.combined(with: .offset(y: 8)))
            }
            HStack {
                Spacer(minLength: 0)
                FloatingMapIconButton(
                    systemImage: "location.fill",
                    accessibilityLabel: "Recenter map on your city"
                ) {
                    recenterTrigger = UUID()
                }
            }
        }
        .padding(.bottom, Spacing.md)
        .animation(.easeOut(duration: 0.25), value: hasPannedFromAnchor)
        .sensoryFeedback(.impact(weight: .light), trigger: searchThisAreaTrigger)
    }

    /// Signals the map to perform a "search this area" using the current map bounds.
    /// 
    /// Signals the map to refresh listings for the current visible region by updating the `searchThisAreaTrigger`.
    /// 
    /// This causes observers (e.g., `ListingMapView`) to perform a search using the map's current camera bounds.
    private func searchThisArea() {
        searchThisAreaTrigger = UUID()
    }

    @ViewBuilder
    private var anchoredItem: some View {
        if showEmptyStatePill {
            MapEmptyStatePill(onAdjust: { viewModel.isSearchSheetPresented = true })
                .transition(.opacity)
        } else if let selected = viewModel.selectedListing {
            SelectedListingCard(
                listing: selected,
                isSaved: viewModel.savedListingIDs.contains(selected.id),
                onTapCard: { pushedListing = selected },
                onToggleSave: {
                    Task { await viewModel.toggleSave(listingID: selected.id) }
                },
                onDismiss: { viewModel.selectPin(nil) }
            )
            // Re-run the card's entrance animation when the backing listing
            // changes rather than animating property-by-property inside the
            // same view instance.
            .id(selected.id)
            .transition(.opacity)
        } else if !viewModel.listings.isEmpty {
            MapListingsCarousel(
                listings: viewModel.listings,
                savedListingIDs: viewModel.savedListingIDs,
                selectedID: viewModel.selectedPinID,
                onSelect: { viewModel.selectPin($0) },
                onToggleSave: { id in
                    Task { await viewModel.toggleSave(listingID: id) }
                }
            )
            .transition(.opacity)
        }
    }

    /// Hide the fee tag at very large Dynamic Type so the card + header don't
    /// collide on small devices (e.g. iPhone SE at AX5). The primary CTA
    /// stays visible; the fee reassurance is secondary.
    ///
    /// Gated on `hasShownFeeToastThisSession` so the toast only ever appears
    /// once per launch: once `dismissFeeTag()` fires (via the 4s auto-dismiss
    /// `.task` or user tap), `feeTagDismissed` flips and the toast stays
    /// hidden for subsequent list↔map toggles and future launches.
    private var showFeeTag: Bool {
        hasShownFeeToastThisSession
            && !viewModel.feeTagDismissed
            && !viewModel.listings.isEmpty
            && dynamicTypeSize < .accessibility3
    }

    private var showEmptyStatePill: Bool {
        viewModel.listings.isEmpty && !viewModel.isLoading && viewModel.error == nil
    }

    /// Gap between fee tag and whatever sits below it.
    /// - `Spacing.md + Spacing.sm` (12pt) when a card is shown (per spec)
    /// - `Spacing.base` (16pt) otherwise (fee tag hovers above tab bar)
    private var feeTagBottomSpacing: CGFloat {
        viewModel.selectedListing != nil ? Spacing.md + Spacing.sm : Spacing.base
    }

    /// Gap between the bottom-most item and the top of the floating tab bar.
    /// `FloatingTabView.onGeometryChange` measures the capsule including its
    /// outer padding but NOT its drop-shadow (8pt radius) — we add headroom
    /// so the card / pill doesn't visually touch the bar's shadow.
    /// - 12pt (spec 8pt + 4pt shadow clearance) when a selected-listing card is shown
    /// - `Spacing.base` (16pt) for the empty-state pill or fee-tag-only state
    private var bottomChromeTrailingSpacing: CGFloat {
        viewModel.selectedListing != nil ? Spacing.md + Spacing.sm : Spacing.base
    }

    // MARK: - City chip row (sibling to the hero header)

    private var cityChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.md) {
                ForEach(Array(availableCities.enumerated()), id: \.offset) { _, city in
                    CityChipView(
                        title: title(for: city),
                        isSelected: viewModel.filter.city == city,
                        action: {
                            var newFilter = viewModel.filter
                            newFilter.city = city
                            viewModel.applyFilter(newFilter)
                        }
                    )
                }
            }
            .padding(.horizontal, Spacing.screenMargin)
        }
        .overlay(alignment: .trailing) {
            LinearGradient(
                colors: [Color.canvas.opacity(0), Color.canvas],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 32)
            .allowsHitTesting(false)
        }
    }

    /// Provides the display title for a city chip.
    /// - Parameter city: The city to convert, or `nil` to represent the "All" option.
    /// - Returns: The localized title string for the given city (`"All"` for `nil`, `"Mogadishu"`, or `"Hargeisa"`).
    private func title(for city: City?) -> String {
        switch city {
        case nil:           return "All"
        case .mogadishu:    return "Mogadishu"
        case .hargeisa:     return "Hargeisa"
        }
    }
}
