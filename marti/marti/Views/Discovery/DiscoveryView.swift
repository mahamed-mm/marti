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

    /// List view: header sits in the flow, content flows under it. Unchanged
    /// by the discovery-map-redesign work — only the map mode is restructured.
    private var listLayout: some View {
        VStack(spacing: 0) {
            listModeHeader
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

    // MARK: - List-mode header (unchanged behavior)

    private var listModeHeader: some View {
        VStack(spacing: Spacing.base) {
            HStack(spacing: Spacing.md) {
                searchBar
                iconButton(systemImage: "line.3.horizontal.decrease", label: "Open filters") {
                    viewModel.isFilterSheetPresented = true
                }
                iconButton(systemImage: "map", label: "Switch to map view") {
                    viewModel.setViewMode(.map)
                }
            }
            cityChips
        }
        .padding(.horizontal, Spacing.screenMargin)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.md)
    }

    private var searchBar: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: searchBarHasSummary ? "slider.horizontal.3" : "magnifyingglass")
                .foregroundStyle(Color.textTertiary)
            Text(searchBarText)
                .font(.martiBody)
                .foregroundStyle(searchBarHasSummary ? Color.textPrimary : Color.textTertiary)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.base)
        .frame(height: 48)
        .frame(maxWidth: .infinity)
        .background(Capsule().fill(Color.surfaceElevated))
        .accessibilityHidden(true) // Search not functional in v1
    }

    private func iconButton(systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .frame(width: 48, height: 48)
                .background(Circle().fill(Color.surfaceElevated))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

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
        }
    }

    // MARK: - Search bar text

    private var searchBarHasSummary: Bool {
        viewModel.filter != .default
    }

    private var searchBarText: String {
        let f = viewModel.filter
        if f == .default {
            return "Search Mogadishu, Hargeisa…"
        }
        var parts: [String] = []
        if let city = f.city { parts.append(city.rawValue) }
        if let dateRange = formattedDateRange(checkIn: f.checkIn, checkOut: f.checkOut) {
            parts.append(dateRange)
        }
        if f.guestCount > 1 {
            parts.append("\(f.guestCount) guests")
        }
        if let min = f.priceMin, let max = f.priceMax {
            parts.append("$\(min/100)–$\(max/100)")
        } else if let min = f.priceMin {
            parts.append("$\(min/100)+")
        } else if let max = f.priceMax {
            parts.append("up to $\(max/100)")
        }
        return parts.isEmpty ? "Search Mogadishu, Hargeisa…" : parts.joined(separator: " · ")
    }

    private func formattedDateRange(checkIn: Date?, checkOut: Date?) -> String? {
        guard let checkIn, let checkOut else { return nil }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return "\(fmt.string(from: checkIn))–\(fmt.string(from: checkOut))"
    }

    private func title(for city: City?) -> String {
        switch city {
        case nil:           return "All"
        case .mogadishu:    return "Mogadishu"
        case .hargeisa:     return "Hargeisa"
        }
    }
}
