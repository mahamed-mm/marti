import SwiftUI

/// Amenities list section for Listing Detail. Each amenity name maps to a
/// hand-picked SF Symbol via `symbolName(for:)`; anything unmapped falls back
/// to `checkmark.circle` so unknown server data still renders.
///
/// v2 visual pass: the section heading "Amenities" was dropped — the Airbnb
/// reference renders no top-level title and each row stands alone with a
/// rounded-square icon container, a bold name, and a secondary description
/// (the description is best-effort: known amenities pull copy from the
/// `description(for:)` lookup; unknowns collapse to heading-only).
///
/// The whole section is suppressed when `amenities` is empty so the screen
/// doesn't show an empty stack of rows.
struct ListingAmenitiesSection: View {
    let amenities: [String]

    var body: some View {
        if amenities.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                ForEach(amenities, id: \.self) { amenity in
                    amenityRow(amenity)
                }
            }
        }
    }

    private func amenityRow(_ amenity: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.base) {
            Image(systemName: Self.symbolName(for: amenity))
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color.textPrimary)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .stroke(Color.dividerLine, lineWidth: 1)
                )
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(amenity)
                    .font(.martiLabel1)
                    .foregroundStyle(Color.textPrimary)
                if let desc = Self.description(for: amenity) {
                    Text(desc)
                        .font(.martiFootnote)
                        .foregroundStyle(Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

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
    private static func description(for amenity: String) -> String? {
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
