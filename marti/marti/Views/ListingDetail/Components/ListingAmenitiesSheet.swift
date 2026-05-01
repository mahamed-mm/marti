import SwiftUI

/// Sheet destination for the §G "Show all N amenities" button. Renders the
/// **full** amenity list using the **v2 stroked-container row recipe** —
/// 36×36 rounded-square icon container, bold title, secondary description
/// copy when available. The richer treatment is reserved for this sheet
/// (the destination earns the visual weight); the inline preview in
/// `ListingAmenitiesSection` stays as bare-glyph rows.
///
/// Lookup tables (`symbolName(for:)`, `description(for:)`) are re-used from
/// `ListingAmenitiesSection` — single source of truth for amenity → symbol
/// + copy mapping.
struct ListingAmenitiesSheet: View {
    let amenities: [String]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text("What this place offers")
                        .font(.martiHeading3)
                        .foregroundStyle(Color.textPrimary)
                        .accessibilityAddTraits(.isHeader)

                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        ForEach(amenities, id: \.self) { amenity in
                            amenityRow(amenity)
                            if amenity != amenities.last {
                                Divider().background(Color.dividerLine)
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.screenMargin)
                .padding(.vertical, Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.surfaceDefault)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationBackground(Color.surfaceDefault)
    }

    /// v2-style row: 36×36 stroked container around the glyph, bold name +
    /// optional secondary description. Identical recipe to the row used in
    /// the v2 inline section, kept here so the sheet preserves the richer
    /// treatment.
    private func amenityRow(_ amenity: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.base) {
            Image(systemName: ListingAmenitiesSection.symbolName(for: amenity))
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color.textPrimary)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .stroke(Color.dividerLine, lineWidth: 1)
                )
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(amenity)
                    .font(.martiLabel1)
                    .foregroundStyle(Color.textPrimary)
                if let desc = ListingAmenitiesSection.description(for: amenity) {
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
}

#if DEBUG

#Preview("Full list") {
    ListingAmenitiesSheet(amenities: [
        "Wifi",
        "Kitchen",
        "Workspace",
        "AC",
        "Pool",
        "Washer",
        "Free parking",
        "TV",
        "Balcony",
        "Breakfast included"
    ])
}

#endif
