import SwiftUI

struct DiscoveryView: View {
    @State private var viewModel: ListingDiscoveryViewModel
    @State private var pushedListing: Listing?

    /// Height of the floating tab bar passed down by `MainTabView`. Used to
    /// anchor the map-mode bottom chrome above the bar without hardcoding.
    /// Default of 0 is for preview and test ergonomics only — in app context
    /// `MainTabView` always wires `FloatingTabView`'s measured height here.
    let tabBarHeight: CGFloat

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
        .sheet(isPresented: $viewModel.isFilterSheetPresented) {
            FilterSheetView(viewModel: viewModel)
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
            DiscoveryHeroHeaderView(viewModel: viewModel)
            cityChips
                .padding(.top, Spacing.md)
            ListingListView(viewModel: viewModel)
        }
    }

    /// Map view: map fills the screen edge-to-edge; `DiscoveryHeaderPill`
    /// floats at the top; a mutually-exclusive bottom chrome stack
    /// (fee tag + card / empty-state pill) anchors above the floating tab bar.
    private var mapLayout: some View {
        ZStack {
            ListingMapView(viewModel: viewModel)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                DiscoveryHeaderPill(
                    title: viewModel.headerTitle,
                    subtitle: viewModel.headerSubtitle,
                    onBack: { viewModel.setViewMode(.list) },
                    onTune: { viewModel.isFilterSheetPresented = true }
                )
                .padding(.horizontal, Spacing.screenMargin)
                .padding(.top, Spacing.base)

                // Guarantees visual separation between floating groups even at
                // extreme Dynamic Type sizes where the chrome would otherwise
                // kiss the pill.
                Spacer(minLength: Spacing.base)

                bottomChrome
                    .padding(.horizontal, Spacing.screenMargin)
                    .padding(.bottom, bottomChromeTrailingSpacing)
            }
        }
    }

    // MARK: - Bottom chrome (map mode)

    @ViewBuilder
    private var bottomChrome: some View {
        VStack(spacing: 0) {
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

    @ViewBuilder
    private var anchoredItem: some View {
        if let selected = viewModel.selectedListing {
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
        } else if showEmptyStatePill {
            MapEmptyStatePill(onAdjust: { viewModel.isFilterSheetPresented = true })
                .transition(.opacity)
        }
    }

    /// Hide the fee tag at very large Dynamic Type so the card + header don't
    /// collide on small devices (e.g. iPhone SE at AX5). The primary CTA
    /// stays visible; the fee reassurance is secondary.
    private var showFeeTag: Bool {
        !viewModel.feeTagDismissed
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
    }

    private func title(for city: City?) -> String {
        switch city {
        case nil:           return "All"
        case .mogadishu:    return "Mogadishu"
        case .hargeisa:     return "Hargeisa"
        }
    }
}
