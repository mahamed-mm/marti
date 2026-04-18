import SwiftUI

struct DiscoveryView: View {
    @State private var viewModel: ListingDiscoveryViewModel
    private let availableCities: [City?] = [nil, .mogadishu, .hargeisa]

    init(viewModel: ListingDiscoveryViewModel) {
        _viewModel = State(initialValue: viewModel)
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
    }

    // MARK: - Layouts

    /// List view: header sits in the flow, content flows under it.
    private var listLayout: some View {
        VStack(spacing: 0) {
            header
            ListingListView(viewModel: viewModel)
        }
    }

    /// Map view: map fills the screen edge-to-edge; the same header floats over it.
    private var mapLayout: some View {
        ZStack(alignment: .top) {
            ListingMapView(viewModel: viewModel)
                .ignoresSafeArea()

            header
                .background(
                    LinearGradient(
                        colors: [Color.canvas.opacity(0.92), Color.canvas.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }

    // MARK: - Header (search + actions + city chips)

    private var header: some View {
        VStack(spacing: Spacing.base) {
            HStack(spacing: Spacing.md) {
                searchBar
                iconButton(systemImage: "line.3.horizontal.decrease", label: "Open filters") {
                    viewModel.isFilterSheetPresented = true
                }
                iconButton(
                    systemImage: viewModel.viewMode == .list ? "map" : "list.bullet",
                    label: viewModel.viewMode == .list ? "Switch to map view" : "Switch to list view"
                ) {
                    viewModel.setViewMode(viewModel.viewMode == .list ? .map : .list)
                }
            }
            cityChips
        }
        .padding(.horizontal, Spacing.base)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.md)
    }

    private var searchBar: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "magnifyingglass")
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
