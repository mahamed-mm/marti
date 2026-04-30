import SwiftUI

/// Amenities preview section for Listing Detail (§G of v3 spec). Shows the
/// **first 6** amenities as bare-glyph rows (no 36×36 stroked container —
/// that recipe lives in `ListingAmenitiesSheet`, the sheet destination), with
/// a full-width "Show all N amenities" button beneath when more exist.
///
/// Recipe per row:
/// - 20pt SF Symbol leading (bare glyph, `Color.textPrimary`).
/// - `Font.martiBody` amenity label, primary text.
///
/// Section header: "What this place offers" — `Font.martiHeading4`, primary,
/// header trait. Whole section is suppressed when `amenities.isEmpty`.
///
/// `symbolName(for:)` and `description(for:)` are exposed at file scope so
/// `ListingAmenitiesSheet` can re-use the same lookup tables for its richer
/// stroked-container row recipe.
struct ListingAmenitiesSection: View {
    let amenities: [String]
    /// Tapped when the user hits "Show all N amenities". The presenter
    /// (currently `ListingDetailView`) flips a `@State` flag and shows the
    /// sheet. Kept as a callback rather than a binding so the section stays
    /// presentation-agnostic.
    let onShowAll: () -> Void

    /// Drives the per-tap haptic on the "Show all" button. Toggled on tap so
    /// `.sensoryFeedback` actually fires (Equatable-Bool flips are the
    /// project pattern — see `ListingDetailStickyFooterView.hapticTrigger`).
    @State private var showAllHapticTrigger = false

    /// Cap the inline preview at this row count — anything above falls into
    /// the sheet via the "Show all" button.
    private static let previewCap: Int = 6

    var body: some View {
        if amenities.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("What this place offers")
                    .font(.martiHeading4)
                    .foregroundStyle(Color.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                VStack(alignment: .leading, spacing: Spacing.lg) {
                    ForEach(previewAmenities, id: \.self) { amenity in
                        amenityRow(amenity)
                    }
                }
                .padding(.top, Spacing.xs)

                if amenities.count > Self.previewCap {
                    showAllButton
                }
            }
        }
    }

    private var previewAmenities: [String] {
        Array(amenities.prefix(Self.previewCap))
    }

    private func amenityRow(_ amenity: String) -> some View {
        HStack(alignment: .center, spacing: Spacing.base) {
            Image(systemName: Self.symbolName(for: amenity))
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(Color.textPrimary)
                .frame(width: 24, alignment: .center)
                .accessibilityHidden(true)
            Text(amenity)
                .font(.martiBody)
                .foregroundStyle(Color.textPrimary)
            // NOTE: v1 schema only stores positive amenities. When we model
            // negatives (e.g. "Carbon monoxide alarm" missing), this row
            // should apply `.strikethrough()` and a slashed-circle SF
            // Symbol variant — branch dormant until then.
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    /// Spec §G "View all-style buttons": `surfaceElevated` fill, `Radius.md`,
    /// ~48pt min height, full-width, `martiLabel1` primary text. Loop 1 shipped
    /// stroked-only — design-reviewer M2. Hairline stroke dropped: the spec
    /// recipe is fill-only, and a stroke on top of `surfaceElevated` reads as
    /// extra chrome without information. Project precedent (`PrimaryButtonStyle`)
    /// is also fill-only, no stroke. `.sensoryFeedback(.selection, …)` matches
    /// the §L row haptic style — selection is the right token for "opens a
    /// sheet" affordances; `.impact` stays reserved for primary CTAs (Reserve).
    private var showAllButton: some View {
        Button {
            showAllHapticTrigger.toggle()
            onShowAll()
        } label: {
            Text("Show all \(amenities.count) amenities")
                .font(.martiLabel1)
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .fill(Color.surfaceElevated)
                )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: showAllHapticTrigger)
        .accessibilityLabel("Show all amenities")
        .accessibilityHint("Opens the full list of amenities for this listing")
    }

    // MARK: - Lookup tables (shared with ListingAmenitiesSheet)

    /// Local mapping table from amenity label → SF Symbol. Lower-cased contains
    /// match keeps matching loose enough to handle hyphen/punctuation drift in
    /// the seed data without losing the icon.
    static func symbolName(for amenity: String) -> String {
        let key = amenity.lowercased()
        if key.contains("wifi") { return "wifi" }
        if key.contains("ac") || key.contains("air") && key.contains("cond") { return "snowflake" }
        if key.contains("airport") { return "airplane.arrival" }
        if key.contains("park") { return "parkingsign.circle" }
        if key.contains("kitchen") { return "fork.knife" }
        if key.contains("pool") { return "figure.pool.swim" }
        if key.contains("wash") || key.contains("laundry") { return "washer" }
        if key.contains("tv") { return "tv" }
        if key.contains("balcon") || key.contains("terrace") { return "sun.max" }
        if key.contains("breakfast") { return "cup.and.saucer.fill" }
        if key.contains("workspace") || key.contains("desk") { return "desktopcomputer" }
        if key.contains("safe") || key.contains("security") { return "lock.shield" }
        return "checkmark.circle"
    }

    /// Secondary description copy keyed off the amenity label (lower-cased
    /// contains match, mirroring `symbolName(for:)`). Out-of-table amenities
    /// return `nil` so the row collapses to heading-only — better than
    /// inventing copy that doesn't match the listing.
    ///
    /// Internal so `ListingAmenitiesSheet` (in the same target) can re-use it.
    static func description(for amenity: String) -> String? {
        let key = amenity.lowercased()
        if key.contains("wifi") { return "Reliable connection in every room." }
        if key.contains("ac") || (key.contains("air") && key.contains("cond")) {
            return "Cool, dry air for warm-weather stays."
        }
        if key.contains("kitchen") { return "Equipped for home-cooked meals during your stay." }
        if key.contains("pool") { return "Shared pool access on the property." }
        if key.contains("wash") || key.contains("laundry") { return "On-site laundry — no laundromat run." }
        if key.contains("parking") || key.contains("park") { return "On-site parking included." }
        if key.contains("workspace") || key.contains("desk") { return "A comfortable spot to get work done." }
        if key.contains("balcon") || key.contains("terrace") { return "Outdoor space attached to the unit." }
        return nil
    }
}
