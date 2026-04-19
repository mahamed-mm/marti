import SwiftUI

/// Editorial header for list-mode Discovery. Leads with a curated one-line
/// destination promise, followed by a single tall search card that opens a
/// search sheet via the `onTapSearch` callback.
///
/// The title is an evergreen editorial constant (`heroCopy`), deliberately
/// independent of filter state — the search card already surfaces active
/// filters on its second line, and duplicating that in display-weight type
/// made the screen read as broken.
///
/// The map-mode header (`DiscoveryHeaderPill`) is intentionally untouched —
/// editorial weight belongs above a scrolling feed, not floating over a map.
/// Map mode still reads `viewModel.headerTitle` / `viewModel.headerSubtitle`.
struct DiscoveryHeroHeaderView: View {
    @Bindable var viewModel: ListingDiscoveryViewModel
    let onTapSearch: () -> Void

    private static let heroCopy = "Feel at home."
    private static let heroSubtitle = "Verified stays across Somalia."

    init(viewModel: ListingDiscoveryViewModel, onTapSearch: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onTapSearch = onTapSearch
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            titleRow
            searchCard
        }
        .padding(.horizontal, Spacing.screenMargin)
        .padding(.top, Spacing.md)
    }

    // MARK: - Title row

    private var titleRow: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(Self.heroCopy)
                .font(.martiDisplay)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.9)
            Text(Self.heroSubtitle)
                .font(.martiFootnote)
                .foregroundStyle(Color.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Feel at home. Verified stays across Somalia.")
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Search card

    private var searchCard: some View {
        Button(action: onTapSearch) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(titleCopy)
                        .font(.martiHeading4)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                    Text(searchCapsuleText)
                        .font(.martiFootnote)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Spacing.base)
            .padding(.vertical, Spacing.md + 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .fill(Color.surfaceDefault)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .strokeBorder(Color.surfaceGlass, lineWidth: 1)
            )
            .shadow(token: .island)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Search stays")
        .accessibilityHint("Opens search with destination, dates, guests, and filters.")
        .accessibilityValue(searchCapsuleText)
    }

    // MARK: - Search capsule text

    private var titleCopy: String {
        hasFilterSummary ? "Edit search" : "Where to?"
    }

    private var hasFilterSummary: Bool {
        viewModel.filter != .default
    }

    private var searchCapsuleText: String {
        let f = viewModel.filter
        if f == .default {
            return "Anywhere · Any dates · Add guests"
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
        return parts.isEmpty ? "Anywhere · Any dates · Add guests" : parts.joined(separator: " · ")
    }

    /// Formats a check-in/check-out pair as a compact date range.
    /// - Parameters:
    ///   - checkIn: The start date of the range; if `nil`, the function returns `nil`.
    ///   - checkOut: The end date of the range; if `nil`, the function returns `nil`.
    /// - Returns: A string in the form `"MMM d–MMM d"` (e.g. `"Jun 4–Jun 6"`) representing the range, or `nil` if either date is missing.
    private static func formattedDateRange(checkIn: Date?, checkOut: Date?) -> String? {
        guard let checkIn, let checkOut else { return nil }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return "\(fmt.string(from: checkIn))–\(fmt.string(from: checkOut))"
    }
}
