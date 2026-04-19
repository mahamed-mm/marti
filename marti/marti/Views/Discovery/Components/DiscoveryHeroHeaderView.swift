import SwiftUI

/// Editorial header for list-mode Discovery. Leads with a curated one-line
/// destination promise, with the search capsule and paired map/filter icon
/// buttons demoted to a single control row beneath it.
///
/// The title is an evergreen editorial constant (`heroCopy`), deliberately
/// independent of filter state — the search capsule already surfaces active
/// filters one row below, and duplicating that in display-weight type made
/// the screen read as broken.
///
/// The map-mode header (`DiscoveryHeaderPill`) is intentionally untouched —
/// editorial weight belongs above a scrolling feed, not floating over a map.
/// Map mode still reads `viewModel.headerTitle` / `viewModel.headerSubtitle`.
struct DiscoveryHeroHeaderView: View {
    @Bindable var viewModel: ListingDiscoveryViewModel

    private static let heroCopy = "Feel at home."

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.base) {
            titleRow
            searchRow
        }
        .padding(.horizontal, Spacing.screenMargin)
        .padding(.top, Spacing.md)
    }

    // MARK: - Title row

    private var titleRow: some View {
        Text(Self.heroCopy)
            .font(.martiDisplay)
            .foregroundStyle(Color.textPrimary)
            .lineLimit(2)
            .minimumScaleFactor(0.9)
            .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Search row (demoted)

    private var searchRow: some View {
        HStack(spacing: Spacing.md) {
            searchCapsule
            iconButton(systemImage: "map", label: "Switch to map view") {
                viewModel.setViewMode(.map)
            }
            iconButton(systemImage: "line.3.horizontal.decrease", label: "Open filters") {
                viewModel.isFilterSheetPresented = true
            }
        }
    }

    /// Non-interactive capsule that surfaces the active filter summary (or a
    /// placeholder when `filter == .default`). Matches the previous header's
    /// behavior — search itself isn't wired in v1, but the capsule remains so
    /// users can read at a glance what filters are active.
    private var searchCapsule: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: hasFilterSummary ? "slider.horizontal.3" : "magnifyingglass")
                .foregroundStyle(Color.textTertiary)
            Text(searchCapsuleText)
                .font(.martiBody)
                .foregroundStyle(hasFilterSummary ? Color.textPrimary : Color.textTertiary)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.base)
        .frame(height: 48)
        .frame(maxWidth: .infinity)
        .background(Capsule().fill(Color.surfaceDefault))
        // Single glassy top-edge stroke so the capsule reads as an elevated
        // plane against canvas without a heavy shadow.
        .overlay(Capsule().strokeBorder(Color.surfaceGlass, lineWidth: 1))
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

    // MARK: - Search capsule text

    private var hasFilterSummary: Bool {
        viewModel.filter != .default
    }

    private var searchCapsuleText: String {
        let f = viewModel.filter
        if f == .default {
            return "Search Mogadishu, Hargeisa…"
        }
        var parts: [String] = []
        if let city = f.city { parts.append(city.rawValue) }
        if let dateRange = Self.formattedDateRange(checkIn: f.checkIn, checkOut: f.checkOut) {
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

    private static func formattedDateRange(checkIn: Date?, checkOut: Date?) -> String? {
        guard let checkIn, let checkOut else { return nil }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return "\(fmt.string(from: checkIn))–\(fmt.string(from: checkOut))"
    }
}
