import SwiftUI

/// A single horizontally-snapping rail inside the Discovery list.
///
/// Layout:
/// ```
/// ┌───────────────────────────────────────┐
/// │ Popular homes in Mogadishu       ›    │   <- header (title + chevron)
/// │ Identity & property confirmed         │   <- optional subtitle
/// │                                       │
/// │  ┌─────────┐ ┌─────────┐ ┌──────      │   <- snapping LazyHStack
/// │  │  card   │ │  card   │ │ peek       │
/// │  └─────────┘ └─────────┘ └──────      │
/// └───────────────────────────────────────┘
/// ```
///
/// Sizing. Each card is pinned to `Spacing.railCardWidth`, a constant tuned
/// so that on a compact iPhone two full cards + a ~38pt peek of the third fit
/// inside the rail's leading/trailing `screenMargin`. Using a constant keeps
/// the card width identical across every rail in the app rather than drifting
/// with screen size — and avoids the "image floats above empty space, text
/// drifts mid-rail" failure mode of the `GeometryReader` + `.frame(minHeight:)`
/// + default `LazyHStack.center` combination.
///
/// The leading inset comes from `.safeAreaPadding(.horizontal, _)` on the
/// ScrollView (not `.padding(.horizontal)` on the inner LazyHStack) so the
/// first card's `.viewAligned` snap point lines up with the header's leading
/// edge. `.contentMargins(for: .scrollContent)` was tried first but on iOS 26
/// it fails to hold the inset once AsyncImage resolves and triggers re-layout.
struct CategoryRailView: View {
    let rail: DiscoveryRail
    let savedIDs: Set<UUID>
    let onToggleSave: (UUID) -> Void
    let onSeeAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            header
            railScroll
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(rail.category.title)
                    .font(.martiHeading4)
                    .foregroundStyle(Color.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                if let subtitle = rail.category.subtitle {
                    Text(subtitle)
                        .font(.martiFootnote)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            Spacer(minLength: Spacing.md)
            Button(action: onSeeAll) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("See all \(rail.category.title)")
        }
        .padding(.horizontal, Spacing.screenMargin)
    }

    // MARK: - Scroll

    private var railScroll: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: Spacing.cardGap) {
                ForEach(rail.listings, id: \.id) { listing in
                    NavigationLink {
                        ListingDetailPlaceholderView(listing: listing)
                    } label: {
                        ListingCardView(
                            listing: listing,
                            variant: .rail,
                            isSaved: savedIDs.contains(listing.id),
                            onToggleSave: { onToggleSave(listing.id) }
                        )
                        .frame(width: Spacing.railCardWidth)
                    }
                    .buttonStyle(.plain)
                }
            }
            .scrollTargetLayout()
        }
        .safeAreaPadding(.horizontal, Spacing.screenMargin)
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
    }
}
