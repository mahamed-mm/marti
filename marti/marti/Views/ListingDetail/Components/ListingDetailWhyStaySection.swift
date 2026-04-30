import SwiftUI

/// Why-stay highlights section (§E of v3 spec). Three "this place is great
/// at" rows, modeled on IMG_0603 / IMG_0604 — bare glyph + bold title +
/// secondary subtitle, no header above them.
///
/// Distinct from `ListingAmenitiesSection` (§G): this surface uses **bare
/// glyphs**, no 36×36 stroked container. That's the visible delta between the
/// two surfaces — amenities sit in their iconography boxes, why-stay rows
/// don't.
///
/// Copy is intentionally generic so it never lies about a property:
/// - "Self check-in" — every Marti host coordinates by message.
/// - "{neighborhood} location" — derived from the listing's own neighborhood.
/// - "Verified host" — only rendered when `isVerified == true`.
///
/// When real amenity-derived highlights ship (e.g. "Sea breeze", "Quiet block"),
/// they promote into this slot. Today's copy is a placeholder, by design.
struct ListingDetailWhyStaySection: View {
    let neighborhood: String
    let city: String
    let isVerified: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            row(
                glyph: "key.fill",
                title: "Self check-in",
                subtitle: "Easy entry on arrival — host coordinates by message."
            )
            row(
                glyph: "mappin.and.ellipse",
                title: "\(neighborhood) location",
                subtitle: "Near \(city)'s daily life — markets, mosques, restaurants within walking distance."
            )
            if isVerified {
                row(
                    glyph: "medal.fill",
                    title: "Verified host",
                    subtitle: "Host has been ID-verified by Marti."
                )
            }
        }
    }

    private func row(glyph: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.base) {
            Image(systemName: glyph)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(Color.textPrimary)
                .frame(width: 24, alignment: .center)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.martiLabel1)
                    .foregroundStyle(Color.textPrimary)
                Text(subtitle)
                    .font(.martiFootnote)
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG

#Preview("Verified host") {
    ListingDetailWhyStaySection(
        neighborhood: "Hamarweyne",
        city: "Mogadishu",
        isVerified: true
    )
    .padding()
    .background(Color.surfaceDefault)
}

#Preview("Unverified host") {
    ListingDetailWhyStaySection(
        neighborhood: "Wadajir",
        city: "Mogadishu",
        isVerified: false
    )
    .padding()
    .background(Color.surfaceDefault)
}

#endif
